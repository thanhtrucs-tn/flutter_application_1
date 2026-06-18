module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('relatives', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'users',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      name: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      avatar: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      age: {
        type: Sequelize.INTEGER,
        allowNull: true,
      },
      address: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      wearable_device: {
        type: Sequelize.STRING(100),
        allowNull: true,
      },
      device_elderly_id: {
        type: Sequelize.STRING(100),
        allowNull: true,
        unique: true,
      },
      safe_zone_radius: {
        type: Sequelize.DECIMAL(8, 2),
        allowNull: true,
        defaultValue: 500,
      },
      safe_zone_lat: {
        type: Sequelize.DECIMAL(10, 8),
        allowNull: true,
      },
      safe_zone_lng: {
        type: Sequelize.DECIMAL(11, 8),
        allowNull: true,
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

    await queryInterface.addIndex('relatives', ['user_id']);
  },

  async down(queryInterface) {
    await queryInterface.dropTable('relatives');
  },
};