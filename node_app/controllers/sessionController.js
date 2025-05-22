const pool = require('../database');
const crypto = require('crypto');

module.exports = {
  // إنشاء جلسة جديدة
  createSession: async (userId, req) => {
    const sessionId = crypto.randomBytes(16).toString('hex');
    const ipAddress = req.ip || req.headers['x-forwarded-for'] || req.connection.remoteAddress;
    const userAgent = req.headers['user-agent'];

    try {
      await pool.query(
        `INSERT INTO sessions 
        (id, user_id, ip_address, user_agent, last_activity) 
        VALUES (?, ?, ?, ?, ?)`,
        [sessionId, userId, ipAddress, userAgent, new Date()]
      );
      return sessionId;
    } catch (error) {
      console.error('Error creating session:', error);
      throw new Error('Failed to create session');
    }
  },

  // التحقق من صحة الجلسة
  verifySession: async (sessionId) => {
    try {
      const [sessions] = await pool.query(
        `SELECT * FROM sessions 
         WHERE id = ? 
         AND last_activity > DATE_SUB(NOW(), INTERVAL 30 MINUTE)`,
        [sessionId]
      );

      if (sessions.length === 0) return false;

      // تحديث وقت النشاط الأخير
      await pool.query(
        'UPDATE sessions SET last_activity = CURRENT_TIMESTAMP WHERE id = ?',
        [sessionId]
      );

      return sessions[0].user_id;
    } catch (error) {
      console.error('Session verification error:', error);
      return false;
    }
  },

  // إنهاء الجلسة
  destroySession: async (sessionId) => {
    try {
      const [result] = await pool.query(
        'DELETE FROM sessions WHERE id = ?',
        [sessionId]
      );
      return result.affectedRows > 0;
    } catch (error) {
      console.error('Session destruction error:', error);
      return false;
    }
  }
};
