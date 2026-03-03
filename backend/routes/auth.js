const express = require('express');
const jwt = require('jsonwebtoken');
const passport = require('passport');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

const VALID_SIGNUP_ROLES = ['customer', 'provider'];
const googleOauthClient = new OAuth2Client();

function primaryRole(user) {
  if (user.is_admin) return 'admin';
  if (user.is_provider) return 'provider';
  return 'customer';
}

function issueToken(user) {
  return jwt.sign({
    id: user._id.toString(),
    email: user.email,
    roles: {
      is_customer: !!user.is_customer,
      is_provider: !!user.is_provider,
      is_admin: !!user.is_admin,
      admin_role: user.admin_role || null,
    },
  }, JWT_SECRET);
}

const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  try {
    req.authToken = token;
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};

function toUserResponse(user) {
  const u = user.toObject ? user.toObject() : user;
  return {
    id: u._id.toString(),
    email: u.email,
    fullName: u.fullName,
    role: primaryRole(u),
    is_customer: !!u.is_customer,
    is_provider: !!u.is_provider,
    is_admin: !!u.is_admin,
    admin_role: u.admin_role || null,
    oauthProviders: {
      google: u.oauthProviders?.google?.id
        ? {
          email: u.oauthProviders.google.email || null,
          linkedAt: u.oauthProviders.google.linkedAt || null,
        }
        : null,
    },
  };
}

function authResponse(user, token) {
  return {
    user: toUserResponse(user),
    token,
  };
}

router.post('/register', async (req, res) => {
  try {
    const { email, password, fullName, role: roleSlug } = req.body;
    if (!email || !password || !fullName) {
      return res.status(400).json({ error: 'Email, password and fullName required' });
    }
    const slug = (roleSlug || 'customer').toLowerCase();
    if (!VALID_SIGNUP_ROLES.includes(slug)) {
      return res.status(400).json({ error: 'Role must be customer or provider' });
    }
    const normalizedEmail = email.toLowerCase();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) return res.status(400).json({ error: 'Email already registered' });
    const user = await User.create({
      email: normalizedEmail,
      password,
      fullName,
      is_customer: true,
      is_provider: slug === 'provider',
      is_admin: false,
      admin_role: null,
    });
    const token = issueToken(user);
    res.status(201).json(authResponse(user, token));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const token = issueToken(user);
    res.json(authResponse(user, token));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/me', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    const token = req.authToken || issueToken(user);
    res.json(authResponse(user, token));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/oauth/google', (req, res, next) => {
  const requestedRole = (req.query.role || 'customer').toString().toLowerCase();
  if (!VALID_SIGNUP_ROLES.includes(requestedRole)) {
    return res.status(400).json({ error: 'Role must be customer or provider' });
  }
  passport.authenticate('google', {
    scope: ['profile', 'email'],
    session: false,
    state: requestedRole,
  })(req, res, next);
});

router.get('/oauth/google/callback', (req, res, next) => {
  passport.authenticate('google', { session: false }, async (err, user) => {
    if (err) return res.status(500).json({ error: err.message });
    if (!user) return res.status(401).json({ error: 'OAuth authentication failed' });
    const token = issueToken(user);
    return res.json(authResponse(user, token));
  })(req, res, next);
});

router.post('/oauth/google/mobile', async (req, res) => {
  try {
    const { idToken, role: requestedRoleRaw } = req.body || {};
    if (!idToken) {
      return res.status(400).json({ error: 'idToken is required' });
    }

    const requestedRole = (requestedRoleRaw || 'customer').toString().toLowerCase();
    if (!VALID_SIGNUP_ROLES.includes(requestedRole)) {
      return res.status(400).json({ error: 'Role must be customer or provider' });
    }

    const googleAudience = process.env.GOOGLE_CLIENT_ID || process.env.GOOGLE_WEB_CLIENT_ID;
    if (!googleAudience) {
      return res.status(500).json({ error: 'Google OAuth audience is not configured on server' });
    }

    const ticket = await googleOauthClient.verifyIdToken({
      idToken,
      audience: googleAudience,
    });
    const payload = ticket.getPayload();
    if (!payload) {
      return res.status(401).json({ error: 'Invalid Google token' });
    }

    const googleId = payload.sub;
    const email = payload.email?.toLowerCase();
    const fullName = payload.name || payload.email;
    if (!googleId || !email || !fullName) {
      return res.status(401).json({ error: 'Google profile is missing required fields' });
    }

    let user = await User.findOne({ email });
    if (!user) {
      user = await User.create({
        email,
        fullName,
        is_customer: true,
        is_provider: requestedRole === 'provider',
        is_admin: false,
        admin_role: null,
        oauthProviders: {
          google: {
            id: googleId,
            email,
            linkedAt: new Date(),
          },
        },
      });
    } else {
      user.fullName = user.fullName || fullName;
      user.is_customer = true;
      if (requestedRole === 'provider') {
        user.is_provider = true;
      }
      user.oauthProviders = user.oauthProviders || {};
      user.oauthProviders.google = {
        id: googleId,
        email,
        linkedAt: user.oauthProviders?.google?.linkedAt || new Date(),
      };
      await user.save();
    }

    const token = issueToken(user);
    return res.json(authResponse(user, token));
  } catch (err) {
    return res.status(401).json({ error: err.message || 'Google authentication failed' });
  }
});

module.exports = router;
module.exports.authMiddleware = authMiddleware;
