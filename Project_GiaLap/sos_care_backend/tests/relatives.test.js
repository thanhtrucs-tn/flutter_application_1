const request = require('supertest');
const { app, cleanDb, registerAndLogin, authHeader } = require('./helpers/test-utils');

const baseRelative = (deviceElderlyId) => ({
  name: 'Bà Lan',
  age: 78,
  address: '12 Lê Lợi, Q1',
  deviceElderlyId,
  safeZoneRadius: 200,
  safeZoneLat: 10.762622,
  safeZoneLng: 106.660172,
  contacts: [
    { name: 'Con trai', phone: '0901111222', relationship: 'Son' },
    { name: 'Hàng xóm', phone: '0903333444', relationship: 'Neighbor' },
  ],
});

describe('Relatives CRUD + owner isolation', () => {
  beforeEach(async () => {
    await cleanDb();
  });

  it('requires auth: GET/POST /api/relatives without token -> 401', async () => {
    expect((await request(app).get('/api/relatives')).statusCode).toBe(401);
    expect((await request(app).post('/api/relatives').send({ name: 'x' })).statusCode).toBe(401);
  });

  it('creates a relative with contacts and reads them back via list', async () => {
    const { token } = await registerAndLogin(`c_${Date.now()}@test.com`);

    const res = await request(app)
      .post('/api/relatives')
      .set(authHeader(token))
      .send(baseRelative('ELDERLY-CREATE'));

    expect(res.statusCode).toBe(201);
    expect(res.body.data.id).toBeTruthy();
    expect(res.body.data.name).toBe('Bà Lan');
    expect(res.body.data.deviceElderlyId).toBe('ELDERLY-CREATE');
    expect(res.body.data.contacts).toHaveLength(2);
    expect(res.body.data.contacts[0]).toMatchObject({ name: 'Con trai', phone: '0901111222' });

    const list = await request(app).get('/api/relatives').set(authHeader(token));
    expect(list.statusCode).toBe(200);
    expect(Array.isArray(list.body.data)).toBe(true);
    expect(list.body.data).toHaveLength(1);
    expect(list.body.data[0].contacts).toHaveLength(2);
  });

  it('get/put/delete a relative work for the owner', async () => {
    const { token } = await registerAndLogin(`o_${Date.now()}@test.com`);
    const created = await request(app)
      .post('/api/relatives')
      .set(authHeader(token))
      .send(baseRelative('ELDERLY-OWNER'));
    const id = created.body.data.id;

    const got = await request(app).get(`/api/relatives/${id}`).set(authHeader(token));
    expect(got.statusCode).toBe(200);
    expect(got.body.data.id).toBe(id);

    const upd = await request(app).put(`/api/relatives/${id}`).set(authHeader(token)).send({
      name: 'Bà Hoa',
      age: 80,
      deviceElderlyId: 'ELDERLY-OWNER',
      contacts: [{ name: 'Con gái', phone: '0911111000' }],
    });
    expect(upd.statusCode).toBe(200);
    expect(upd.body.data.name).toBe('Bà Hoa');
    expect(upd.body.data.contacts).toHaveLength(1);
    expect(upd.body.data.contacts[0].name).toBe('Con gái');

    const del = await request(app).delete(`/api/relatives/${id}`).set(authHeader(token));
    expect(del.statusCode).toBe(200);
    expect(del.body.success).toBe(true);

    const after = await request(app).get(`/api/relatives/${id}`).set(authHeader(token));
    expect(after.statusCode).toBe(404);
  });

  it('cross-user isolation: userB cannot access userA relative (404)', async () => {
    const a = await registerAndLogin(`a_${Date.now()}@test.com`, { name: 'UserA' });
    const b = await registerAndLogin(`b_${Date.now()}@test.com`, { name: 'UserB' });

    const created = await request(app)
      .post('/api/relatives')
      .set(authHeader(a.token))
      .send(baseRelative('ELDERLY-ISO'));
    const id = created.body.data.id;

    expect((await request(app).get(`/api/relatives/${id}`).set(authHeader(b.token))).statusCode).toBe(404);
    expect(
      (await request(app).put(`/api/relatives/${id}`).set(authHeader(b.token)).send({ name: 'Hijack' })).statusCode,
    ).toBe(404);
    expect((await request(app).delete(`/api/relatives/${id}`).set(authHeader(b.token))).statusCode).toBe(404);

    // Owner still sees the relative intact.
    const ownerGet = await request(app).get(`/api/relatives/${id}`).set(authHeader(a.token));
    expect(ownerGet.statusCode).toBe(200);
    expect(ownerGet.body.data.name).toBe('Bà Lan');
  });
});