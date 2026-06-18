module.exports = {
  testEnvironment: 'node',
  // Integration tests share a single physical MySQL database (project_app_test)
  // and each test truncates all business tables in beforeEach. Running files
  // in parallel workers would let one file's truncation wipe another file's
  // in-flight rows, so execution must be serial.
  maxWorkers: 1,
  // The Sequelize connection pool stays open after tests (closing it from
  // globalTeardown can't reach the worker's instance), so force Jest to exit
  // once all tests complete. Standard practice for DB-backed integration tests.
  forceExit: true,
  testMatch: ['**/tests/**/*.test.js'],
  coveragePathIgnorePatterns: ['/node_modules/', '/tests/'],
  setupFiles: ['<rootDir>/tests/helpers/setup.js'],
};