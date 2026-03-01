const path = require('path');
const User = require('../models/User');
// Resolve auth from routes explicitly (avoid ./auth from middleware folder)
const { authMiddleware } = require(path.join(__dirname, '..', 'routes', 'auth'));

/**
 * Require the request user to have one of the given roles (by slug).
 * Must be used after authMiddleware. Loads user with role and sets req.user.roleSlug.
 */
function requireRole(...allowedSlugs) {
  return async (req, res, next) => {
    try {
      const user = await User.findById(req.user.id).populate('roleId').lean();
      if (!user) return res.status(401).json({ error: 'User not found' });
      const roleSlug = user.roleId?.slug ?? null;
      req.user.roleSlug = roleSlug;
      req.user.roleId = user.roleId?._id?.toString() ?? user.roleId;
      if (!roleSlug || !allowedSlugs.includes(roleSlug)) {
        return res.status(403).json({ error: 'Forbidden', message: 'Insufficient role' });
      }
      next();
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  };
}

/**
 * Optionally load user role into req.user.roleSlug (for routes that allow multiple roles but need to know which).
 */
async function loadUserRole(req, res, next) {
  try {
    const user = await User.findById(req.user.id).populate('roleId').lean();
    if (!user) return next();
    req.user.roleSlug = user.roleId?.slug ?? null;
    req.user.roleId = user.roleId?._id?.toString() ?? user.roleId;
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { requireRole, loadUserRole, authMiddleware };
