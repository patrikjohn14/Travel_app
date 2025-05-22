// controllers/authController.js
const pool = require('../database');
const bcrypt = require('bcryptjs');

exports.register = async (req, res) => {
  const { email, password, first_name, last_name } = req.body;

  try {
    // التحقق من البريد الإلكتروني
    const [existingUser] = await pool.query(
      'SELECT * FROM users WHERE email = ?', 
      [email]
    );

    if (existingUser.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Email already exists'
      });
    }

 
    const hashedPassword = await bcrypt.hash(password, 10);

   
    const [result] = await pool.query(
      'INSERT INTO users (email, password, first_name, last_name, created_at) VALUES (?, ?, ?, ?, ?)',
      [email, hashedPassword, first_name, last_name, new Date()]
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      userId: result.insertId
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};
