const pool = require('../database');
const path = require('path');

// ✅ جلب معلومات المستخدم
const getUserProfile = async (req, res) => {
  const userId = req.params.id;

  try {
    const [rows] = await pool.query(
      'SELECT id, first_name, last_name, email, bio, profile_picture FROM users WHERE id = ?',
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User Not Found!' });
    }

    const user = rows[0];
    res.json({ success: true, user });
  } catch (error) {
    console.error('خطأ أثناء جلب بيانات المستخدم:', error);
    res.status(500).json({ success: false, message: 'حدث خطأ أثناء جلب البيانات' });
  }
};

// ✅ تعديل البروفايل مع رفع الصورة
const updateUserProfile = async (req, res) => {
  const userId = req.params.id;
  const { first_name, last_name, bio } = req.body;

  if (!userId || isNaN(userId)) {
    return res.status(400).json({ success: false, message: 'Invalid user ID!' });
  }

  try {
    // في حال وجود صورة مرفوعة
    const profile_picture = req.file ? `/assets/profile/${req.file.filename}` : null;

    const [result] = await pool.query(
      `UPDATE users 
       SET first_name = ?, 
           last_name = ?, 
           bio = ?, 
           profile_picture = ?
       WHERE id = ?`,
      [first_name || null, last_name || null, bio || null, profile_picture, userId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'User Not Found!' });
    }

    res.json({ success: true, message: 'User updated successfully!' });
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).json({ success: false, message: 'An error occurred while updating user data.' });
  }
};

module.exports = {
  getUserProfile,
  updateUserProfile,
};
