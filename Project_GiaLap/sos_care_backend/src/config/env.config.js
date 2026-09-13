require('dotenv').config();

/**
 * Centralized environment configuration.
 *
 * Reads values from process.env and provides sensible defaults so the
 * rest of the application does not scatter env access.
 */
const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '8081', 10),
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    // Môi trường test dùng DB riêng (<DB_NAME>_test) để khớp với sequelize-cli
    // test config — tránh ghi đè dữ liệu dev/prod khi chạy jest.
    name: process.env.NODE_ENV === 'test'
      ? `${process.env.DB_NAME || 'sos_care_db'}_test`
      : (process.env.DB_NAME || 'sos_care_db'),
    user: process.env.DB_USER || 'root',
    pass: process.env.DB_PASS || '',
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  logLevel: process.env.LOG_LEVEL || 'info',
  logToFile: process.env.LOG_TO_FILE !== 'false',
  dbSync: process.env.DB_SYNC === 'true',
  deviceAuthMode: process.env.DEVICE_AUTH_MODE || 'none',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  deviceToken: process.env.DEVICE_TOKEN,
};

// Kiểm tra biến môi trường bắt buộc khi khởi động. Chỉ in TÊN biến thiếu,
// không bao giờ in giá trị secret.
const requiredVars = ['JWT_SECRET'];
if (env.deviceAuthMode === 'token') {
  requiredVars.push('DEVICE_TOKEN');
}

const missingVars = requiredVars.filter((name) => !process.env[name]);
if (missingVars.length > 0) {
  throw new Error(
    `Thiếu biến môi trường bắt buộc: ${missingVars.join(', ')}. Vui lòng khai báo trong file .env.`,
  );
}

if (env.nodeEnv === 'production' && env.deviceAuthMode === 'none') {
  // Cảnh báo không chặn server: một số demo chạy production cục bộ.
  console.warn('[env] CẢNH BÁO: DEVICE_AUTH_MODE=none trong production — các API nhận dữ liệu thiết bị sẽ không được xác thực.');
}

module.exports = env;
