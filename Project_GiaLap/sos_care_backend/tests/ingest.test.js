const request = require('supertest');
const { app, cleanDb, registerAndLogin, authHeader, trackSocket } = require('./helpers/test-utils');

// Seed a relative paired to a device elderly id. The ingest endpoints resolve
// the owning relative via this business key, then scope the realtime event to
// the caregiver's room.
async function seedRelative(token, deviceElderlyId) {
  const res = await request(app)
    .post('/api/relatives')
    .set(authHeader(token))
    .send({
      name: 'Ông Tư',
      deviceElderlyId,
      safeZoneRadius: 100,
      safeZoneLat: 10.762622,
      safeZoneLng: 106.660172,
    });
  return res.body.data;
}

describe('Device ingest -> caregiver alert + realtime event', () => {
  let socket;
  beforeEach(async () => {
    await cleanDb();
    socket = trackSocket();
  });
  afterEach(() => {
    socket.restore();
  });

  it('POST /api/sos creates an sos alert row and emits sos:alert with alertId+relativeId', async () => {
    const { token, userId } = await registerAndLogin(`sos_${Date.now()}@test.com`);
    const relative = await seedRelative(token, 'ELDERLY-001');

    const res = await request(app).post('/api/sos').send({
      deviceId: 'ELDERLY-001',
      elderlyId: 'ELDERLY-001',
      timestamp: new Date().toISOString(),
      latitude: 10.762622,
      longitude: 106.660172,
      type: 'SOS',
    });
    expect(res.statusCode).toBe(201);

    // Caregiver-facing alert (type=sos) was derived from the device SOS row.
    const list = await request(app).get('/api/alerts').set(authHeader(token));
    expect(list.statusCode).toBe(200);
    const sosAlert = list.body.data.find((a) => a.type === 'sos');
    expect(sosAlert).toBeTruthy();
    expect(sosAlert.relativeId).toBe(relative.id);

    // Realtime payload scoped to the owner's room, carrying numeric ids.
    expect(socket.emitToRoomSpy).toHaveBeenCalledWith(
      `user:${userId}`,
      'sos:alert',
      expect.objectContaining({
        alertId: expect.any(Number),
        relativeId: relative.id,
      }),
    );
  });

  it('POST /api/events FALL_DETECTED -> alert type=fall + event:fall emitted', async () => {
    const { token, userId } = await registerAndLogin(`fall_${Date.now()}@test.com`);
    const relative = await seedRelative(token, 'ELDERLY-FALL');

    const res = await request(app).post('/api/events').send({
      deviceId: 'ELDERLY-FALL',
      elderlyId: 'ELDERLY-FALL',
      timestamp: new Date().toISOString(),
      latitude: 10.762622,
      longitude: 106.660172,
      type: 'FALL_DETECTED',
    });
    expect(res.statusCode).toBe(201);

    const list = await request(app).get('/api/alerts').set(authHeader(token));
    const fall = list.body.data.find((a) => a.type === 'fall');
    expect(fall).toBeTruthy();
    expect(fall.relativeId).toBe(relative.id);

    expect(socket.emitToRoomSpy).toHaveBeenCalledWith(
      `user:${userId}`,
      'event:fall',
      expect.objectContaining({
        alertId: expect.any(Number),
        relativeId: relative.id,
      }),
    );
  });

  it('POST /api/events HEART_RATE_ALERT -> alert type=vital + event:heart_rate emitted', async () => {
    const { token, userId } = await registerAndLogin(`hr_${Date.now()}@test.com`);
    await seedRelative(token, 'ELDERLY-HR');

    const res = await request(app).post('/api/events').send({
      deviceId: 'ELDERLY-HR',
      elderlyId: 'ELDERLY-HR',
      timestamp: new Date().toISOString(),
      latitude: 10.762622,
      longitude: 106.660172,
      type: 'HEART_RATE_ALERT',
    });
    expect(res.statusCode).toBe(201);

    const list = await request(app).get('/api/alerts').set(authHeader(token));
    const vital = list.body.data.find((a) => a.type === 'vital');
    expect(vital).toBeTruthy();

    expect(socket.emitToRoomSpy).toHaveBeenCalledWith(
      `user:${userId}`,
      'event:heart_rate',
      expect.objectContaining({
        alertId: expect.any(Number),
        relativeId: expect.any(Number),
      }),
    );
  });
});