const pool = require('../database');

const friendController = {
 
  searchUsers: async (req, res) => {
    try {
      const { userId } = req.params;
      const { query } = req.query;
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;

      if (!userId || isNaN(userId)) {
        return res.status(400).json({ error: 'Invalid user ID' });
      }

      let sql = `
        SELECT u.id, u.first_name, u.last_name, u.profile_picture,
          CASE
            WHEN f.user1_id IS NOT NULL THEN 'friend'
            WHEN fr.sender_id = ? AND fr.status = 'pending' THEN 'request_sent'
            WHEN fr.receiver_id = ? AND fr.status = 'pending' THEN 'request_received'
            ELSE 'none'
          END AS relationship_status
        FROM users u
        LEFT JOIN friends f ON (f.user1_id = u.id OR f.user2_id = u.id) 
          AND (f.user1_id = ? OR f.user2_id = ?)
        LEFT JOIN friend_requests fr ON 
          ((fr.sender_id = ? AND fr.receiver_id = u.id) OR 
           (fr.sender_id = u.id AND fr.receiver_id = ?))
        WHERE u.id != ?
      `;
      
      let params = [userId, userId, userId, userId, userId, userId, userId];
      
      if (query && query.trim() !== '') {
        const searchTerm = `%${query.trim()}%`;
        sql += ` AND (CONCAT(u.first_name, ' ', u.last_name) LIKE ? OR u.first_name LIKE ? OR u.last_name LIKE ?)`;
        params.push(searchTerm, searchTerm, searchTerm);
      }

      sql += ` LIMIT ? OFFSET ?`;
      params.push(limit, offset);

      const [users] = await pool.query(sql, params);
      
      res.status(200).json({
        success: true,
        data: users,
        pagination: { page, limit }
      });

    } catch (error) {
      console.error('Search error:', error);
      res.status(500).json({ error: 'Error occurred while searching' });
    }
  },

  sendFriendRequest: async (req, res) => {
    try {
      const senderId = parseInt(req.params.senderId);
      const receiverId = parseInt(req.body.receiverId);

      // Data validation
      if (isNaN(senderId)) {
        return res.status(400).json({ 
          success: false,
          error: 'Sender ID must be a valid number' 
        });
      }
      
      if (isNaN(receiverId)) {
        return res.status(400).json({ 
          success: false,
          error: 'Receiver ID must be a valid number' 
        });
      }

      if (senderId === receiverId) {
        return res.status(400).json({ 
          success: false,
          error: 'Cannot send friend request to yourself' 
        });
      }

      // Start transaction to manage operations
      const connection = await pool.getConnection();
      await connection.beginTransaction();

      try {
        // Check for existing friendship
        const [existing] = await connection.query(
          `SELECT 1 FROM friends 
           WHERE (user1_id = ? AND user2_id = ?) OR 
                 (user1_id = ? AND user2_id = ?) 
           LIMIT 1`,
          [senderId, receiverId, receiverId, senderId]
        );

        if (existing.length > 0) {
          await connection.rollback();
          return res.status(400).json({ 
            success: false,
            error: 'You are already friends' 
          });
        }

        // Check for existing requests
        const [request] = await connection.query(
          `SELECT status FROM friend_requests 
           WHERE (sender_id = ? AND receiver_id = ?) OR 
                 (sender_id = ? AND receiver_id = ?) 
           LIMIT 1`,
          [senderId, receiverId, receiverId, senderId]
        );

        if (request.length > 0) {
          await connection.rollback();
          const statusMessage = request[0].status === 'pending' ? 
            'There is a pending friend request' : 
            `There is a previous friend request (status: ${request[0].status})`;
          
          return res.status(400).json({ 
            success: false,
            error: statusMessage 
          });
        }

        // Send friend request
        const [result] = await connection.query(
          `INSERT INTO friend_requests 
           (sender_id, receiver_id, status, created_at) 
           VALUES (?, ?, 'pending', NOW())`,
          [senderId, receiverId]
        );

        await connection.commit();

        // Send response with request data
        res.status(201).json({ 
          success: true,
          message: 'Friend request sent successfully',
          data: {
            requestId: result.insertId,
            senderId,
            receiverId,
            status: 'pending',
            timestamp: new Date().toISOString()
          }
        });

      } catch (transactionError) {
        await connection.rollback();
        throw transactionError;
      } finally {
        connection.release();
      }
    } catch (error) {
      console.error('Send request error:', error);
      
      res.status(500).json({ 
        success: false,
        error: 'Error occurred while sending request',
        details: process.env.NODE_ENV === 'development' ? {
          message: error.message,
          stack: error.stack
        } : undefined
      });
    }
  },

  // Get received friend requests
  getFriendRequests: async (req, res) => {
    try {
      const { userId } = req.params;
      console.log('Received userId:', userId);

      const [requests] = await pool.query(
        `SELECT fr.id, fr.sender_id, u.first_name, u.last_name, u.profile_picture, fr.created_at
         FROM friend_requests fr
         JOIN users u ON fr.sender_id = u.id
         WHERE fr.receiver_id = ? AND fr.status = 'pending'
         ORDER BY fr.created_at DESC`,
        [userId]
      );

      res.status(200).json({ success: true, data: requests });
    } catch (error) {
      console.error('Get requests error:', error);
      res.status(500).json({ error: 'Error occurred while fetching requests' });
    }
  },

  // Accept friend request
  acceptFriendRequest: async (req, res) => {
    try {
      const { requestId } = req.params;
      const { userId } = req.body; // ID of the user accepting the request

      // Check if request exists
      const [request] = await pool.query(
        `SELECT * FROM friend_requests WHERE id = ? AND receiver_id = ? AND status = 'pending'`,
        [requestId, userId]
      );

      if (request.length === 0) {
        return res.status(404).json({ error: 'Friend request not found' });
      }

      // Start transaction
      await pool.query('START TRANSACTION');

      try {
        // Update request status
        await pool.query(
          `UPDATE friend_requests SET status = 'accepted', updated_at = NOW() WHERE id = ?`,
          [requestId]
        );

        // Add friendship
        const senderId = request[0].sender_id;
        const user1Id = Math.min(senderId, userId);
        const user2Id = Math.max(senderId, userId);

        await pool.query(
          `INSERT INTO friends (user1_id, user2_id) VALUES (?, ?)`,
          [user1Id, user2Id]
        );

        await pool.query('COMMIT');
        res.status(200).json({ success: true, message: 'Friend request accepted' });

      } catch (error) {
        await pool.query('ROLLBACK');
        throw error;
      }

    } catch (error) {
      console.error('Accept request error:', error);
      res.status(500).json({ error: 'Error occurred while accepting request' });
    }
  },

  // Reject friend request
  rejectFriendRequest: async (req, res) => {
    try {
      const { requestId } = req.params;
      const { userId } = req.body;

      const [result] = await pool.query(
        `UPDATE friend_requests 
         SET status = 'rejected', updated_at = NOW() 
         WHERE id = ? AND receiver_id = ? AND status = 'pending'`,
        [requestId, userId]
      );

      if (result.affectedRows === 0) {
        return res.status(404).json({ error: 'Friend request not found' });
      }

      res.status(200).json({ success: true, message: 'Friend request rejected' });
    } catch (error) {
      console.error('Reject request error:', error);
      res.status(500).json({ error: 'Error occurred while rejecting request' });
    }
  },

  getFriendsList: async (req, res) => {
    try {
      const { userId } = req.params;

      const [friends] = await pool.query(
        `SELECT u.id, u.first_name, u.last_name, u.profile_picture
         FROM friends f
         JOIN users u ON (f.user1_id = u.id OR f.user2_id = u.id) AND u.id != ?
         WHERE f.user1_id = ? OR f.user2_id = ?`,
        [userId, userId, userId]
      );

      res.status(200).json({ success: true, data: friends });
    } catch (error) {
      console.error('Get friends error:', error);
      res.status(500).json({ error: 'Error occurred while fetching friends list' });
    }
  },

  // Remove friend
  removeFriend: async (req, res) => {
    const connection = await pool.getConnection();
    try {
      const { userId, friendId } = req.params;

      if (!userId || !friendId || isNaN(userId) || isNaN(friendId)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid user IDs'
        });
      }

      await connection.beginTransaction();

      // 1. Delete friendship from friends table
      const [deleteFriendResult] = await connection.query(
        `DELETE FROM friends 
         WHERE (user1_id = ? AND user2_id = ?) 
         OR (user1_id = ? AND user2_id = ?)`,
        [userId, friendId, friendId, userId]
      );

      // 2. Delete any friend requests between them
      const [deleteRequestsResult] = await connection.query(
        `DELETE FROM friend_requests
         WHERE (sender_id = ? AND receiver_id = ?)
         OR (sender_id = ? AND receiver_id = ?)`,
        [userId, friendId, friendId, userId]
      );

      if (deleteFriendResult.affectedRows === 0 && deleteRequestsResult.affectedRows === 0) {
        await connection.rollback();
        return res.status(404).json({
          success: false,
          error: 'No friendship or requests found between users'
        });
      }

      await connection.commit();
      
      res.status(200).json({
        success: true,
        message: 'Friend and related requests removed successfully',
        data: {
          friendRemoved: deleteFriendResult.affectedRows > 0,
          requestsRemoved: deleteRequestsResult.affectedRows
        }
      });

    } catch (error) {
      if (connection) await connection.rollback();
      console.error('Remove friend error:', error);
      res.status(500).json({
        success: false,
        error: 'Error occurred while removing friend',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    } finally {
      if (connection) connection.release();
    }
  },

  // Get sent friend requests
  getSentRequests: async (req, res) => {
    try {
      const { userId } = req.params;

      const [requests] = await pool.query(
        `SELECT fr.id, fr.receiver_id, u.first_name, u.last_name, u.profile_picture, fr.created_at
         FROM friend_requests fr
         JOIN users u ON fr.receiver_id = u.id
         WHERE fr.sender_id = ? AND fr.status = 'pending'
         ORDER BY fr.created_at DESC`,
        [userId]
      );

      res.status(200).json({ success: true, data: requests });
    } catch (error) {
      console.error('Get sent requests error:', error);
      res.status(500).json({ error: 'Error occurred while fetching sent requests' });
    }
  },

  // Cancel sent friend request
  cancelFriendRequest: async (req, res) => {
    const connection = await pool.getConnection();
    try {
      const { requestId } = req.params;
      const { userId } = req.body;

      await connection.beginTransaction();

      const [result] = await connection.query(
        `DELETE FROM friend_requests 
         WHERE id = ? AND sender_id = ? AND status = 'pending'`,
        [requestId, userId]
      );

      if (result.affectedRows === 0) {
        await connection.rollback();
        return res.status(404).json({ 
          success: false,
          error: 'Friend request not found or already processed' 
        });
      }

      await connection.commit();
      res.status(200).json({ 
        success: true, 
        message: 'Friend request cancelled successfully' 
      });
    } catch (error) {
      await connection.rollback();
      console.error('Cancel request error:', error);
      res.status(500).json({ 
        success: false,
        error: 'Error occurred while cancelling request' 
      });
    } finally {
      connection.release();
    }
  },
};

module.exports = friendController;
