const express = require('express');
const Booking = require('../models/Booking');
const Service = require('../models/Service');
const { authMiddleware } = require('./auth');
const { requirePermission } = require('../middleware/rbac');

const router = express.Router();
router.use(authMiddleware);

const parseScheduledAt = (scheduledDate, scheduledTime) => {
  const rawDate = (scheduledDate || '').toString().trim();
  const rawTime = (scheduledTime || '').toString().trim();
  if (!rawDate || !rawTime) return null;

  const isoCandidate = new Date(`${rawDate}T${rawTime}`);
  if (!Number.isNaN(isoCandidate.getTime())) return isoCandidate;

  const merged = new Date(`${rawDate} ${rawTime}`);
  if (!Number.isNaN(merged.getTime())) return merged;
  return null;
};

const VALID_STATUSES = new Set(['pending', 'confirmed', 'declined', 'cancelled', 'ongoing', 'completed']);

const TRANSITIONS = {
  pending: new Set(['confirmed', 'declined', 'cancelled']),
  confirmed: new Set(['ongoing', 'cancelled']),
  ongoing: new Set(['completed', 'cancelled']),
  declined: new Set([]),
  cancelled: new Set([]),
  completed: new Set([]),
};

const allowedCancelFrom = new Set(['pending', 'confirmed', 'ongoing']);

function normalizeStatus(value) {
  const v = (value || '').toString().trim().toLowerCase();
  if (v === 'upcoming') return 'confirmed';
  if (v === 'past') return 'completed';
  return v;
}

function statusFilterForQuery(status) {
  if (status === 'confirmed') return { $in: ['confirmed', 'upcoming'] };
  if (status === 'completed') return { $in: ['completed', 'past'] };
  return status;
}

function resolveBookingView(req) {
  const requested = (req.query.as || '').toString().trim().toLowerCase();
  if (requested === 'provider' && req.user?.is_provider) return 'provider';
  if (requested === 'customer' && req.user?.is_customer) return 'customer';
  return req.user.roleSlug === 'provider' ? 'provider' : 'customer';
}

function requestedActor(req) {
  const preferred = (req.body?.as || req.query?.as || '').toString().trim().toLowerCase();
  if (preferred === 'provider' && req.user?.is_provider) return 'provider';
  if (preferred === 'customer' && req.user?.is_customer) return 'customer';
  return null;
}

function resolveMutationActor(req, booking) {
  const preferred = requestedActor(req);
  if (preferred) return preferred;

  const isProviderOwner = booking?.providerId?.toString() === req.user.id;
  const isCustomerOwner = booking?.userId?.toString() === req.user.id;
  if (isProviderOwner && !isCustomerOwner) return 'provider';
  if (isCustomerOwner && !isProviderOwner) return 'customer';

  const role = (req.user?.roleSlug || '').toString().toLowerCase();
  if (role === 'provider') return 'provider';
  if (role === 'customer') return 'customer';
  return null;
}

function canAccessBooking(req, booking, actor) {
  if (actor === 'provider') return booking.providerId?.toString() === req.user.id;
  if (actor === 'customer') return booking.userId?.toString() === req.user.id;
  return false;
}

function canTransition(from, to) {
  return TRANSITIONS[from]?.has(to) ?? false;
}

function effectiveStatus(booking) {
  const raw = (booking?.status || '').toString().trim().toLowerCase();
  if (raw === 'upcoming') {
    return booking?.respondedAt ? 'confirmed' : 'pending';
  }
  if (raw === 'past') return 'completed';
  return raw;
}

async function updateStatus({
  booking,
  toStatus,
  actorId,
  reason,
  cancelledByRole,
  updatePaymentStatus,
}) {
  booking.status = toStatus;
  booking.statusUpdatedBy = actorId;
  if (reason !== undefined) booking.statusReason = reason;
  if (toStatus === 'confirmed' || toStatus === 'declined') {
    booking.respondedAt = new Date();
  }
  if (toStatus === 'cancelled') {
    booking.cancelledAt = new Date();
    booking.cancelledByRole = cancelledByRole || 'system';
  }
  if (toStatus === 'completed') {
    booking.completedAt = new Date();
  }
  if (updatePaymentStatus) {
    booking.paymentStatus = updatePaymentStatus;
  }
  await booking.save();
}

