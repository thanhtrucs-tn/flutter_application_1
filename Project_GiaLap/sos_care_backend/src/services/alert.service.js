const alertRepository = require('../repositories/alert.repository');
const relativeRepository = require('../repositories/relative.repository');
const socketService = require('./socket.service');
const AppError = require('../utils/appError.util');

/**
 * Caregiver-facing alerts. Device ingestion services call createFromDeviceEvent
 * to derive an alert from device telemetry, inheriting user_id from the paired
 * relative. Caregiver clients read/acknowledge alerts via REST.
 */
class AlertService {
  // Derive and persist a caregiver alert from a device telemetry event. Resolves
  // the owning relative (via the device's elderly_id business key, or its
  // relative_id) so the alert is user-scoped. Returns { alert, relative } so
  // callers can attach alertId/relativeId to their Socket.IO payloads.
  async createFromDeviceEvent({
    device,
    type,
    urgency,
    message,
    latitude,
    longitude,
    timestamp,
    sourceType,
    sourceId,
  }) {
    let relative = null;
    if (device && device.elderlyId) {
      relative = await relativeRepository.findByDeviceElderlyId(device.elderlyId);
    } else if (device && device.relativeId) {
      relative = await relativeRepository.findById(device.relativeId);
    }

    const alert = await alertRepository.create({
      relativeId: relative ? relative.id : null,
      userId: relative ? relative.userId : null,
      type,
      urgency,
      message,
      latitude: latitude ?? null,
      longitude: longitude ?? null,
      timestamp: new Date(timestamp),
      sourceType: sourceType || null,
      sourceId: sourceId ? String(sourceId) : null,
    });

    return { alert, relative };
  }

  // Scope a realtime event to the owning caregiver's room, or broadcast
  // globally when the alert has no owner (unpaired device, dev fallback).
  emitCaregiverEvent(event, payload, userId) {
    if (userId) {
      socketService.emitToRoom(`user:${userId}`, event, payload);
    } else {
      socketService.emit(event, payload);
    }
  }

  async listByUser(userId, pagination) {
    return alertRepository.findByUserId(userId, pagination);
  }

  async countUnreadByUser(userId) {
    return alertRepository.countUnreadByUser(userId);
  }

  async acknowledge(id, userId) {
    const alert = await alertRepository.findByIdForUser(id, userId);
    if (!alert) throw new AppError('Không tìm thấy cảnh báo', 404);
    await alert.update({ acknowledged: true });
    return alert;
  }

  async markRead(id, userId) {
    const alert = await alertRepository.findByIdForUser(id, userId);
    if (!alert) throw new AppError('Không tìm thấy cảnh báo', 404);
    await alert.update({ read: true });
    return alert;
  }

  async markAllRead(userId) {
    return alertRepository.markAllReadByUser(userId);
  }

  async createManual(userId, payload) {
    const { relativeId, type, urgency, message, locationName, latitude, longitude, timestamp } = payload;
    return alertRepository.create({
      relativeId: relativeId || null,
      userId,
      type: type || 'manual',
      urgency: urgency || 'warning',
      message,
      locationName: locationName || null,
      latitude: latitude ?? null,
      longitude: longitude ?? null,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      sourceType: 'manual',
    });
  }
}

module.exports = new AlertService();