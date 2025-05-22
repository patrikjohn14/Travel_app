const pool = require('../database');

const notificationController = {
  // إرسال إشعار عند إضافة محتوى جديد (يتم استدعاؤها من controllers أخرى)
  sendNewContentNotification: async (contentType, contentId, adminId) => {
    try {
      let title, message, entityName;
      
      // تحديد نوع المحتوى المضاف
      switch(contentType) {
        case 'category':
          const [category] = await pool.query('SELECT name FROM categories WHERE id = ?', [contentId]);
          entityName = category[0].name;
          title = 'فئة جديدة!';
          message = `تمت إضافة فئة جديدة: ${entityName}`;
          break;
          
        /*
        case 'wilaya':
          // سيتم تنفيذ هذا الجزء لاحقاً بعد اكتمال جدول الولايات
          const [wilaya] = await pool.query('SELECT name FROM wilayas WHERE id = ?', [contentId]);
          entityName = wilaya[0].name;
          title = 'ولاية جديدة!';
          message = `تمت إضافة ولاية جديدة: ${entityName}`;
          break;
        */
          
        case 'place':
          const [place] = await pool.query('SELECT name FROM places WHERE id = ?', [contentId]);
          entityName = place[0].name;
          title = 'مكان جديد!';
          message = `تمت إضافة مكان جديد: ${entityName}`;
          break;
          
        default:
          throw new Error('نوع المحتوى غير معروف');
      }

      // إنشاء الإشعار
      const [result] = await pool.query(
        `INSERT INTO notifications (title, message, entity_type, entity_id, created_by) 
         VALUES (?, ?, ?, ?, ?)`,
        [title, message, contentType, contentId, adminId]
      );

      // إرسال لجميع المستخدمين
      await pool.query(
        `INSERT INTO user_notifications (notification_id, user_id)
         SELECT ?, id FROM users WHERE deleted_at IS NULL`,
        [result.insertId]
      );

      return result.insertId;
    } catch (error) {
      console.error('Error sending content notification:', error);
      throw error;
    }
  },

  // استلام الإشعارات (للمستخدم فقط)
  getUserNotifications: async (userId, limit = 20) => {
    try {
      const [notifications] = await pool.query(
        `SELECT n.*, un.is_read, 
         DATE_FORMAT(n.created_at, '%Y-%m-%d %H:%i') as formatted_date
         FROM notifications n
         JOIN user_notifications un ON n.id = un.notification_id
         WHERE un.user_id = ?
         ORDER BY n.created_at DESC
         LIMIT ?`,
        [userId, limit]
      );

      return notifications;
    } catch (error) {
      console.error('Error getting user notifications:', error);
      throw error;
    }
  },

  // تحديد الإشعار كمقروء
  markAsRead: async (userId, notificationId) => {
    try {
      await pool.query(
        `UPDATE user_notifications 
         SET is_read = TRUE, read_at = NOW()
         WHERE user_id = ? AND notification_id = ?`,
        [userId, notificationId]
      );
      return true;
    } catch (error) {
      console.error('Error marking notification as read:', error);
      throw error;
    }
  }
};

module.exports = notificationController;
