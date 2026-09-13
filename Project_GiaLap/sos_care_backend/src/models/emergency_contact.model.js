const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * Emergency contact attached to a relative (name + phone + relationship).
 * Deleted with the owning relative (cascade).
 */
const EmergencyContact = sequelize.define(
  'EmergencyContact',
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    relativeId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      field: 'relative_id',
      references: {
        model: 'relatives',
        key: 'id',
      },
    },
    name: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },
    phone: {
      type: DataTypes.STRING(20),
      allowNull: false,
    },
    relationship: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },
  },
  {
    tableName: 'emergency_contacts',
    timestamps: true,
    paranoid: true,
    underscored: true,
    indexes: [{ fields: ['relative_id'] }],
  },
);

module.exports = EmergencyContact;