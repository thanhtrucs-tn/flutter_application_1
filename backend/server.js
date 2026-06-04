/**
 * SOS Care Backend API
 * --------------------
 * Mục đích: Cho phép Flutter Web (Chrome) đăng ký/đăng nhập qua MySQL.
 * Vì trình duyệt không thể kết nối TCP trực tiếp tới MySQL, cần có
 * backend trung gian xử lý HTTP request từ Chrome.
 *
 * Cài đặt:
 *   cd backend
 *   npm install
 *
 * Chạy:
 *   npm start         (chạy production)
 *   npm run dev       (chạy với auto-reload khi sửa code)
 *
 * Test nhanh bằng trình duyệt:
 *   http://localhost:3000/
 */

const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();
const PORT = process.env.PORT || 3000;

// ===== MIDDLEWARE =====
app.use(cors());                    // Cho phép Chrome gọi từ domain khác
app.use(express.json());            // Parse JSON body
app.use(express.urlencoded({ extended: true }));

// ===== CẤU HÌNH DATABASE =====
const dbConfig = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'test_123',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
};

// Pool kết nối MySQL - tái sử dụng connection để tăng hiệu năng
let pool;

async function initPool() {
  try {
    pool = mysql.createPool(dbConfig);
    // Test kết nối ngay khi khởi động
    const conn = await pool.getConnection();
    console.log('✅ Kết nối MySQL thành công tới', dbConfig.host + ':' + dbConfig.port);
    conn.release();
  } catch (err) {
    console.error('❌ KHÔNG THỂ KẾT NỐI MYSQL:', err.message);
    console.error('   Hãy kiểm tra:');
    console.error('   1. MySQL server đã chạy chưa?');
    console.error('   2. Database "test_123" đã tạo chưa? (xem db_script.sql)');
    console.error('   3. User/password đúng chưa?');
    process.exit(1);
  }
}

// ===== ROOT ENDPOINT =====
app.get('/', (req, res) => {
  res.json({
    name: 'SOS Care Backend API',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      health: 'GET /api/health',
      register: 'POST /api/register',
      login: 'POST /api/login',
      listUsers: 'GET /api/users',
    },
  });
});

// ===== HEALTH CHECK =====
app.get('/api/health', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT 1 AS ok');
    res.json({
      status: 'ok',
      database: 'connected',
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(500).json({
      status: 'error',
      database: 'disconnected',
      error: err.message,
    });
  }
});

// ===== ĐĂNG KÝ TÀI KHOẢN =====
app.post('/api/register', async (req, res) => {
  try {
    const { username, password } = req.body;

    // Validate input
    if (!username || !password) {
      return res.status(400).json({
        success: false,
        error: 'Thiếu username hoặc password.',
      });
    }

    if (username.length > 32) {
      return res.status(400).json({
        success: false,
        error: 'Username tối đa 32 ký tự.',
      });
    }

    if (password.length > 64) {
      return res.status(400).json({
        success: false,
        error: 'Password tối đa 64 ký tự.',
      });
    }

    // Kiểm tra trùng username
    const [existing] = await pool.query(
      'SELECT id FROM users WHERE username = ?',
      [username]
    );
    if (existing.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'Tài khoản này đã tồn tại.',
      });
    }

    // Lưu vào MySQL (chưa hash password để tương thích với code Flutter cũ)
    const [result] = await pool.query(
      'INSERT INTO users (username, password) VALUES (?, ?)',
      [username, password]
    );

    console.log(`✅ Đăng ký mới: username="${username}", id=${result.insertId}`);

    res.json({
      success: true,
      message: 'Đăng ký tài khoản thành công!',
      userId: result.insertId,
    });
  } catch (err) {
    console.error('❌ Lỗi /api/register:', err);
    res.status(500).json({
      success: false,
      error: 'Lỗi server: ' + err.message,
    });
  }
});

// ===== ĐĂNG NHẬP =====
app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        error: 'Thiếu username hoặc password.',
      });
    }

    const [rows] = await pool.query(
      'SELECT id, username FROM users WHERE username = ? AND password = ?',
      [username, password]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Sai tài khoản hoặc mật khẩu.',
      });
    }

    res.json({
      success: true,
      message: 'Đăng nhập thành công!',
      user: {
        id: rows[0].id,
        username: rows[0].username,
      },
    });
  } catch (err) {
    console.error('❌ Lỗi /api/login:', err);
    res.status(500).json({
      success: false,
      error: 'Lỗi server: ' + err.message,
    });
  }
});

// ===== LIỆT KÊ USERS (DEBUG) =====
app.get('/api/users', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, username, created_at FROM users ORDER BY id ASC'
    );
    res.json({
      success: true,
      count: rows.length,
      users: rows,
    });
  } catch (err) {
    console.error('❌ Lỗi /api/users:', err);
    res.status(500).json({
      success: false,
      error: 'Lỗi server: ' + err.message,
    });
  }
});

// ===== KHỞI ĐỘNG SERVER =====
initPool().then(() => {
  app.listen(PORT, '0.0.0.0', () => {
    console.log('');
    console.log('🚀 ===================================');
    console.log(`🚀 SOS Care Backend đang chạy`);
    console.log(`🚀 http://localhost:${PORT}`);
    console.log('🚀 ===================================');
    console.log('');
    console.log('Các endpoint:');
    console.log(`   GET  http://localhost:${PORT}/api/health`);
    console.log(`   POST http://localhost:${PORT}/api/register`);
    console.log(`   POST http://localhost:${PORT}/api/login`);
    console.log(`   GET  http://localhost:${PORT}/api/users`);
    console.log('');
  });
});
