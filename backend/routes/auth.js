const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Role = require('../models/Role');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};

function toUserResponse(user) {
  const u = user.toObject ? user.toObject() : user;
  const roleId = u.roleId;
  const roleSlug = roleId?.slug ?? (roleId?.slug !== undefined ? roleId.slug : null);
  return {
    id: u._id.toString(),
    email: u.email,
    fullName: u.fullName,
    role: roleSlug ?? (roleId?.toString?.() ? undefined : null),
    roleId: roleId?._id?.toString?.() ?? roleId?.toString?.() ?? u.roleId?.toString?.(),
  };
}

router.post('/register', async (req, res) => {
  try {
    const { email, password, fullName, role: roleSlug } = req.body;
    if (!email || !password || !fullName) {
      return res.status(400).json({ error: 'Email, password and fullName required' });
    }
    const allowedRoles = ['customer', 'provider'];
    const slug = (roleSlug || 'customer').toLowerCase();
    if (!allowedRoles.includes(slug)) {
      return res.status(400).json({ error: 'Role must be customer or provider' });
    }
    const role = await Role.findOne({ slug });
    if (!role) return res.status(400).json({ error: 'Invalid role; ensure roles are seeded' });
    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ error: 'Email already registered' });
    const user = await User.create({ email, password, fullName, roleId: role._id });
    const token = jwt.sign({ id: user._id.toString(), email: user.email }, JWT_SECRET);
    const populated = await User.findById(user._id).populate('roleId').select('-password');
    res.status(201).json({
      user: { ...toUserResponse(populated), role: slug },
      token,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });
    const user = await User.findOne({ email }).populate('roleId');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const token = jwt.sign({ id: user._id.toString(), email: user.email }, JWT_SECRET);
    const roleSlug = user.roleId?.slug ?? null;
    res.json({
      user: {
        id: user._id.toString(),
        email: user.email,
        fullName: user.fullName,
        role: roleSlug,
        roleId: user.roleId?._id?.toString?.() ?? user.roleId?.toString?.(),
      },
      token,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/me', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate('roleId').select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    const roleSlug = user.roleId?.slug ?? null;
    res.json({
      id: user._id.toString(),
      email: user.email,
      fullName: user.fullName,
      role: roleSlug,
      roleId: user.roleId?._id?.toString?.() ?? user.roleId?.toString?.(),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
module.exports.authMiddleware = authMiddleware;