const toBookingJson = (b) => ({
  id: b._id.toString(),
  userId: b.userId?.toString?.() ?? b.userId,
  providerId: b.providerId?.toString?.() ?? b.providerId,
  serviceId: b.serviceId?.toString?.() ?? b.serviceId,
  serviceTitle: b.serviceTitle,
  providerName: b.providerName,
  scheduledDate: b.scheduledDate,
  scheduledTime: b.scheduledTime,
  scheduledAt: (() => {
    if (b.scheduledAt) return new Date(b.scheduledAt).toISOString();
    const parsed = parseScheduledAt(b.scheduledDate, b.scheduledTime);
    return parsed ? parsed.toISOString() : null;
  })(),
  address: b.address,
  status: effectiveStatus(b),
  statusReason: b.statusReason || null,
  respondedAt: b.respondedAt ? new Date(b.respondedAt).toISOString() : null,
  cancelledAt: b.cancelledAt ? new Date(b.cancelledAt).toISOString() : null,
  completedAt: b.completedAt ? new Date(b.completedAt).toISOString() : null,
  statusUpdatedBy: b.statusUpdatedBy?.toString?.() ?? b.statusUpdatedBy ?? null,
  cancelledByRole: b.cancelledByRole || null,
  totalAmount: b.totalAmount,
  imageUrl: b.imageUrl || null,
  cancellationPolicy: b.cancellationPolicy || 'flexible',
  refundAmount: Number(b.refundAmount || 0),
  paymentStatus: b.paymentStatus || 'unpaid',
  createdAt: b.createdAt ? new Date(b.createdAt).toISOString() : null,
  updatedAt: b.updatedAt ? new Date(b.updatedAt).toISOString() : null,
});

