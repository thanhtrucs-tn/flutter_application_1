module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('device_statuses', 'spo2_percent', {
      type: Sequelize.TINYINT.UNSIGNED,
      allowNull: true,
    });

    await queryInterface.changeColumn('events', 'type', {
      type: Sequelize.ENUM('FALL_DETECTED', 'HEART_RATE_ALERT', 'SPO2_ALERT'),
      allowNull: false,
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('device_statuses', 'spo2_percent');

    await queryInterface.changeColumn('events', 'type', {
      type: Sequelize.ENUM('FALL_DETECTED', 'HEART_RATE_ALERT'),
      allowNull: false,
    });
  },
};