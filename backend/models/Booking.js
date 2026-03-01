const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  providerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  serviceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },
  serviceTitle: { type: String, required: true },
  providerName: { type: String, required: true },
  scheduledDate: { type: String, required: true },
  scheduledTime: { type: String, required: true },
  address: { type: String, required: true },
  status: { type: String, enum: ['upcoming', 'completed', 'cancelled'], default: 'upcoming' },
  totalAmount: { type: Number, required: true },
  imageUrl: { type: String },
}, { timestamps: true });

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
