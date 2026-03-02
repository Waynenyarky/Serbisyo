const path = require('path');
const User = require('../models/User');
const AdminLog = require('../models/AdminLog');
// Resolve auth from routes explicitly (avoid ./auth from middleware folder)
const { authMiddleware } = require(path.join(__dirname, '..', 'routes', 'auth'));

const PERMISSIONS = {
  customer: new Set([
    'bookings.read',
    'bookings.create',
    'messages.read',
    'messages.create_thread',
    'messages.send',
    'services.read',
    'providers.read_public',
  ]),
  provider: new Set([
    'bookings.read',
    'messages.read',
    'messages.send',
    'services.read',
    'services.manage_own',
    'providers.manage_self',
    'providers.read_public',
  ]),
  admin: new Set(['*']),
};

function deriveRoles(user) {
  const roles = [];
  if (user.is_customer) roles.push('customer');
  if (user.is_provider) roles.push('provider');
  if (user.is_admin) roles.push('admin');
  return roles;
}

function primaryRole(roles) {
  if (roles.includes('admin')) return 'admin';
  if (roles.includes('provider')) return 'provider';
  if (roles.includes('customer')) return 'customer';
  return null;
}

function hasPermission(roles, permission) {
  return roles.some((role) => {
    const set = PERMISSIONS[role];
    return set?.has('*') || set?.has(permission);
  });
}

async function auditForbidden(req, permissionOrRole) {
  try {
    await AdminLog.create({
      action: 'forbidden_access',
      performedBy: req.user?.id || null,
      details: {
        permissionOrRole,
        method: req.method,
        path: req.originalUrl,
        userAgent: req.headers['user-agent'] || null,
        roleSlug: req.user?.roleSlug || null,
        roles: req.user?.roles || [],
      },
    });
  } catch (_) {
    // Swallow audit failures to avoid blocking API response path.
  }
}

async function loadAuthzContext(req) {
  const user = await User.findById(req.user.id)
    .select('is_customer is_provider is_admin admin_role')
    .lean();
  if (!user) return null;
  const roles = deriveRoles(user);
  req.user.roles = roles;
  req.user.roleSlug = primaryRole(roles);
  req.user.admin_role = user.admin_role || null;
  req.user.is_customer = !!user.is_customer;
  req.user.is_provider = !!user.is_provider;
  req.user.is_admin = !!user.is_admin;
  return user;
}

/**
 * Require the request user to have one of the given roles (by slug).
 * Must be used after authMiddleware. Loads user with role and sets req.user.roleSlug.
 */
function requireRole(...allowedSlugs) {
  return async (req, res, next) => {
    try {
      const user = await loadAuthzContext(req);
      if (!user) return res.status(401).json({ error: 'User not found' });
      const roleSlug = req.user.roleSlug;
      if (!roleSlug || !allowedSlugs.includes(roleSlug)) {
        await auditForbidden(req, `roles:${allowedSlugs.join(',')}`);
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
    const user = await loadAuthzContext(req);
    if (!user) return next();
    next();
  } catch (err) {
    next(err);
  }
}

function requirePermission(permission) {
  return async (req, res, next) => {
    try {
      const user = await loadAuthzContext(req);
      if (!user) return res.status(401).json({ error: 'User not found' });
      if (!hasPermission(req.user.roles || [], permission)) {
        await auditForbidden(req, `permission:${permission}`);
        return res.status(403).json({ error: 'Forbidden', message: 'Insufficient permission' });
      }
      next();
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  };
}

module.exports = { requireRole, requirePermission, loadUserRole, authMiddleware };
