const request = require('supertest');
const { app, cleanDb, registerAndLogin, authHeader, trackSocket } = require('./helpers/test-utils');

// Safe-zone center with a small 100m radius.
const CENTER = { lat: 10.762622, lng: 106.660172 };

async function seedRelative(token, deviceElderlyId) {
  const res = await request(app)
    .post('/api/relatives')
    .set(authHeader(token))
    .send({
      name: 'Bà Mai',
      deviceElderlyId,
      safeZoneRadius: 100,
      safeZoneLat: CENTER.lat,
      safeZoneLng: CENTER.lng,
    });
  return res.body.data;
}

function postLocation(elderlyId, lat, lng) {
  return request(app).post('/api/location').send({
    deviceId: elderlyId,
    elderlyId,
    timestamp: new Date().toISOString(),
    latitude: lat,
    longitude: lng,
  });
}

describe('Location ingest does not raise leave-home (geofence) alerts', () => {
  let socket;
  beforeEach(async () => {
    await cleanDb();
    socket = trackSocket();
  });
  afterEach(() => {
    socket.restore();
  });

  it('location OUTSIDE home no longer creates a geofence alert (leave-home alerts removed)', async () => {
    const { token } = await registerAndLogin(`out_${Date.now()}@test.com`);
    await seedRelative(token, 'ELDERLY-GEO-OUT');

    // ~1km north of home.
    const res = await postLocation('ELDERLY-GEO-OUT', 10.771622, 106.660172);
    expect(res.statusCode).toBe(201);

    const list = await request(app).get('/api/alerts').set(authHeader(token));
    expect(list.body.data.find((a) => a.type === 'geofence')).toBeUndefined();

    const geofenceCalls = socket.emitToRoomSpy.mock.calls.filter((c) => c[1] === 'geofence:alert');
    expect(geofenceCalls).toHaveLength(0);
    // Realtime location still reaches the caregiver.
    const locationCalls = socket.emitToRoomSpy.mock.calls.filter((c) => c[1] === 'device:location');
    expect(locationCalls.length).toBeGreaterThan(0);
  });

  it('location INSIDE the safe zone does not create a geofence alert', async () => {
    const { token } = await registerAndLogin(`in_${Date.now()}@test.com`);
    await seedRelative(token, 'ELDERLY-GEO-IN');

    const res = await postLocation('ELDERLY-GEO-IN', CENTER.lat, CENTER.lng);
    expect(res.statusCode).toBe(201);

    const list = await request(app).get('/api/alerts').set(authHeader(token));
    expect(list.body.data.find((a) => a.type === 'geofence')).toBeUndefined();

    // device:location is still emitted, but geofence:alert must not be.
    const geofenceCalls = socket.emitToRoomSpy.mock.calls.filter((c) => c[1] === 'geofence:alert');
    expect(geofenceCalls).toHaveLength(0);
  });
});