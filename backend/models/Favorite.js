const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  serviceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },
}, { timestamps: true });

favoriteSchema.index({ userId: 1, serviceId: 1 }, { unique: true });

favoriteSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    ret.userId = ret.userId?.toString?.() ?? ret.userId;
    ret.serviceId = ret.serviceId?.toString?.() ?? ret.serviceId;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Favorite', favoriteSchema);

