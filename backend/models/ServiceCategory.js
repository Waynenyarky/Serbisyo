const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  name: { type: String, required: true },
  assetImagePath: { type: String, default: 'assets/images/placeholders/placeholder.png' },
}, { timestamps: true });

categorySchema.index({ name: 1 }, { unique: true });

categorySchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('ServiceCategory', categorySchema);
