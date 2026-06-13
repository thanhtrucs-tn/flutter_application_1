/**
 * SOS Care Backend API
 * --------------------
 * Mục đích: Cho phép Flutter Web (Chrome) đăng ký/đăng nhập qua MySQL.
 * Vì trình duyệt không thể kết nối TCP trực tiếp tới MySQL, cần có
 * backend Node.js trung gian xử lý HTTP request từ Chrome.
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
      updateUser: 'PUT /api/users/:username',
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

// ===== HELPER =====
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  // RFC 5322 simplified regex cho định dạng email cơ bản
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

// ===== ĐĂNG KÝ TÀI KHOẢN =====
app.post('/api/register', async (req, res) => {
  try {
    const { username, password, email } = req.body;

    // Validate input
    if (!username || !password || !email) {
      return res.status(400).json({
        success: false,
        error: 'Vui lòng nhập đầy đủ username, email và password.',
      });
    }

    const trimmedEmail = email.trim();

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

    if (trimmedEmail.length > 48) {
      return res.status(400).json({
        success: false,
        error: 'Email tối đa 48 ký tự.',
      });
    }

    if (!isValidEmail(trimmedEmail)) {
      return res.status(400).json({
        success: false,
        error: 'Email không đúng định dạng.',
      });
    }

    // Kiểm tra trùng username
    const [existingUser] = await pool.query(
      'SELECT id FROM users WHERE username = ?',
      [username]
    );
    if (existingUser.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'Tên tài khoản này đã tồn tại.',
      });
    }

    // Kiểm tra trùng email
    const [existingEmail] = await pool.query(
      'SELECT id FROM users WHERE email = ?',
      [trimmedEmail]
    );
    if (existingEmail.length > 0) {
      return res.status(409).json({
        success: false,
        error: 'Email này đã được sử dụng.',
      });
    }

    // Lưu vào MySQL (chưa hash password để tương thích với code Flutter cũ)
    const [result] = await pool.query(
      'INSERT INTO users (username, password, email) VALUES (?, ?, ?)',
      [username, password, trimmedEmail]
    );

    console.log(`✅ Đăng ký mới: username="${username}", email="${trimmedEmail}", id=${result.insertId}`);

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
        error: 'Thiếu username/email hoặc password.',
      });
    }

    // Hỗ trợ đăng nhập bằng username hoặc email
    const isEmail = isValidEmail(username);
    const query = isEmail
      ? 'SELECT id, username, name, email, phone FROM users WHERE email = ? AND password = ?'
      : 'SELECT id, username, name, email, phone FROM users WHERE username = ? AND password = ?';

    const [rows] = await pool.query(query, [username, password]);

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Sai tài khoản/email hoặc mật khẩu.',
      });
    }

    res.json({
      success: true,
      message: 'Đăng nhập thành công!',
      user: {
        id: rows[0].id,
        username: rows[0].username,
        name: rows[0].name || rows[0].username,
        email: rows[0].email || '',
        phone: rows[0].phone || '',
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

// ===== CẬP NHẬT THÔNG TIN CÁ NHÂN =====
app.put('/api/users/:username', async (req, res) => {
  try {
    const { username } = req.params;
    const { name, email, phone } = req.body;

    if (!username) {
      return res.status(400).json({
        success: false,
        error: 'Thiếu username.',
      });
    }

    const [result] = await pool.query(
      'UPDATE users SET name = ?, email = ?, phone = ? WHERE username = ?',
      [name || username, email || '', phone || '', username]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        error: 'Không tìm thấy tài khoản.',
      });
    }

    res.json({
      success: true,
      message: 'Cập nhật thông tin thành công!',
    });
  } catch (err) {
    console.error('❌ Lỗi PUT /api/users/:username:', err);
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
      'SELECT id, username, name, email, phone, created_at FROM users ORDER BY id ASC'
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
    console.log(`   PUT  http://localhost:${PORT}/api/users/:username`);
    console.log(`   GET  http://localhost:${PORT}/api/users`);
    console.log('');
  });
});
