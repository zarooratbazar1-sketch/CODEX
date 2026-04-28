const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../../db/pool');
const config = require('../../config/env');

async function registerUser({ fullName, email, password, roleId }) {
  const hash = await bcrypt.hash(password, 12);
  const query = `
    INSERT INTO users (role_id, full_name, email, password_hash)
    VALUES ($1, $2, $3, $4)
    RETURNING id, role_id, full_name, email;
  `;
  const { rows } = await db.query(query, [roleId, fullName, email, hash]);
  return rows[0];
}

async function loginUser({ email, password }) {
  const userQuery = `
    SELECT u.id, u.full_name, u.email, u.password_hash, r.code as role_code,
      COALESCE(array_agg(p.code) FILTER (WHERE p.code IS NOT NULL), '{}') as permissions
    FROM users u
    JOIN roles r ON r.id = u.role_id
    LEFT JOIN role_permissions rp ON rp.role_id = r.id
    LEFT JOIN permissions p ON p.id = rp.permission_id
    WHERE u.email = $1 AND u.is_active = TRUE
    GROUP BY u.id, r.code;
  `;

  const { rows } = await db.query(userQuery, [email]);
  const user = rows[0];
  if (!user) throw new Error('Invalid credentials');

  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) throw new Error('Invalid credentials');

  const payload = {
    sub: user.id,
    role: user.role_code,
    permissions: user.permissions,
  };

  return {
    accessToken: jwt.sign(payload, config.jwtSecret, { expiresIn: config.jwtExpiresIn }),
    refreshToken: jwt.sign({ sub: user.id }, config.jwtRefreshSecret, { expiresIn: config.jwtRefreshExpiresIn }),
    user: { id: user.id, fullName: user.full_name, email: user.email, role: user.role_code },
  };
}

module.exports = { registerUser, loginUser };
