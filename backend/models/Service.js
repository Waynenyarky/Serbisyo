const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  title: { type: String, required: true },
  categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'ServiceCategory', required: true },
  providerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  imageUrl: { type: String },
  rating: { type: Number, default: 0 },
  reviewCount: { type: Number, default: 0 },
  pricePerHour: { type: Number, default: 0 },
  providerName: { type: String, required: true },
  description: { type: String },
  // Richer detail for premium service page
  offers: { type: String },
  locationDescription: { type: String },
  availability: { type: String },
  thingsToKnow: { type: String },
  status: { type: String, enum: ['draft', 'active'], default: 'draft' },
}, { timestamps: true });

serviceSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    ret.categoryId = ret.categoryId?.toString?.() ?? ret.categoryId;
    ret.providerId = ret.providerId?.toString?.() ?? ret.providerId;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Service', serviceSchema);
