module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('devices', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      elderly_id: {
        type: Sequelize.STRING(100),
        allowNull: false,
        unique: true,
      },
      elderly_name: {
        type: Sequelize.STRING(255),
        allowNull: true,
      },
      serial_number: {
        type: Sequelize.STRING(100),
        allowNull: true,
        unique: true,
      },
      status: {
        type: Sequelize.ENUM('active', 'inactive', 'lost'),
        allowNull: false,
        defaultValue: 'active',
      },
      last_seen_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      user_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
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
  },

  async down(queryInterface) {
    await queryInterface.dropTable('devices');
  },
};
