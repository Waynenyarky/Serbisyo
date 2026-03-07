const express = require('express');
const Payment = require('../models/Payment');
const Booking = require('../models/Booking');
const { authMiddleware } = require('./auth');
const { requirePermission } = require('../middleware/rbac');

const router = express.Router();
router.use(authMiddleware);

function actorRole(req) {
  return (req.user?.roleSlug || '').toString().toLowerCase();
}

router.get('/', requirePermission('payments.read'), async (req, res) => {
  try {
    const role = actorRole(req);
    const filter = role === 'provider'
      ? { providerId: req.user.id }
      : { userId: req.user.id };
    const list = await Payment.find(filter).sort({ createdAt: -1 }).lean();
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Simulated payment authorization/capture for MVP phase.
router.post('/bookings/:bookingId/intent', requirePermission('payments.create'), async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.bookingId);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.userId?.toString() !== req.user.id) {
      return res.status(403).json({ error: 'Only the guest can initiate payment' });
    }

    const payment = await Payment.create({
      bookingId: booking._id,
      userId: booking.userId,
      providerId: booking.providerId,
      amount: booking.totalAmount,
      currency: 'PHP',
      method: (req.body?.method || 'card').toString(),
      providerRef: `SIM-${Date.now()}`,
      status: 'captured',
      meta: {
        last4: (req.body?.last4 || '4242').toString(),
      },
    });

    booking.paymentStatus = 'paid';
    booking.statusUpdatedBy = req.user.id;
    await booking.save();

    res.status(201).json(payment.toJSON());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/bookings/:bookingId/refund', requirePermission('payments.read'), async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.bookingId);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    const role = actorRole(req);
    const canRefund = (role === 'provider' && booking.providerId?.toString() === req.user.id)
      || (role === 'customer' && booking.userId?.toString() === req.user.id);
    if (!canRefund) return res.status(403).json({ error: 'Not allowed to refund this booking' });

    const payment = await Payment.findOne({ bookingId: booking._id }).sort({ createdAt: -1 });
    if (!payment) return res.status(404).json({ error: 'Payment not found for this booking' });

    const requested = Number(req.body?.amount || booking.totalAmount || 0);
    const safeAmount = Math.max(0, Math.min(requested, payment.amount));
    payment.status = safeAmount > 0 ? 'refunded' : payment.status;
    payment.refundedAmount = safeAmount;
    await payment.save();

    booking.refundAmount = safeAmount;
    booking.paymentStatus = safeAmount > 0 ? 'refunded' : booking.paymentStatus;
    booking.statusUpdatedBy = req.user.id;
    await booking.save();

    res.json(payment.toJSON());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
