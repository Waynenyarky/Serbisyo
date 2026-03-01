const mongoose = require('mongoose');

const providerProfileSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  phone: { type: String },
  address: { type: String },
  bio: { type: String },
  serviceArea: { type: String },
  avatarUrl: { type: String },
  isVerified: { type: Boolean, default: false },
  payoutMethodAdded: { type: Boolean, default: false },
}, { timestamps: true });

providerProfileSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    ret.userId = ret.userId?.toString?.() ?? ret.userId;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('ProviderProfile', providerProfileSchema);
