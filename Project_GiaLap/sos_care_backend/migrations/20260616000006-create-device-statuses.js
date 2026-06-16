module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('device_statuses', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      device_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'devices',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      battery_percent: {
        type: Sequelize.TINYINT.UNSIGNED,
        allowNull: false,
      },
      heart_rate_bpm: {
        type: Sequelize.SMALLINT.UNSIGNED,
        allowNull: true,
      },
      is_online: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true,
      },
      timestamp: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'),
      },
      deleted_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
    });

    await queryInterface.addIndex('device_statuses', ['device_id']);
    await queryInterface.addIndex('device_statuses', ['timestamp']);
  },

  async down(queryInterface) {
    await queryInterface.dropTable('device_statuses');
  },
};
