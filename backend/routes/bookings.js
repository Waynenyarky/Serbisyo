const express = require('express');
const Booking = require('../models/Booking');
const { authMiddleware } = require('./auth');
const { requireRole, loadUserRole } = require('../middleware/rbac');

const router = express.Router();
router.use(authMiddleware);

// List bookings: customer = my bookings (userId=me), provider = bookings for me (providerId=me)
router.get('/', loadUserRole, async (req, res) => {
  try {
    const filter = req.user.roleSlug === 'provider'
      ? { providerId: req.user.id }
      : { userId: req.user.id };
    const bookings = await Booking.find(filter).sort({ createdAt: -1 }).lean();
    const list = bookings.map(b => ({
      id: b._id.toString(),
      userId: b.userId?.toString?.() ?? b.userId,
      providerId: b.providerId?.toString?.() ?? b.providerId,
      serviceId: b.serviceId?.toString?.() ?? b.serviceId,
      serviceTitle: b.serviceTitle,
      providerName: b.providerName,
      scheduledDate: b.scheduledDate,
      scheduledTime: b.scheduledTime,
      address: b.address,
      status: b.status,
      totalAmount: b.totalAmount,
      imageUrl: b.imageUrl || null,
    }));
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get one booking: customer can get own, provider can get where they are provider
router.get('/:id', loadUserRole, async (req, res) => {
  try {
    const filter = req.user.roleSlug === 'provider'
      ? { _id: req.params.id, providerId: req.user.id }
      : { _id: req.params.id, userId: req.user.id };
    const booking = await Booking.findOne(filter).lean();
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    res.json({
      id: booking._id.toString(),
      userId: booking.userId?.toString?.() ?? booking.userId,
      providerId: booking.providerId?.toString?.() ?? booking.providerId,
      serviceId: booking.serviceId?.toString?.() ?? booking.serviceId,
      serviceTitle: booking.serviceTitle,
      providerName: booking.providerName,
      scheduledDate: booking.scheduledDate,
      scheduledTime: booking.scheduledTime,
      address: booking.address,
      status: booking.status,
      totalAmount: booking.totalAmount,
      imageUrl: booking.imageUrl || null,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create booking: customer only; body must include providerId (from service, or backend will try to get from service)
router.post('/', requireRole('customer'), async (req, res) => {
  try {
    const { serviceId, providerId: bodyProviderId, serviceTitle, providerName, scheduledDate, scheduledTime, address, totalAmount, imageUrl } = req.body;
    if (!serviceId || !serviceTitle || !providerName || !scheduledDate || !scheduledTime || !address || totalAmount == null) {
      return res.status(400).json({ error: 'Missing required booking fields (serviceId, serviceTitle, providerName, scheduledDate, scheduledTime, address, totalAmount)' });
    }
    let providerId = bodyProviderId;
    if (!providerId) {
      const Service = require('../models/Service');
      const svc = await Service.findById(serviceId).lean();
      if (svc?.providerId) providerId = svc.providerId.toString();
    }
    if (!providerId) {
      return res.status(400).json({ error: 'providerId required (or service must have a provider)' });
    }
    const booking = await Booking.create({
      userId: req.user.id,
      providerId,
      serviceId,
      serviceTitle,
      providerName,
      scheduledDate,
      scheduledTime,
      address,
      totalAmount: Number(totalAmount),
      imageUrl: imageUrl || undefined,
      status: 'upcoming',
    });
    res.status(201).json({
      id: booking._id.toString(),
      userId: booking.userId.toString(),
      providerId: booking.providerId.toString(),
      serviceId: booking.serviceId.toString(),
      serviceTitle: booking.serviceTitle,
      providerName: booking.providerName,
      scheduledDate: booking.scheduledDate,
      scheduledTime: booking.scheduledTime,
      address: booking.address,
      status: booking.status,
      totalAmount: booking.totalAmount,
      imageUrl: booking.imageUrl || null,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
