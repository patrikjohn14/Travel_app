const pool = require('../database');
const bcrypt = require('bcryptjs');
const { createSession } = require('./sessionController');

const login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ 
      success: false,
      message: 'Email and password are required'
    });
  }

  try {
    const [userRows] = await pool.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (userRows.length === 0) {
      return res.status(404).json({ 
        success: false,
        message: 'Email not registered' 
      });
    }

    const user = userRows[0];
    const isPasswordValid = await bcrypt.compare(password, user.password);
    
    if (!isPasswordValid) {
      return res.status(401).json({ 
        success: false,
        message: 'Incorrect password' 
      });
    }

    // إنشاء جلسة جديدة
    const sessionId = await createSession(user.id, req);

    res.status(200).json({
      success: true,
      user: {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email
      },
      session_id: sessionId,
      expires_in: 1800 // 30 دقيقة بالثواني
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      success: false,
      message: 'An error occurred during login' 
    });
  }
};

module.exports = {
  login
};
