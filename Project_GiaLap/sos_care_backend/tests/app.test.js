const request = require('supertest');
const createApp = require('../src/app');

const app = createApp();

describe('Health endpoint', () => {
  it('GET /health returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('ok');
  });
});

describe('Validation middleware', () => {
  it('POST /api/sos returns 400 for invalid body', async () => {
    const res = await request(app).post('/api/sos').send({ deviceId: 'x' });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.errors).toBeDefined();
  });

  it('POST /api/events returns 400 for missing type', async () => {
    const res = await request(app).post('/api/events').send({
      deviceId: 'SOS-DEVICE-001',
      timestamp: new Date().toISOString(),
      latitude: 10.762622,
      longitude: 106.660172,
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });
});

describe('Auth middleware', () => {
  it('GET /api/history returns 401 without token', async () => {
    const res = await request(app).get('/api/history');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('GET /api/device/:id returns 401 without token', async () => {
    const res = await request(app).get('/api/device/abc');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});

describe('Protected routes require JWT', () => {
  it('GET /api/relatives returns 401 without token', async () => {
    const res = await request(app).get('/api/relatives');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('GET /api/alerts returns 401 without token', async () => {
    const res = await request(app).get('/api/alerts');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('POST /api/relatives returns 401 without token', async () => {
    const res = await request(app).post('/api/relatives').send({ name: 'x' });
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });
});
