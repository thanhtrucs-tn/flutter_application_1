const { Alert } = require('../models');
const alertService = require('./alert.service');

const EARTH_RADIUS_METERS = 6371000;

const toRad = (deg) => (Number(deg) * Math.PI) / 180;

/**
 * Haversine great-circle distance in meters between two lat/lng points.
 */
function haversineDistance(lat1, lng1, lat2, lng2) {
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_METERS * c;
}

/**
 * Server-side geofence breach detection. When the device is outside the
 * relative's safe-zone radius AND no active (unacknowledged) geofence alert
 * exists for that relative, create a geofence alert and return it so the
 * caller can emit `geofence:alert`. Returns null when inside the zone or when
 * an active geofence alert already exists (avoid duplicate spam).
 */
class GeofenceService {
  async checkBreach({ relative, latitude, longitude, timestamp }) {
    if (!relative || relative.safeZoneLat == null || relative.safeZoneLng == null) {
      return null;
    }
    const radius = Number(relative.safeZoneRadius ?? 500);
    const distance = haversineDistance(
      Number(relative.safeZoneLat),
      Number(relative.safeZoneLng),
      Number(latitude),
      Number(longitude),
    );
    if (distance <= radius) return null;

    const active = await Alert.findOne({
      where: { relativeId: relative.id, type: 'geofence', acknowledged: false },
      order: [['timestamp', 'DESC']],
    });
    if (active) return null;

    const { alert } = await alertService.createFromDeviceEvent({
      device: { elderlyId: relative.deviceElderlyId, relativeId: relative.id },
      type: 'geofence',
      urgency: 'critical',
      message: `${relative.name} đã ra khỏi vùng an toàn (cách tâm ~${Math.round(distance)}m)`,
      latitude,
      longitude,
      timestamp,
      sourceType: 'geofence',
    });
    return alert;
  }
}

module.exports = new GeofenceService();