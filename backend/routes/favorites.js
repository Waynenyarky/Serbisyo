const express = require('express');
const mongoose = require('mongoose');
const Favorite = require('../models/Favorite');
const Service = require('../models/Service');
const { authMiddleware } = require('./auth');
const { requirePermission } = require('../middleware/rbac');

const router = express.Router();

router.use(authMiddleware);

function isValidObjectId(value) {
  return mongoose.Types.ObjectId.isValid(value);
}

// GET /api/favorites — list favorite services for current user
router.get('/', requirePermission('favorites.read'), async (req, res) => {
  try {
    const favorites = await Favorite.find({ userId: req.user.id }).lean();
    if (!favorites.length) return res.json([]);

    const serviceIds = favorites.map((f) => f.serviceId);
    const services = await Service.find({ _id: { $in: serviceIds }, status: 'active' }).lean();
    const byId = new Map(services.map((s) => [s._id.toString(), s]));

    const list = favorites
      .map((fav) => {
        const s = byId.get(fav.serviceId.toString());
        if (!s) return null;
        return {
          id: s._id.toString(),
          title: s.title,
          categoryId: s.categoryId?.toString?.() ?? s.categoryId,
          providerId: s.providerId?.toString?.() ?? s.providerId ?? null,
          imageUrl: s.imageUrl || null,
          rating: s.rating ?? 0,
          reviewCount: s.reviewCount ?? 0,
          pricePerHour: s.pricePerHour,
          providerName: s.providerName,
          description: s.description || null,
          offers: s.offers || null,
          locationDescription: s.locationDescription || null,
          availability: s.availability || null,
          thingsToKnow: s.thingsToKnow || null,
        };
      })
      .filter(Boolean);

    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/favorites — add a favorite for current user
router.post('/', requirePermission('favorites.write'), async (req, res) => {
  try {
    const { serviceId } = req.body || {};
    if (!serviceId || !isValidObjectId(serviceId)) {
      return res.status(400).json({ error: 'Valid serviceId is required' });
    }

    const service = await Service.findOne({ _id: serviceId, status: 'active' }).lean();
    if (!service) {
      return res.status(404).json({ error: 'Service not found' });
    }

    await Favorite.updateOne(
      { userId: req.user.id, serviceId },
      { $setOnInsert: { userId: req.user.id, serviceId } },
      { upsert: true },
    );

    res.status(201).json({ success: true });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(200).json({ success: true });
    }
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/favorites/:serviceId — remove a favorite
router.delete('/:serviceId', requirePermission('favorites.write'), async (req, res) => {
  try {
    const { serviceId } = req.params;
    if (!serviceId || !isValidObjectId(serviceId)) {
      return res.status(400).json({ error: 'Valid serviceId is required' });
    }
    await Favorite.deleteOne({ userId: req.user.id, serviceId });
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

