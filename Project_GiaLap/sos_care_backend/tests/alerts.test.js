const request = require('supertest');
const { app, cleanDb, registerAndLogin, authHeader } = require('./helpers/test-utils');

describe('Alerts manual create + read/acknowledge state', () => {
  beforeEach(async () => {
    await cleanDb();
  });

  it('requires auth: GET/POST /api/alerts without token -> 401', async () => {
    expect((await request(app).get('/api/alerts')).statusCode).toBe(401);
    expect((await request(app).post('/api/alerts').send({ message: 'x' })).statusCode).toBe(401);
  });

  it('creates a manual alert (type=sos) tied to a relative and lists it', async () => {
    const { token, userId } = await registerAndLogin(`m_${Date.now()}@test.com`);

    const rel = await request(app)
      .post('/api/relatives')
      .set(authHeader(token))
      .send({ name: 'Ông Bảy', deviceElderlyId: 'ELDERLY-ALERT' });
    const relativeId = rel.body.data.id;

    const res = await request(app).post('/api/alerts').set(authHeader(token)).send({
      type: 'sos',
      urgency: 'critical',
      message: 'Cảnh báo thủ công từ ứng dụng',
      relativeId,
      locationName: 'Phòng khách',
      latitude: 10.762622,
      longitude: 106.660172,
    });

    expect(res.statusCode).toBe(201);
    expect(res.body.data.id).toBeTruthy();
    expect(res.body.data.type).toBe('sos');
    expect(res.body.data.userId).toBe(userId);
    expect(res.body.data.relativeId).toBe(relativeId);
    expect(res.body.data.read).toBe(false);
    expect(res.body.data.acknowledged).toBe(false);

    const list = await request(app).get('/api/alerts').set(authHeader(token));
    expect(list.statusCode).toBe(200);
    expect(Array.isArray(list.body.data)).toBe(true);
    expect(list.body.data).toHaveLength(1);
    expect(list.body.meta.unread).toBeGreaterThanOrEqual(1);
  });

  it('acknowledge and mark-read flip the alert flags and reduce unread', async () => {
    const { token } = await registerAndLogin(`r_${Date.now()}@test.com`);
    const created = await request(app)
      .post('/api/alerts')
      .set(authHeader(token))
      .send({ message: 'Test read/ack', urgency: 'warning' });
    const id = created.body.data.id;

    const ack = await request(app).patch(`/api/alerts/${id}/acknowledge`).set(authHeader(token));
    expect(ack.statusCode).toBe(200);
    expect(ack.body.data.acknowledged).toBe(true);

    const read = await request(app).patch(`/api/alerts/${id}/read`).set(authHeader(token));
    expect(read.statusCode).toBe(200);
    expect(read.body.data.read).toBe(true);

    const list = await request(app).get('/api/alerts').set(authHeader(token));
    expect(list.body.meta.unread).toBe(0);
  });

  it('mark-all-read marks every unread alert for the user', async () => {
    const { token } = await registerAndLogin(`all_${Date.now()}@test.com`);
    await request(app).post('/api/alerts').set(authHeader(token)).send({ message: 'one' });
    await request(app).post('/api/alerts').set(authHeader(token)).send({ message: 'two' });

    const before = await request(app).get('/api/alerts').set(authHeader(token));
    expect(before.body.meta.unread).toBe(2);

    const res = await request(app).post('/api/alerts/mark-all-read').set(authHeader(token));
    expect(res.statusCode).toBe(200);
    expect(res.body.data.markedRead).toBe(2);

    const after = await request(app).get('/api/alerts').set(authHeader(token));
    expect(after.body.meta.unread).toBe(0);
    expect(after.body.data.every((a) => a.read === true)).toBe(true);
  });
});