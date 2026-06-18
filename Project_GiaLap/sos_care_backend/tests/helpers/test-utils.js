const request = require('supertest');
const createApp = require('../../src/app');
const { sequelize } = require('../../src/models');
const socketService = require('../../src/services/socket.service');

// Single Express app reused across all test files. createApp() does not
// eagerly open a DB connection — sequelize connects lazily on first query.
const app = createApp();

// Business tables only. sequelize_meta is intentionally excluded so
// migrations are never wiped. FK checks are disabled during truncation so
// order is irrelevant, then re-enabled.
const TABLES = [
  'alerts',
  'emergency_contacts',
  'relatives',
  'device_statuses',
  'events',
  'locations',
  'sos_alerts',
  'devices',
  'users',
];

async function cleanDb() {
  await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const table of TABLES) {
    await sequelize.query(`TRUNCATE TABLE \`${table}\``);
  }
  await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');
}

// Register a caregiver and return { token, userId }. Real HTTP via supertest,
// real DB write. Throws on non-201 so test failures surface a clear cause.
async function registerAndLogin(email, { name, password } = {}) {
  const res = await request(app)
    .post('/api/auth/register')
    .send({
      email,
      password: password || 'Pass1234!',
      name: name || 'Test Caregiver',
    });
  if (res.statusCode !== 201) {
    throw new Error(`register failed for ${email}: ${res.statusCode} ${JSON.stringify(res.body)}`);
  }
  return {
    token: res.body.data.token,
    userId: res.body.data.user.id,
  };
}

function authHeader(token) {
  return { Authorization: `Bearer ${token}` };
}

// Spies on both socket emit methods. Originals are no-ops in tests (io is
// null), so callThrough is safe — the spy records the call then the original
// guards on `if (this.io)` and does nothing. Returns restore() for afterEach.
function trackSocket() {
  const emitSpy = jest.spyOn(socketService, 'emit');
  const emitToRoomSpy = jest.spyOn(socketService, 'emitToRoom');
  return {
    emitSpy,
    emitToRoomSpy,
    restore() {
      emitSpy.mockRestore();
      emitToRoomSpy.mockRestore();
    },
  };
}

module.exports = {
  app,
  cleanDb,
  registerAndLogin,
  authHeader,
  trackSocket,
  sequelize,
  socketService,
};