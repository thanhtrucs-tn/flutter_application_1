// Runs before any test file is loaded (and before src/app -> env.config is
// first required). Disables the Winston daily-rotate-file transport during
// tests so no file handle keeps Jest from exiting cleanly, and avoids
// polluting logs/ with test output. Console logging still works.
process.env.LOG_TO_FILE = 'false';