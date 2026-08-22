const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { EmergencyContact, Device, Location, DeviceStatus } = require('../models');
const relativeRepository = require('../repositories/relative.repository');
const contactRepository = require('../repositories/emergencyContact.repository');
const { AVATAR_DIR, MIME_EXT, IMAGE_EXTENSIONS, normalizeMime } = require('../middleware/upload.middleware');
const logger = require('../utils/logger.util');
const AppError = require('../utils/appError.util');

/**
 * Caregiver-scoped CRUD for relatives. Returns fused DTOs (profile + contacts
 * + latest device location/status) so the Flutter client can build one
 * ElderlyModel per relative. Vitals/status are never stored on the relative.
 */
class RelativeService {
  async _latestVitals(deviceElderlyId) {
    if (!deviceElderlyId) return { latestLocation: null, latestStatus: null };
    const device = await Device.findOne({ where: { elderlyId: deviceElderlyId } });
    if (!device) return { latestLocation: null, latestStatus: null };
    const [latestLocation, latestStatus] = await Promise.all([
      Location.findOne({ where: { deviceId: device.id }, order: [['timestamp', 'DESC']] }),
      DeviceStatus.findOne({ where: { deviceId: device.id }, order: [['timestamp', 'DESC']] }),
    ]);
    return { latestLocation, latestStatus };
  }

  _toDto(relative, latestLocation, latestStatus) {
    return {
      id: relative.id,
      userId: relative.userId,
      name: relative.name,
      avatar: relative.avatar,
      age: relative.age,
      address: relative.address,
      wearableDevice: relative.wearableDevice,
      deviceElderlyId: relative.deviceElderlyId,
      safeZoneRadius: relative.safeZoneRadius,
      safeZoneLat: relative.safeZoneLat,
      safeZoneLng: relative.safeZoneLng,
      contacts: (relative.contacts || []).map((c) => ({
        id: c.id, name: c.name, phone: c.phone, relationship: c.relationship,
      })),
      latestLocation: latestLocation
        ? { latitude: latestLocation.latitude, longitude: latestLocation.longitude, timestamp: latestLocation.timestamp }
        : null,
      latestStatus: latestStatus
        ? {
            batteryPercent: latestStatus.batteryPercent,
            heartRateBpm: latestStatus.heartRateBpm,
            spo2Percent: latestStatus.spo2Percent,
            isOnline: latestStatus.isOnline,
            timestamp: latestStatus.timestamp,
          }
        : null,
    };
  }

  // Split the payload into a profile map (nullable strings normalized) and the
  // optional contacts array used for bulk-replace.
  _cleanProfile({ contacts, ...profile }) {
    const clean = { ...profile };
    if ('deviceElderlyId' in clean) clean.deviceElderlyId = clean.deviceElderlyId || null;
    if ('avatar' in clean) clean.avatar = clean.avatar || null;
    return { contacts, clean };
  }

  async listByUser(userId) {
    const relatives = await relativeRepository.findByUserId(userId);
    return Promise.all(
      relatives.map(async (r) => {
        const v = await this._latestVitals(r.deviceElderlyId);
        return this._toDto(r, v.latestLocation, v.latestStatus);
      }),
    );
  }

  async getById(id, userId) {
    const relative = await relativeRepository.findByIdForUser(id, userId);
    if (!relative) throw new AppError('Không tìm thấy người thân', 404);
    const v = await this._latestVitals(relative.deviceElderlyId);
    return this._toDto(relative, v.latestLocation, v.latestStatus);
  }

  async create(userId, payload) {
    const { contacts, clean } = this._cleanProfile(payload);
    const relative = await relativeRepository.createForUser(userId, clean);
    if (contacts && contacts.length) {
      await contactRepository.bulkReplaceForRelative(relative.id, contacts);
    }
    return this.getById(relative.id, userId);
  }

  async update(id, userId, payload) {
    const relative = await relativeRepository.findByIdForUser(id, userId);
    if (!relative) throw new AppError('Không tìm thấy người thân', 404);
    const { contacts, clean } = this._cleanProfile(payload);
    await relative.update(clean);
    if (contacts !== undefined) {
      await contactRepository.bulkReplaceForRelative(relative.id, contacts || []);
    }
    return this.getById(id, userId);
  }

  async remove(id, userId) {
    const relative = await relativeRepository.findByIdForUser(id, userId);
    if (!relative) throw new AppError('Không tìm thấy người thân', 404);
    await EmergencyContact.destroy({ where: { relativeId: relative.id } });
    this._deleteAvatarFileIfUploaded(relative.avatar);
    await relative.destroy();
    return true;
  }

  // Best-effort delete an uploaded avatar file. Only files inside the avatar
  // upload folder are removed (never external/URL avatars).
  _deleteAvatarFileIfUploaded(avatarUrl) {
    if (!avatarUrl || !avatarUrl.startsWith('/uploads/avatars/')) return;
    const filePath = path.join(AVATAR_DIR, path.basename(avatarUrl));
    fs.unlink(filePath, () => {});
  }

  async updateAvatarPhoto(id, userId, file) {
    if (!file || !file.buffer || file.buffer.length === 0) {
      throw new AppError('Vui lòng chọn một tệp ảnh', 400);
    }
    const relative = await relativeRepository.findByIdForUser(id, userId);
    if (!relative) throw new AppError('Không tìm thấy người thân', 404);

    const mime = normalizeMime(file.mimetype);
    const originalExt = path.extname(file.originalname || '').toLowerCase();
    const ext = MIME_EXT[mime] ||
      (IMAGE_EXTENSIONS.has(originalExt) ? originalExt : '.jpg');
    const filename = `${relative.userId}_${relative.id}_${Date.now()}${ext}`;
    const absolutePath = path.join(AVATAR_DIR, filename);
    fs.writeFileSync(absolutePath, file.buffer);

    this._deleteAvatarFileIfUploaded(relative.avatar);
    await relative.update({ avatar: `/uploads/avatars/${filename}` });
    logger.info(`Đã cập nhật ảnh đại diện cho người thân #${relative.id}`);
    return this.getById(id, userId);
  }

  async listContacts(id, userId) {
    const relative = await relativeRepository.findByIdForUser(id, userId);
    if (!relative) throw new AppError('Không tìm thấy người thân', 404);
    return (relative.contacts || []).map((c) => ({
      id: c.id, name: c.name, phone: c.phone, relationship: c.relationship,
    }));
  }

  async addContact(id, userId, payload) {
    const relative = await relativeRepository.findByIdForUser(id, userId);
    if (!relative) throw new AppError('Không tìm thấy người thân', 404);
    return contactRepository.createForRelative(relative.id, payload);
  }

  async removeContact(id, contactId, userId) {
    const relative = await relativeRepository.findByIdForUser(id, userId);
    if (!relative) throw new AppError('Không tìm thấy người thân', 404);
    const contact = await contactRepository.findById(contactId);
    if (!contact || contact.relativeId !== relative.id) {
      throw new AppError('Không tìm thấy liên hệ', 404);
    }
    await contact.destroy();
    return true;
  }
}

module.exports = new RelativeService();