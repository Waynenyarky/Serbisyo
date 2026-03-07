const express = require('express');
const mongoose = require('mongoose');
const Review = require('../models/Review');
const Booking = require('../models/Booking');
const Service = require('../models/Service');
const User = require('../models/User');
const { authMiddleware } = require('./auth');
const { requirePermission } = require('../middleware/rbac');

const router = express.Router();
router.use(authMiddleware);

function role(req) {
  const preferred = (req.body?.as || req.query?.as || '').toString().toLowerCase();
  if (preferred === 'customer' && req.user?.is_customer) return 'customer';
  if (preferred === 'provider' && req.user?.is_provider) return 'provider';
  return (req.user?.roleSlug || '').toString().toLowerCase();
}

async function recomputeServiceRating(serviceId) {
  if (!serviceId) return;
  const serviceIdString = serviceId.toString().trim();
  if (!serviceIdString) return;
  const normalizedServiceId = mongoose.Types.ObjectId.isValid(serviceIdString)
    ? new mongoose.Types.ObjectId(serviceIdString)
    : serviceIdString;
  const metrics = await Review.aggregate([
    {
      $match: {
        serviceId: normalizedServiceId,
        roleType: 'guest_to_host',
      },
    },
    {
      $group: {
        _id: '$serviceId',
        reviewCount: { $sum: 1 },
        rating: { $avg: '$ratingOverall' },
      },
    },
  ]);

  const row = metrics[0];
  const service = await Service.findById(serviceId);
  if (!service) return;

  service.reviewCount = Number(row?.reviewCount || 0);
  service.rating = Number(row?.rating || 0);
  await service.save();
}

router.get('/', requirePermission('reviews.read'), async (req, res) => {
  try {
    const revieweeId = (req.query.revieweeId || '').toString().trim();
    const bookingId = (req.query.bookingId || '').toString().trim();
    const serviceId = (req.query.serviceId || '').toString().trim();
    const roleType = (req.query.roleType || '').toString().trim();
    const filter = {};
    if (revieweeId) filter.revieweeId = revieweeId;
    if (bookingId) filter.bookingId = bookingId;
    if (serviceId) filter.serviceId = serviceId;
    if (roleType) filter.roleType = roleType;
    const list = await Review.find(filter).sort({ createdAt: -1 }).lean();
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', requirePermission('reviews.create'), async (req, res) => {
  try {
    const {
      bookingId,
      ratingOverall,
      ratings,
      comment,
    } = req.body || {};

    if (!bookingId || !ratingOverall) {
      return res.status(400).json({ error: 'bookingId and ratingOverall are required' });
    }

    const booking = await Booking.findById(bookingId);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.status !== 'completed') {
      return res.status(400).json({ error: 'You can only review completed bookings' });
    }

    const actor = role(req);
    const preferred = (req.body?.as || '').toString().trim().toLowerCase();
    const ownsAsGuest = booking.userId?.toString() === req.user.id;
    const ownsAsHost = booking.providerId?.toString() === req.user.id;
    const isGuest = ownsAsGuest && (!ownsAsHost || preferred == 'customer' || actor == 'customer');
    const isHost = ownsAsHost && (!ownsAsGuest || preferred == 'provider' || actor == 'provider');
    if (!isGuest && !isHost) {
      return res.status(403).json({ error: 'Not allowed to review this booking' });
    }

    const roleType = isGuest ? 'guest_to_host' : 'host_to_guest';
    const revieweeId = isGuest ? booking.providerId : booking.userId;

    const existing = await Review.findOne({
      bookingId: booking._id,
      reviewerId: req.user.id,
      roleType,
    });
    if (existing) return res.status(409).json({ error: 'You already submitted this review' });

    const review = await Review.create({
      bookingId: booking._id,
      reviewerId: req.user.id,
      revieweeId,
      roleType,
      serviceId: booking.serviceId,
      ratingOverall: Number(ratingOverall),
      ratings: ratings || {},
      comment: (comment || '').toString().trim(),
    });

    if (roleType === 'guest_to_host') {
      await recomputeServiceRating(booking.serviceId);
    } else {
      const guest = await User.findById(booking.userId);
      if (guest) {
        const current = Number(guest.ratings || 0);
        guest.ratings = current > 0 ? (current + Number(ratingOverall)) / 2 : Number(ratingOverall);
        await guest.save();
      }
    }

    res.status(201).json(review.toJSON());
  } catch (err) {
    if (err?.code === 11000) {
      return res.status(409).json({ error: 'Review already exists for this booking and role' });
    }
    return res.status(500).json({ error: err.message });
  }
});

module.exports = router;
