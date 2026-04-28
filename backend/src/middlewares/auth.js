const jwt = require('jsonwebtoken');
const config = require('../config/env');

function authenticate(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Missing Bearer token' });
  }

  const token = header.slice(7);
  try {
    req.user = jwt.verify(token, config.jwtSecret);
    return next();
  } catch {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

function authorize(requiredPermissions = []) {
  return (req, res, next) => {
    const userPerms = req.user?.permissions || [];
    const missing = requiredPermissions.filter((perm) => !userPerms.includes(perm));
    if (missing.length > 0) {
      return res.status(403).json({ message: 'Insufficient permissions', missing });
    }
    return next();
  };
}

module.exports = { authenticate, authorize };
