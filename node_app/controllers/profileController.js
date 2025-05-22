const express = require('express');
const pool = require('../database');
const router = express.Router();

// Fetch user profile
router.get('/users/:id', async (req, res) => {
  const userId = req.params.id;

  try {
    const [rows] = await pool.query(
      'SELECT id, first_name, last_name, email FROM users WHERE id = ?',
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, user: rows[0] });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ success: false, message: 'An error occurred' });
  }
});

// Update user profile
router.put('/users/:id', async (req, res) => {
  const userId = req.params.id;
  console.log('Received body:', req.body); // تسجيل البيانات الواردة
  const { first_name, last_name, bio, profile_picture } = req.body;

  const updates = {};
  if (first_name) updates.first_name = first_name;
  if (last_name) updates.last_name = last_name;
  if (bio) updates.bio = bio;
  if (profile_picture) updates.profile_picture = profile_picture;

  console.log('Updates to apply:', updates); // تسجيل البيانات بعد التصفية

  try {
    const [result] = await pool.query('UPDATE users SET ? WHERE id = ?', [updates, userId]);
    console.log('SQL Result:', result); // تسجيل نتيجة الاستعلام

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, message: 'User updated successfully' });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ success: false, message: 'An error occurred' });
  }
});

module.exports = router;

