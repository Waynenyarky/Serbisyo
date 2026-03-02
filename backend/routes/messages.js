const express = require('express');
const MessageThread = require('../models/MessageThread');
const Booking = require('../models/Booking');
const Service = require('../models/Service');
const { authMiddleware } = require('./auth');
const { requirePermission, loadUserRole } = require('../middleware/rbac');
const mongoose = require('mongoose');

const router = express.Router();
router.use(authMiddleware);

// List threads: customer = where userId=me, provider = where providerId=me
router.get('/threads', requirePermission('messages.read'), async (req, res) => {
  try {
    const filter = req.user.roleSlug === 'provider'
      ? { providerId: req.user.id }
      : { userId: req.user.id };
    const threads = await MessageThread.find(filter).lean();
    const list = threads.map(t => {
      const lastMsg = t.messages?.length ? t.messages[t.messages.length - 1] : null;
      const unreadCount = (t.messages || []).filter(m => !m.readAt && m.senderId?.toString() !== req.user.id).length;
      return {
        id: t._id.toString(),
        providerName: t.providerName,
        serviceTitle: t.serviceTitle,
        lastMessage: lastMsg?.text ?? '',
        lastMessageAt: lastMsg ? new Date(lastMsg.createdAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }) : '',
        unreadCount,
      };
    });
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get one thread: allow if user is customer (userId) or provider (providerId)
router.get('/threads/:id', requirePermission('messages.read'), async (req, res) => {
  try {
    const thread = await MessageThread.findOne({
      _id: req.params.id,
      $or: [{ userId: req.user.id }, { providerId: req.user.id }],
    }).lean();
    if (!thread) return res.status(404).json({ error: 'Thread not found' });
    const messages = (thread.messages || []).map(m => ({
      id: m._id.toString(),
      text: m.text,
      isMe: m.senderId?.toString() === req.user.id,
      time: new Date(m.createdAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }),
    }));
    res.json({
      id: thread._id.toString(),
      providerName: thread.providerName,
      serviceTitle: thread.serviceTitle,
      messages,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create thread: customer only; body bookingId (providerId/providerName/serviceTitle from booking)
router.post('/threads', requirePermission('messages.create_thread'), async (req, res) => {
  try {
    const { bookingId } = req.body;
    if (!bookingId) return res.status(400).json({ error: 'bookingId required' });
    const booking = await Booking.findOne({ _id: bookingId, userId: req.user.id }).lean();
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    const existing = await MessageThread.findOne({
      userId: req.user.id,
      providerId: booking.providerId,
      bookingId: booking._id,
    });
    if (existing) {
      return res.json({
        id: existing._id.toString(),
        providerName: existing.providerName,
        serviceTitle: existing.serviceTitle,
        messages: (existing.messages || []).map(m => ({
          id: m._id.toString(),
          text: m.text,
          isMe: m.senderId?.toString() === req.user.id,
          time: new Date(m.createdAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }),
        })),
      });
    }
    const thread = await MessageThread.create({
      userId: req.user.id,
      providerId: booking.providerId,
      providerName: booking.providerName,
      serviceTitle: booking.serviceTitle,
      bookingId: booking._id,
      messages: [],
    });
    res.status(201).json({
      id: thread._id.toString(),
      providerName: thread.providerName,
      serviceTitle: thread.serviceTitle,
      messages: [],
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create direct thread from a service (no booking required): customer only
router.post('/threads/direct', requirePermission('messages.create_thread'), async (req, res) => {
  try {
    const { serviceId } = req.body;
    if (!serviceId) return res.status(400).json({ error: 'serviceId required' });

    const service = await Service.findById(serviceId).lean();
    if (!service || !service.providerId) {
      return res.status(404).json({ error: 'Service or provider not found' });
    }

    const existing = await MessageThread.findOne({
      userId: req.user.id,
      providerId: service.providerId,
      bookingId: null,
      serviceTitle: service.title,
    });
    if (existing) {
      return res.json({
        id: existing._id.toString(),
        providerName: existing.providerName,
        serviceTitle: existing.serviceTitle,
        messages: (existing.messages || []).map(m => ({
          id: m._id.toString(),
          text: m.text,
          isMe: m.senderId?.toString() === req.user.id,
          time: new Date(m.createdAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }),
        })),
      });
    }

    const thread = await MessageThread.create({
      userId: req.user.id,
      providerId: service.providerId,
      providerName: service.providerName,
      serviceTitle: service.title,
      messages: [],
    });
    res.status(201).json({
      id: thread._id.toString(),
      providerName: thread.providerName,
      serviceTitle: thread.serviceTitle,
      messages: [],
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Send message: allow if user is participant (userId or providerId)
router.post('/threads/:id/messages', requirePermission('messages.send'), async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) return res.status(400).json({ error: 'Message text required' });
    const thread = await MessageThread.findOne({
      _id: req.params.id,
      $or: [{ userId: req.user.id }, { providerId: req.user.id }],
    });
    if (!thread) return res.status(404).json({ error: 'Thread not found' });
    thread.messages.push({
      senderId: new mongoose.Types.ObjectId(req.user.id),
      text: text.trim(),
    });
    await thread.save();
    const msg = thread.messages[thread.messages.length - 1];
    res.status(201).json({
      id: msg._id.toString(),
      text: msg.text,
      isMe: true,
      time: new Date(msg.createdAt).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' }),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