// List bookings: customer = my bookings (userId=me), provider = bookings for me (providerId=me)
router.get('/', requirePermission('bookings.read'), async (req, res) => {
  try {
    const viewAs = resolveBookingView(req);
    const filter = viewAs === 'provider'
      ? { providerId: req.user.id }
      : { userId: req.user.id };

    const status = normalizeStatus(req.query.status);
    if (status) {
      if (!VALID_STATUSES.has(status)) {
        return res.status(400).json({ error: 'Invalid status filter' });
      }
      filter.status = statusFilterForQuery(status);
    }

    const from = (req.query.from || '').toString().trim();
    const to = (req.query.to || '').toString().trim();
    if (from || to) {
      const range = {};
      if (from) {
        const parsedFrom = new Date(from);
        if (!Number.isNaN(parsedFrom.getTime())) range.$gte = parsedFrom;
      }
      if (to) {
        const parsedTo = new Date(to);
        if (!Number.isNaN(parsedTo.getTime())) range.$lte = parsedTo;
      }
      if (Object.keys(range).length) filter.scheduledAt = range;
    }

    const sortParam = (req.query.sort || '').toString().trim().toLowerCase();
    let sort = { createdAt: -1 };
    if (sortParam === 'scheduled_asc') sort = { scheduledAt: 1, createdAt: 1 };
    if (sortParam === 'scheduled_desc') sort = { scheduledAt: -1, createdAt: -1 };

    const bookings = await Booking.find(filter).sort(sort).lean();
    const list = bookings.map(toBookingJson);
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get one booking: customer can get own, provider can get where they are provider
router.get('/:id', requirePermission('bookings.read'), async (req, res) => {
  try {
    const viewAs = resolveBookingView(req);
    const filter = viewAs === 'provider'
      ? { _id: req.params.id, providerId: req.user.id }
      : { _id: req.params.id, userId: req.user.id };
    const booking = await Booking.findOne(filter).lean();
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    res.json(toBookingJson(booking));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create booking: customer only; body must include providerId (from service, or backend will try to get from service)
router.post('/', requirePermission('bookings.create'), async (req, res) => {
  try {
    const {
      serviceId,
      providerId: bodyProviderId,
      serviceTitle,
      providerName,
      scheduledDate,
      scheduledTime,
      address,
      totalAmount,
      imageUrl,
      cancellationPolicy,
    } = req.body;
    if (!serviceId || !serviceTitle || !providerName || !scheduledDate || !scheduledTime || !address || totalAmount == null) {
      return res.status(400).json({ error: 'Missing required booking fields (serviceId, serviceTitle, providerName, scheduledDate, scheduledTime, address, totalAmount)' });
    }
    const svc = await Service.findById(serviceId).select('providerId').lean();
    if (!svc) {
      return res.status(404).json({ error: 'Service not found' });
    }

    const providerId = svc.providerId?.toString();
    if (!providerId) {
      return res.status(400).json({ error: 'Selected service has no provider' });
    }
    if (bodyProviderId && bodyProviderId.toString() !== providerId) {
      return res.status(400).json({ error: 'providerId does not match selected service provider' });
    }
    if (providerId === req.user.id) {
      return res.status(400).json({ error: 'You cannot book your own service' });
    }

    const booking = await Booking.create({
      userId: req.user.id,
      providerId,
      serviceId,
      serviceTitle,
      providerName,
      scheduledDate,
      scheduledTime,
      scheduledAt: parseScheduledAt(scheduledDate, scheduledTime),
      address,
      totalAmount: Number(totalAmount),
      imageUrl: imageUrl || undefined,
      status: 'pending',
      paymentStatus: 'unpaid',
      cancellationPolicy: ['flexible', 'moderate', 'strict'].includes((cancellationPolicy || '').toString())
        ? cancellationPolicy
        : 'flexible',
    });
    res.status(201).json(toBookingJson(booking));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

async function handleAccept(req, res) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    const actor = resolveMutationActor(req, booking);
    if (actor !== 'provider' || !canAccessBooking(req, booking, actor)) {
      return res.status(403).json({ error: 'Only the host can accept this request' });
    }
    const from = effectiveStatus(booking);
    booking.status = from;
    if (!canTransition(from, 'confirmed')) {
      return res.status(400).json({ error: `Cannot accept booking from status "${from}"` });
    }
    await updateStatus({
      booking,
      toStatus: 'confirmed',
      actorId: req.user.id,
      reason: (req.body?.reason || '').toString().trim() || undefined,
      updatePaymentStatus: 'paid',
    });
    return res.json(toBookingJson(booking));
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function handleDecline(req, res) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    const actor = resolveMutationActor(req, booking);
    if (actor !== 'provider' || !canAccessBooking(req, booking, actor)) {
      return res.status(403).json({ error: 'Only the host can decline this request' });
    }
    const from = effectiveStatus(booking);
    booking.status = from;
    if (!canTransition(from, 'declined')) {
      return res.status(400).json({ error: `Cannot decline booking from status "${from}"` });
    }
    await updateStatus({
      booking,
      toStatus: 'declined',
      actorId: req.user.id,
      reason: (req.body?.reason || '').toString().trim() || 'Host unavailable for selected schedule.',
    });
    return res.json(toBookingJson(booking));
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function handleCancel(req, res) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    const actor = resolveMutationActor(req, booking);
    if (actor !== 'customer' || !canAccessBooking(req, booking, actor)) {
      return res.status(403).json({ error: 'Only the customer can cancel this booking' });
    }
    const from = effectiveStatus(booking);
    booking.status = from;
    if (!allowedCancelFrom.has(from)) {
      return res.status(400).json({ error: `Cannot cancel booking from status "${from}"` });
    }
    const role = actor;
    const reason = (req.body?.reason || '').toString().trim() || 'Cancelled by customer';
    const refundAmount = Number(booking.totalAmount || 0) * 0.5;
    booking.refundAmount = refundAmount;
    await updateStatus({
      booking,
      toStatus: 'cancelled',
      actorId: req.user.id,
      reason,
      cancelledByRole: role,
      updatePaymentStatus: refundAmount > 0 ? 'refunded' : booking.paymentStatus,
    });
    return res.json(toBookingJson(booking));
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function handleStart(req, res) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    const actor = resolveMutationActor(req, booking);
    if (actor !== 'provider' || !canAccessBooking(req, booking, actor)) {
      return res.status(403).json({ error: 'Only the host can start this booking' });
    }
    const from = effectiveStatus(booking);
    booking.status = from;
    if (!canTransition(from, 'ongoing')) {
      return res.status(400).json({ error: `Cannot start booking from status "${from}"` });
    }
    await updateStatus({
      booking,
      toStatus: 'ongoing',
      actorId: req.user.id,
      reason: (req.body?.reason || '').toString().trim() || undefined,
    });
    return res.json(toBookingJson(booking));
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

async function handleComplete(req, res) {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    const actor = resolveMutationActor(req, booking);
    if (actor !== 'provider' || !canAccessBooking(req, booking, actor)) {
      return res.status(403).json({ error: 'Only the host can complete this booking' });
    }
    const from = effectiveStatus(booking);
    booking.status = from;
    if (!canTransition(from, 'completed')) {
      return res.status(400).json({ error: `Cannot complete booking from status "${from}"` });
    }
    await updateStatus({
      booking,
      toStatus: 'completed',
      actorId: req.user.id,
      reason: (req.body?.reason || '').toString().trim() || undefined,
    });
    return res.json(toBookingJson(booking));
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

router.patch('/:id/accept', requirePermission('bookings.respond'), handleAccept);
router.post('/:id/accept', requirePermission('bookings.respond'), handleAccept);

router.patch('/:id/decline', requirePermission('bookings.respond'), handleDecline);
router.post('/:id/decline', requirePermission('bookings.respond'), handleDecline);

router.patch('/:id/cancel', requirePermission('bookings.cancel'), handleCancel);
router.post('/:id/cancel', requirePermission('bookings.cancel'), handleCancel);

router.patch('/:id/start', requirePermission('bookings.update_progress'), handleStart);
router.post('/:id/start', requirePermission('bookings.update_progress'), handleStart);

router.patch('/:id/complete', requirePermission('bookings.update_progress'), handleComplete);
router.post('/:id/complete', requirePermission('bookings.update_progress'), handleComplete);

function requiredPermissionForStatus(next) {
  if (next === 'confirmed' || next === 'declined') return 'bookings.respond';
  if (next === 'ongoing' || next === 'completed') return 'bookings.update_progress';
  if (next === 'cancelled') return 'bookings.cancel';
  return null;
}

function hasRequiredPermission(req, permission) {
  const roles = req.user?.roles || [];
  if (roles.includes('admin')) return true;
  if (permission === 'bookings.respond') return roles.includes('provider');
  if (permission === 'bookings.update_progress') return roles.includes('provider');
  if (permission === 'bookings.cancel') return roles.includes('customer') || roles.includes('provider');
  return false;
}

// Compatibility: older clients can PATCH /bookings/:id with { status: ... }.
router.patch('/:id', requirePermission('bookings.read'), async (req, res) => {
  const next = normalizeStatus(req.body?.status);
  if (!next || !VALID_STATUSES.has(next)) {
    return res.status(400).json({ error: 'Valid status is required' });
  }
  const permission = requiredPermissionForStatus(next);
  if (!permission || !hasRequiredPermission(req, permission)) {
    return res.status(403).json({ error: 'Forbidden', message: 'Insufficient permission' });
  }
  if (next === 'confirmed') return handleAccept(req, res);
  if (next === 'declined') return handleDecline(req, res);
  if (next === 'cancelled') return handleCancel(req, res);
  if (next === 'ongoing') return handleStart(req, res);
  if (next === 'completed') return handleComplete(req, res);
  return res.status(400).json({ error: `Transition to "${next}" is not allowed` });
});

// Compatibility: older clients can POST /bookings/:id with { status: ... }.
router.post('/:id', requirePermission('bookings.read'), async (req, res) => {
  const next = normalizeStatus(req.body?.status);
  if (!next || !VALID_STATUSES.has(next)) {
    return res.status(400).json({ error: 'Valid status is required' });
  }
  const permission = requiredPermissionForStatus(next);
  if (!permission || !hasRequiredPermission(req, permission)) {
    return res.status(403).json({ error: 'Forbidden', message: 'Insufficient permission' });
  }
  if (next === 'confirmed') return handleAccept(req, res);
  if (next === 'declined') return handleDecline(req, res);
  if (next === 'cancelled') return handleCancel(req, res);
  if (next === 'ongoing') return handleStart(req, res);
  if (next === 'completed') return handleComplete(req, res);
  return res.status(400).json({ error: `Transition to "${next}" is not allowed` });
});

module.exports = router;
