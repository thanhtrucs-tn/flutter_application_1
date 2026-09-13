const request = require('supertest');
const { app, cleanDb, registerAndLogin, authHeader } = require('./helpers/test-utils');

describe('Auth profile endpoints', () => {
  beforeEach(async () => {
    await cleanDb();
  });

  it('register returns name/phone and a JWT token', async () => {
    const email = `reg_${Date.now()}@test.com`;
    const res = await request(app).post('/api/auth/register').send({
      email,
      password: 'Pass1234!',
      name: 'Nguyễn Văn A',
      phone: '0901234567',
    });

    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(email);
    expect(res.body.data.user.name).toBe('Nguyễn Văn A');
    expect(res.body.data.user.phone).toBe('0901234567');
    expect(res.body.data.user.role).toBe('caregiver');
    expect(typeof res.body.data.token).toBe('string');
  });

  it('GET /api/auth/profile returns the logged-in user profile', async () => {
    const email = `prof_${Date.now()}@test.com`;
    const { token, userId } = await registerAndLogin(email, { name: 'Profile User' });

    const res = await request(app).get('/api/auth/profile').set(authHeader(token));

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBe(userId);
    expect(res.body.data.email).toBe(email);
    expect(res.body.data.name).toBe('Profile User');
  });

  it('PUT /api/auth/profile updates name/phone/avatarUrl and persists', async () => {
    const email = `upd_${Date.now()}@test.com`;
    const { token } = await registerAndLogin(email);

    const res = await request(app).put('/api/auth/profile').set(authHeader(token)).send({
      name: 'Updated Name',
      phone: '0999888777',
      avatarUrl: 'https://cdn.test/a.png',
    });

    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Updated Name');
    expect(res.body.data.phone).toBe('0999888777');
    expect(res.body.data.avatarUrl).toBe('https://cdn.test/a.png');

    const get = await request(app).get('/api/auth/profile').set(authHeader(token));
    expect(get.body.data.name).toBe('Updated Name');
    expect(get.body.data.avatarUrl).toBe('https://cdn.test/a.png');
  });

  it('GET /api/auth/profile without a token returns 401', async () => {
    const res = await request(app).get('/api/auth/profile');

    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});