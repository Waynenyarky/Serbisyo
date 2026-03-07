const express = require('express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const Service = require('../models/Service');
const ProviderProfile = require('../models/ProviderProfile');
const User = require('../models/User');
const { authMiddleware } = require('./auth');
const { requirePermission } = require('../middleware/rbac');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

function providerRole(user) {
  if (user.is_admin) return 'admin';
  if (user.is_provider) return 'provider';
  return 'customer';
}

function issueToken(user) {
  return jwt.sign(
    {
      id: user._id.toString(),
      email: user.email,
      roles: {
        is_customer: !!user.is_customer,
        is_provider: !!user.is_provider,
        is_admin: !!user.is_admin,
        admin_role: user.admin_role || null,
      },
    },
    JWT_SECRET
  );
}

function isValidObjectId(value) {
  return mongoose.Types.ObjectId.isValid(value);
}

function parsePositiveInt(value, fallback) {
  if (value === undefined || value === null || value === '') return fallback;
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

function parseNumber(value, fallback) {
  if (value === undefined || value === null || value === '') return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function escapeRegex(input) {
  return input.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Authenticated fallback endpoint to upgrade current user to provider.
// Kept under /providers to support older clients/servers during transition.
router.post('/me/upgrade', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.is_customer = true;
    if (!user.is_provider) {
      user.is_provider = true;
      await user.save();
    }

    const token = issueToken(user);
    return res.json({
      user: {
        id: user._id.toString(),
        email: user.email,
        fullName: user.fullName,
        role: providerRole(user),
        is_customer: !!user.is_customer,
        is_provider: !!user.is_provider,
        is_admin: !!user.is_admin,
        admin_role: user.admin_role || null,
      },
      token,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

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

// Public: provider lookup/search for discovery flows
router.get('/search', async (req, res) => {
  try {
    const { q, categoryId, page: pageQuery, limit: limitQuery } = req.query;

    if (categoryId && !isValidObjectId(categoryId)) {
      return res.status(400).json({ error: 'Invalid categoryId' });
    }

    const page = parsePositiveInt(pageQuery, 1);
    if (page === null) return res.status(400).json({ error: 'Invalid page. Must be a positive integer.' });
    const limit = parsePositiveInt(limitQuery, 20);
    if (limit === null) return res.status(400).json({ error: 'Invalid limit. Must be a positive integer.' });
    const cappedLimit = Math.min(limit, 50);

    const normalizedQ = typeof q === 'string' ? q.trim() : '';
    if (normalizedQ.length > 100) {
      return res.status(400).json({ error: 'Invalid q. Max length is 100 characters.' });
    }

    const serviceMatch = { status: 'active' };
    if (categoryId) serviceMatch.categoryId = new mongoose.Types.ObjectId(categoryId);
    if (normalizedQ) {
      const safeRegex = new RegExp(escapeRegex(normalizedQ), 'i');
      serviceMatch.$or = [
        { title: safeRegex },
        { providerName: safeRegex },
        { description: safeRegex },
      ];
    }

    const grouped = await Service.aggregate([
      { $match: serviceMatch },
      {
        $group: {
          _id: '$providerId',
          providerName: { $first: '$providerName' },
          activeServiceCount: { $sum: 1 },
          bestRating: { $max: '$rating' },
          categoryIds: { $addToSet: '$categoryId' },
        },
      },
      { $match: { _id: { $ne: null } } },
      { $sort: { bestRating: -1, activeServiceCount: -1 } },
    ]);

    const providerIds = grouped.map((item) => item._id);
    if (!providerIds.length) {
      return res.json({
        page,
        limit: cappedLimit,
        total: 0,
        results: [],
      });
    }

    const [users, profiles] = await Promise.all([
      User.find({ _id: { $in: providerIds }, is_provider: true })
        .select('fullName email ratings address')
        .lean(),
      ProviderProfile.find({ userId: { $in: providerIds } }).lean(),
    ]);

    const userById = new Map(users.map((user) => [user._id.toString(), user]));
    const profileByUserId = new Map(profiles.map((profile) => [profile.userId.toString(), profile]));

    let results = grouped
      .map((item) => {
        const providerId = item._id.toString();
        const user = userById.get(providerId);
        if (!user) return null;
        const profile = profileByUserId.get(providerId);
        return {
          id: providerId,
          fullName: user.fullName,
          email: user.email,
          providerName: item.providerName || user.fullName,
          ratings: typeof user.ratings === 'number' ? user.ratings : (item.bestRating ?? 0),
          activeServiceCount: item.activeServiceCount,
          serviceArea: profile?.serviceArea || '',
          isVerified: profile?.isVerified ?? false,
          avatarUrl: profile?.avatarUrl || null,
        };
      })
      .filter(Boolean);

    if (normalizedQ) {
      const safeRegex = new RegExp(escapeRegex(normalizedQ), 'i');
      results = results.filter((item) => (
        safeRegex.test(item.fullName || '')
        || safeRegex.test(item.providerName || '')
        || safeRegex.test(item.email || '')
      ));
    }

    const total = results.length;
    const startIndex = (page - 1) * cappedLimit;
    const paged = results.slice(startIndex, startIndex + cappedLimit);

    return res.json({
      page,
      limit: cappedLimit,
      total,
      results: paged,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

// Public: nearest providers by customer coordinates
router.get('/nearest', async (req, res) => {
  try {
    const {
      lng: lngQuery,
      lat: latQuery,
      radiusMeters: radiusQuery,
      limit: limitQuery,
      categoryId,
    } = req.query;

    if (categoryId && !isValidObjectId(categoryId)) {
      return res.status(400).json({ error: 'Invalid categoryId' });
    }

    const lng = parseNumber(lngQuery, null);
    const lat = parseNumber(latQuery, null);
    if (lng === null || lat === null) {
      return res.status(400).json({ error: 'lng and lat are required numbers' });
    }
    if (lng < -180 || lng > 180 || lat < -90 || lat > 90) {
      return res.status(400).json({ error: 'Invalid coordinates range' });
    }

    const radiusMeters = parsePositiveInt(radiusQuery, 10000);
    if (radiusMeters === null) {
      return res.status(400).json({ error: 'Invalid radiusMeters. Must be a positive integer.' });
    }
    const cappedRadius = Math.min(radiusMeters, 50000);

    const limit = parsePositiveInt(limitQuery, 10);
    if (limit === null) {
      return res.status(400).json({ error: 'Invalid limit. Must be a positive integer.' });
    }
    const cappedLimit = Math.min(limit, 25);

    const serviceMatch = { status: 'active' };
    if (categoryId) serviceMatch.categoryId = new mongoose.Types.ObjectId(categoryId);

    const providerIds = await Service.distinct('providerId', serviceMatch);
    const validProviderIds = providerIds.filter(Boolean).map((id) => new mongoose.Types.ObjectId(id));

    if (!validProviderIds.length) {
      return res.json({
        matched: false,
        fallbackReason: 'no_active_providers',
        search: { lng, lat, radiusMeters: cappedRadius, categoryId: categoryId || null },
        candidates: [],
      });
    }

    const nearestUsers = await User.aggregate([
      {
        $geoNear: {
          near: { type: 'Point', coordinates: [lng, lat] },
          distanceField: 'distanceMeters',
          maxDistance: cappedRadius,
          spherical: true,
          query: {
            _id: { $in: validProviderIds },
            is_provider: true,
          },
        },
      },
      {
        $project: {
          fullName: 1,
          email: 1,
          ratings: 1,
          distanceMeters: 1,
        },
      },
      { $sort: { distanceMeters: 1, ratings: -1 } },
      { $limit: cappedLimit },
    ]);

    if (!nearestUsers.length) {
      return res.json({
        matched: false,
        fallbackReason: 'no_candidates_in_radius',
        search: { lng, lat, radiusMeters: cappedRadius, categoryId: categoryId || null },
        candidates: [],
      });
    }

    const nearestIds = nearestUsers.map((item) => item._id);
    const [profiles, services] = await Promise.all([
      ProviderProfile.find({ userId: { $in: nearestIds } }).lean(),
      Service.find({ providerId: { $in: nearestIds }, status: 'active' })
        .select('providerId title categoryId rating pricePerHour')
        .lean(),
    ]);

    const profileByUserId = new Map(profiles.map((profile) => [profile.userId.toString(), profile]));
    const servicesByProvider = new Map();
    for (const service of services) {
      const key = service.providerId.toString();
      const list = servicesByProvider.get(key) || [];
      list.push(service);
      servicesByProvider.set(key, list);
    }

    const candidates = nearestUsers.map((provider) => {
      const providerId = provider._id.toString();
      const profile = profileByUserId.get(providerId);
      const providerServices = servicesByProvider.get(providerId) || [];
      return {
        id: providerId,
        fullName: provider.fullName,
        email: provider.email,
        ratings: typeof provider.ratings === 'number' ? provider.ratings : 0,
        distanceMeters: Math.round(provider.distanceMeters),
        serviceArea: profile?.serviceArea || '',
        isVerified: profile?.isVerified ?? false,
        avatarUrl: profile?.avatarUrl || null,
        activeServiceCount: providerServices.length,
        services: providerServices.map((service) => ({
          id: service._id.toString(),
          title: service.title,
          categoryId: service.categoryId?.toString?.() ?? service.categoryId,
          rating: service.rating ?? 0,
          pricePerHour: service.pricePerHour ?? 0,
        })),
      };
    });

    return res.json({
      matched: true,
      search: { lng, lat, radiusMeters: cappedRadius, categoryId: categoryId || null },
      candidates,
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
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
