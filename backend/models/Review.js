const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true, index: true },
  reviewerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  revieweeId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  roleType: { type: String, enum: ['guest_to_host', 'host_to_guest'], required: true },
  serviceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service' },
  ratingOverall: { type: Number, min: 1, max: 5, required: true },
  ratings: {
    cleanliness: { type: Number, min: 1, max: 5 },
    accuracy: { type: Number, min: 1, max: 5 },
    communication: { type: Number, min: 1, max: 5 },
    location: { type: Number, min: 1, max: 5 },
    value: { type: Number, min: 1, max: 5 },
    behavior: { type: Number, min: 1, max: 5 },
    ruleCompliance: { type: Number, min: 1, max: 5 },
  },
  comment: { type: String, default: '' },
}, { timestamps: true });

reviewSchema.index({ bookingId: 1, reviewerId: 1, roleType: 1 }, { unique: true });
reviewSchema.index({ revieweeId: 1, createdAt: -1 });

reviewSchema.set('toJSON', {
  virtuals: true,
  transform: (_doc, ret) => {
    ret.id = ret._id.toString();
    ret.bookingId = ret.bookingId?.toString?.() ?? ret.bookingId;
    ret.reviewerId = ret.reviewerId?.toString?.() ?? ret.reviewerId;
    ret.revieweeId = ret.revieweeId?.toString?.() ?? ret.revieweeId;
    ret.serviceId = ret.serviceId?.toString?.() ?? ret.serviceId;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Review', reviewSchema);
