const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  threadId: { type: mongoose.Schema.Types.ObjectId, ref: 'MessageThread', required: true },
  senderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  text: { type: String, required: true },
  readAt: { type: Date },
}, { timestamps: true });

const threadSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  providerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  providerName: { type: String, required: true },
  serviceTitle: { type: String, required: true },
  bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
  messages: [messageSchema],
}, { timestamps: true });

// Common access and search indexes for thread list queries.
threadSchema.index({ userId: 1, updatedAt: -1 });
threadSchema.index({ providerId: 1, updatedAt: -1 });
threadSchema.index({ providerName: 'text', serviceTitle: 'text', 'messages.text': 'text' });

threadSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    ret.userId = ret.userId?.toString?.() ?? ret.userId;
    ret.providerId = ret.providerId?.toString?.() ?? ret.providerId;
    ret.bookingId = ret.bookingId?.toString?.() ?? ret.bookingId;
    const lastMsg = ret.messages?.length ? ret.messages[ret.messages.length - 1] : null;
    ret.lastMessage = lastMsg?.text ?? '';
    ret.lastMessageAt = lastMsg ? new Date(lastMsg.createdAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }) : '';
    ret.unreadCount = (ret.messages || []).filter(m => !m.readAt && m.senderId?.toString() !== ret.userId).length;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('MessageThread', threadSchema);
