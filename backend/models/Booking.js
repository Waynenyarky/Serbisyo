const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  providerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  serviceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },
  serviceTitle: { type: String, required: true },
  providerName: { type: String, required: true },
  scheduledDate: { type: String, required: true },
  scheduledTime: { type: String, required: true },
  scheduledAt: { type: Date },
  address: { type: String, required: true },
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'declined', 'cancelled', 'ongoing', 'completed'],
    default: 'pending',
  },
  statusReason: { type: String },
  respondedAt: { type: Date },
  cancelledAt: { type: Date },
  completedAt: { type: Date },
  statusUpdatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  cancelledByRole: { type: String, enum: ['customer', 'provider', 'system'] },
  totalAmount: { type: Number, required: true },
  imageUrl: { type: String },
  cancellationPolicy: { type: String, enum: ['flexible', 'moderate', 'strict'], default: 'flexible' },
  refundAmount: { type: Number, default: 0 },
  paymentStatus: {
    type: String,
    enum: ['unpaid', 'authorized', 'paid', 'refunded', 'failed'],
    default: 'unpaid',
  },
}, { timestamps: true });

bookingSchema.index({ userId: 1, scheduledAt: 1, createdAt: -1 });
bookingSchema.index({ providerId: 1, scheduledAt: 1, createdAt: -1 });

bookingSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    ret.serviceId = ret.serviceId?.toString?.() ?? ret.serviceId;
    ret.userId = ret.userId?.toString?.() ?? ret.userId;
    ret.providerId = ret.providerId?.toString?.() ?? ret.providerId;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Booking', bookingSchema);
