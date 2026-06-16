const express = require('express');
const sosRoutes = require('./sos.routes');
const eventRoutes = require('./event.routes');
const locationRoutes = require('./location.routes');
const deviceStatusRoutes = require('./deviceStatus.routes');
const batteryRoutes = require('./battery.routes');
const authRoutes = require('./auth.routes');
const deviceRoutes = require('./device.routes');
const historyRoutes = require('./history.routes');
const healthRoutes = require('./health.routes');

const router = express.Router();

router.use('/health', healthRoutes);
router.use('/api/auth', authRoutes);
router.use('/api/sos', sosRoutes);
router.use('/api/events', eventRoutes);
router.use('/api/location', locationRoutes);
router.use('/api/device/status', deviceStatusRoutes);
router.use('/api/device/battery', batteryRoutes); // Flutter compatibility alias
router.use('/api/device', deviceRoutes);
router.use('/api/history', historyRoutes);

module.exports = router;
