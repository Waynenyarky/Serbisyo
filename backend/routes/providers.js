const express = require('express');
const Service = require('../models/Service');
const ProviderProfile = require('../models/ProviderProfile');
const User = require('../models/User');
const { authMiddleware } = require('./auth');
const { requirePermission } = require('../middleware/rbac');

const router = express.Router();

// Provider-only: activation status (has active service, verified, payout, isActive)
router.get('/me/status', authMiddleware, requirePermission('providers.manage_self'), async (req, res) => {
  try {
    const providerId = req.user.id;
    const activeCount = await Service.countDocuments({ providerId, status: 'active' });
    const hasActiveService = activeCount > 0;
    const profile = await ProviderProfile.findOne({ userId: providerId }).lean();
    const isVerified = profile?.isVerified ?? false;
    const hasPayoutMethod = profile?.payoutMethodAdded ?? false;
    const isActive = hasActiveService; // optional: && isVerified && hasPayoutMethod
    res.json({
      hasActiveService,
      isVerified,
      hasPayoutMethod,
      isActive,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Provider-only: get my profile (phone, address, bio, serviceArea, etc.)
router.get('/me', authMiddleware, requirePermission('providers.manage_self'), async (req, res) => {
  try {
    const profile = await ProviderProfile.findOne({ userId: req.user.id }).lean();
    if (!profile) {
      return res.json({
        id: null,
        userId: req.user.id,
        phone: '',
        address: '',
        bio: '',
        serviceArea: '',
        avatarUrl: null,
        isVerified: false,
        payoutMethodAdded: false,
      });
    }
    res.json({
      id: profile._id.toString(),
      userId: profile.userId?.toString?.() ?? profile.userId,
      phone: profile.phone || '',
      address: profile.address || '',
      bio: profile.bio || '',
      serviceArea: profile.serviceArea || '',
      avatarUrl: profile.avatarUrl || null,
      isVerified: profile.isVerified ?? false,
      payoutMethodAdded: profile.payoutMethodAdded ?? false,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Provider-only: update my profile
router.patch('/me', authMiddleware, requirePermission('providers.manage_self'), async (req, res) => {
  try {
    const { phone, address, bio, serviceArea, avatarUrl } = req.body;
    const profile = await ProviderProfile.findOneAndUpdate(
      { userId: req.user.id },
      {
        ...(phone !== undefined && { phone }),
        ...(address !== undefined && { address }),
        ...(bio !== undefined && { bio }),
        ...(serviceArea !== undefined && { serviceArea }),
        ...(avatarUrl !== undefined && { avatarUrl }),
      },
      { new: true, upsert: true }
    ).lean();
    res.json({
      id: profile._id.toString(),
      userId: profile.userId?.toString?.() ?? profile.userId,
      phone: profile.phone || '',
      address: profile.address || '',
      bio: profile.bio || '',
      serviceArea: profile.serviceArea || '',
      avatarUrl: profile.avatarUrl || null,
      isVerified: profile.isVerified ?? false,
      payoutMethodAdded: profile.payoutMethodAdded ?? false,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Public: lightweight provider info for service detail (no phone or payout data)
router.get('/:id/public', async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('fullName is_provider').lean();
    if (!user) return res.status(404).json({ error: 'Provider not found' });
    if (!user.is_provider) return res.status(404).json({ error: 'Provider not found' });

    const profile = await ProviderProfile.findOne({ userId: user._id }).lean();
    res.json({
      id: user._id.toString(),
      fullName: user.fullName,
      bio: profile?.bio || '',
      serviceArea: profile?.serviceArea || '',
      avatarUrl: profile?.avatarUrl || null,
      isVerified: profile?.isVerified ?? false,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
