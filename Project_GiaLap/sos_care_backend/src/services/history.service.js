const { Op } = require('sequelize');
const { SosAlert, Event, Location, Device } = require('../models');

/**
 * Service that aggregates SOS alerts, events, and locations for the
 * history endpoint.
 *
 * When no `type` filter is supplied, results from all three tables are
 * merged and sorted by timestamp. Pagination is applied globally using
 * the provided limit/offset.
 */
class HistoryService {
  async list(query, userId) {
    const {
      deviceId,
      type,
      startDate,
      endDate,
      page = 1,
      limit = 20,
    } = query;

    const where = {};
    if (deviceId) where.deviceId = deviceId;
    if (startDate || endDate) {
      where.timestamp = {};
      if (startDate) where.timestamp[Op.gte] = new Date(startDate);
      if (endDate) where.timestamp[Op.lte] = new Date(endDate);
    }

    const parsedPage = Math.max(1, parseInt(page, 10));
    const parsedLimit = Math.max(1, parseInt(limit, 10));
    const offset = (parsedPage - 1) * parsedLimit;

    // Chỉ lấy dữ liệu của các thiết bị thuộc người dùng hiện tại — chặn
    // xem lịch sử (SOS/vị trí/sự kiện) của người khác qua deviceId.
    const include = [
      {
        model: Device,
        as: 'device',
        attributes: ['id', 'elderlyId', 'elderlyName'],
        where: { userId },
        required: true,
      },
    ];

    if (type) {
      const model = this._modelForType(type);
      const { rows, count } = await model.findAndCountAll({
        where,
        include,
        order: [['timestamp', 'DESC']],
        limit: parsedLimit,
        offset,
      });

      return {
        data: rows.map((r) => ({ ...r.toJSON(), kind: type })),
        meta: {
          page: parsedPage,
          limit: parsedLimit,
          total: count,
        },
      };
    }

    // No type filter: fetch relevant slices from all three tables and merge.
    const [alerts, events, locations] = await Promise.all([
      SosAlert.findAll({ where, include, order: [['timestamp', 'DESC']], limit: parsedLimit, offset }),
      Event.findAll({ where, include, order: [['timestamp', 'DESC']], limit: parsedLimit, offset }),
      Location.findAll({ where, include, order: [['timestamp', 'DESC']], limit: parsedLimit, offset }),
    ]);

    const [alertCount, eventCount, locationCount] = await Promise.all([
      SosAlert.count({ where, include }),
      Event.count({ where, include }),
      Location.count({ where, include }),
    ]);

    const merged = [
      ...alerts.map((a) => ({ ...a.toJSON(), kind: 'sos' })),
      ...events.map((e) => ({ ...e.toJSON(), kind: 'event' })),
      ...locations.map((l) => ({ ...l.toJSON(), kind: 'location' })),
    ].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    return {
      data: merged.slice(0, parsedLimit),
      meta: {
        page: parsedPage,
        limit: parsedLimit,
        total: alertCount + eventCount + locationCount,
      },
    };
  }

  _modelForType(type) {
    switch (type) {
      case 'sos': return SosAlert;
      case 'event': return Event;
      case 'location': return Location;
      default: throw new Error(`Unknown history type: ${type}`);
    }
  }
}

module.exports = new HistoryService();
