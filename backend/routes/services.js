const express = require('express');
const Service = require('../models/Service');
const { authMiddleware } = require('./auth');
const { requireRole } = require('../middleware/rbac');

const router = express.Router();

// Public list: only active services (optional filter by categoryId, q, providerId)
router.get('/', async (req, res) => {
  try {
    const { categoryId, q, providerId } = req.query;
    const filter = { status: 'active' };
    if (categoryId) filter.categoryId = categoryId;
    if (providerId) filter.providerId = providerId;
    if (q) {
      filter.$or = [
        { title: new RegExp(q, 'i') },
        { providerName: new RegExp(q, 'i') },
      ];
    }
    const services = await Service.find(filter).populate('categoryId', 'name').lean();
    const list = services.map(s => ({
      id: s._id.toString(),
      title: s.title,
      categoryId: s.categoryId?._id?.toString() ?? s.categoryId?.toString() ?? s.categoryId,
      providerId: s.providerId?.toString() ?? s.providerId ?? null,
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
    }));
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Provider-only: list my services (draft + active)
router.get('/mine', authMiddleware, requireRole('provider'), async (req, res) => {
  try {
    const services = await Service.find({ providerId: req.user.id }).populate('categoryId', 'name').sort({ createdAt: -1 }).lean();
    const list = services.map(s => ({
      id: s._id.toString(),
      title: s.title,
      categoryId: s.categoryId?._id?.toString() ?? s.categoryId?.toString() ?? s.categoryId,
      providerId: s.providerId?.toString() ?? s.providerId,
      imageUrl: s.imageUrl || null,
      rating: s.rating ?? 0,
      reviewCount: s.reviewCount ?? 0,
      pricePerHour: s.pricePerHour,
      providerName: s.providerName,
      description: s.description || null,
      status: s.status || 'draft',
    }));
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const service = await Service.findById(req.params.id).populate('categoryId', 'name').lean();
    if (!service) return res.status(404).json({ error: 'Service not found' });
    // Public: only show active services
    if (service.status !== 'active') return res.status(404).json({ error: 'Service not found' });
    res.json({
      id: service._id.toString(),
      title: service.title,
      categoryId: service.categoryId?._id?.toString() ?? service.categoryId,
      providerId: service.providerId?.toString() ?? service.providerId ?? null,
      imageUrl: service.imageUrl || null,
      rating: service.rating ?? 0,
      reviewCount: service.reviewCount ?? 0,
      pricePerHour: service.pricePerHour,
      providerName: service.providerName,
      description: service.description || null,
      offers: service.offers || null,
      locationDescription: service.locationDescription || null,
      availability: service.availability || null,
      thingsToKnow: service.thingsToKnow || null,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Provider-only: create service as draft (providerId set to current user)
router.post('/', authMiddleware, requireRole('provider'), async (req, res) => {
  try {
    const { title, categoryId, imageUrl, pricePerHour, description, offers, locationDescription, availability, thingsToKnow } = req.body;
    if (!title || !categoryId) {
      return res.status(400).json({ error: 'title and categoryId required' });
    }
    const User = require('../models/User');
    const user = await User.findById(req.user.id).select('fullName');
    const service = await Service.create({
      title,
      categoryId,
      providerId: req.user.id,
      providerName: user?.fullName ?? 'Provider',
      pricePerHour: Number(pricePerHour) || 0,
      imageUrl: imageUrl || undefined,
      description: description || undefined,
      offers: offers || undefined,
      locationDescription: locationDescription || undefined,
      availability: availability || undefined,
      thingsToKnow: thingsToKnow || undefined,
      status: 'draft',
    });
    const populated = await Service.findById(service._id).populate('categoryId', 'name').lean();
    res.status(201).json({
      id: populated._id.toString(),
      title: populated.title,
      categoryId: populated.categoryId?._id?.toString() ?? populated.categoryId,
      providerId: populated.providerId?.toString(),
      providerName: populated.providerName,
      pricePerHour: populated.pricePerHour,
      imageUrl: populated.imageUrl || null,
      description: populated.description || null,
      status: populated.status || 'draft',
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Provider-only: update service (only owner); can set status to 'active' to publish
router.patch('/:id', authMiddleware, requireRole('provider'), async (req, res) => {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) return res.status(404).json({ error: 'Service not found' });
    if (service.providerId?.toString() !== req.user.id) {
      return res.status(403).json({ error: 'Not allowed to update this service' });
    }
    const { title, categoryId, imageUrl, pricePerHour, description, offers, locationDescription, availability, thingsToKnow, status } = req.body;
    if (title !== undefined) service.title = title;
    if (categoryId !== undefined) service.categoryId = categoryId;
    if (imageUrl !== undefined) service.imageUrl = imageUrl;
    if (pricePerHour !== undefined) service.pricePerHour = Number(pricePerHour);
    if (description !== undefined) service.description = description;
    if (offers !== undefined) service.offers = offers;
    if (locationDescription !== undefined) service.locationDescription = locationDescription;
    if (availability !== undefined) service.availability = availability;
    if (thingsToKnow !== undefined) service.thingsToKnow = thingsToKnow;
    if (status !== undefined) {
      if (status === 'active') {
        if (service.pricePerHour <= 0) return res.status(400).json({ error: 'Set price per hour before publishing' });
        service.status = 'active';
      } else if (status === 'draft') {
        service.status = 'draft';
      }
    }
    await service.save();
    const populated = await Service.findById(service._id).populate('categoryId', 'name').lean();
    res.json({
      id: populated._id.toString(),
      title: populated.title,
      categoryId: populated.categoryId?._id?.toString() ?? populated.categoryId,
      providerId: populated.providerId?.toString(),
      providerName: populated.providerName,
      pricePerHour: populated.pricePerHour,
      imageUrl: populated.imageUrl || null,
      description: populated.description || null,
      offers: populated.offers || null,
      locationDescription: populated.locationDescription || null,
      availability: populated.availability || null,
      thingsToKnow: populated.thingsToKnow || null,
      status: populated.status || 'draft',
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
