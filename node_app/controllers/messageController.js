const pool = require('../database');

module.exports = {
    // ✅ جلب رسائل المجموعة مع بيانات المرسل
    getGroupMessages: async (req, res) => {
        try {
            const groupId = parseInt(req.params.groupId);

            const [messages] = await pool.query(
                `SELECT 
          gm.id,
          gm.group_id,
          gm.sender_id,
          gm.message,
          gm.sent_at,
          u.first_name,
          u.last_name,
          u.profile_picture
        FROM group_messages gm
        JOIN users u ON gm.sender_id = u.id
        WHERE gm.group_id = ?
        ORDER BY gm.sent_at DESC`,
                [groupId]
            );

            res.status(200).json({
                success: true,
                data: messages,
            });

        } catch (error) {
            console.error('Error fetching group messages:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error while fetching messages',
            });
        }
    },

    // ✅ إرسال رسالة جديدة للمجموعة
    sendGroupMessage: async (req, res) => {
        try {
            const groupId = parseInt(req.params.groupId);
            const { userId, content } = req.body;

            if (!userId || !content) {
                return res.status(400).json({
                    success: false,
                    error: 'userId and content are required',
                });
            }

            await pool.query(
                `INSERT INTO group_messages (group_id, sender_id, message, sent_at)
         VALUES (?, ?, ?, NOW())`,
                [groupId, userId, content]
            );

            res.status(200).json({
                success: true,
                message: 'Message sent successfully',
            });

        } catch (error) {
            console.error('Error sending message:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error while sending message',
            });
        }
    },
    // في messageController.js
    getUserChats: async (req, res) => {
        try {
            const userId = parseInt(req.params.userId);

            const [chats] = await pool.query(`
        SELECT 
          g.id AS group_id,
          g.name AS group_name,
          g.image AS group_image,
          gm.message,
          gm.sent_at
        FROM group_messages gm
        JOIN groups g ON gm.group_id = g.id
        WHERE gm.sender_id = ?
        GROUP BY g.id
        ORDER BY MAX(gm.sent_at) DESC
      `, [userId]);

            res.status(200).json({ success: true, data: chats });
        } catch (error) {
            console.error('Error fetching user chats:', error);
            res.status(500).json({ success: false, error: 'Internal server error' });
        }
    },
};
