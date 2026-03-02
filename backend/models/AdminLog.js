const mongoose = require('mongoose');

const adminLogSchema = new mongoose.Schema({
  action: { type: String, required: true },
  performedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  details: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: { createdAt: true, updatedAt: false } });

adminLogSchema.index({ action: 1, createdAt: -1 });
adminLogSchema.index({ performedBy: 1, createdAt: -1 });

adminLogSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    ret.performedBy = ret.performedBy?.toString?.() ?? ret.performedBy ?? null;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('AdminLog', adminLogSchema);