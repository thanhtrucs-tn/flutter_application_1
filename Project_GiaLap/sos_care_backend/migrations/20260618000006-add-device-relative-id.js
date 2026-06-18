module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('devices', 'relative_id', {
      type: Sequelize.INTEGER,
      allowNull: true,
      references: {
        model: 'relatives',
        key: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('devices', 'relative_id');
  },
};