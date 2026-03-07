const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true, index: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  providerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'PHP' },
  method: { type: String, default: 'card' },
  providerRef: { type: String },
  status: {
    type: String,
    enum: ['authorized', 'captured', 'refunded', 'failed'],
    default: 'authorized',
  },
  refundedAmount: { type: Number, default: 0 },
  meta: { type: Object, default: {} },
}, { timestamps: true });

paymentSchema.index({ bookingId: 1, createdAt: -1 });

paymentSchema.set('toJSON', {
  virtuals: true,
  transform: (_doc, ret) => {
    ret.id = ret._id.toString();
    ret.bookingId = ret.bookingId?.toString?.() ?? ret.bookingId;
    ret.userId = ret.userId?.toString?.() ?? ret.userId;
    ret.providerId = ret.providerId?.toString?.() ?? ret.providerId;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Payment', paymentSchema);
