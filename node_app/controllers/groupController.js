const pool = require('../database');
const path = require('path');
const upload = require('../middlewares/upload');

const groupController = {

  createGroup: async (req, res) => {
    const connection = await pool.getConnection();
    try {
      const { name, description } = req.body;
      const creatorId = parseInt(req.params.creatorId);

      const imagePath = req.file ? `/assets/images/${req.file.filename}` : null;

      await connection.beginTransaction();

      const [result] = await connection.query(
        "INSERT INTO \`groups\` (name, description, creator_id, image, created_at, updated_at) VALUES (?, ?, ?, ?, NOW(), NOW())",
        [name.trim(), description?.trim(), creatorId, imagePath]
      );


      await connection.query(
        `INSERT INTO  \`group_members\` (group_id, user_id, role, joined_at)
         VALUES (?, ?, 'admin', NOW())`,
        [result.insertId, creatorId]
      );

      await connection.commit();

      res.status(201).json({
        success: true,
        message: 'Group created successfully',
        data: {
          groupId: result.insertId,
          name: name.trim(),
          description: description?.trim(),
          image: imagePath
        }
      });

    } catch (error) {
      await connection.rollback();
      console.error('Create group error:', error);
      res.status(500).json({ success: false, error: 'Error occurred while creating group' });
    } finally {
      connection.release();
    }
  }
  ,
  updateGroup: async (req, res) => {
    const connection = await pool.getConnection();
    try {
      const groupId = parseInt(req.params.groupId);
      const { name, description, userId } = req.body;

      if (!name || !userId || isNaN(groupId)) {
        return res.status(400).json({ success: false, error: 'Invalid data provided' });
      }

      // ✅ التحقق من صلاحية المستخدم
      const [permission] = await connection.query(
        `SELECT gm.role, g.creator_id 
         FROM \`group_members\` gm
         JOIN \`groups\` g ON gm.group_id = g.id
         WHERE gm.group_id = ? AND gm.user_id = ?`,
        [groupId, userId]
      );

      if (
        permission.length === 0 ||
        (permission[0].role !== 'admin' && permission[0].creator_id != userId)
      ) {
        return res.status(403).json({
          success: false,
          error: 'You do not have permission to update this group'
        });
      }

      // ✅ تحضير مسار الصورة (إن وُجدت)
      const imagePath = req.file ? `/assets/images/${req.file.filename}` : null;

      // ✅ بناء الاستعلام ديناميكيًا حسب وجود صورة
      const fields = ['name = ?', 'description = ?', 'updated_at = NOW()'];
      const values = [name.trim(), description?.trim()];
      if (imagePath) {
        fields.splice(2, 0, 'image = ?');
        values.splice(2, 0, imagePath);
      }
      values.push(groupId); // WHERE id = ?

      const query = `UPDATE \`groups\` SET ${fields.join(', ')} WHERE id = ?`;

      const [result] = await connection.query(query, values);

      if (result.affectedRows === 0) {
        return res.status(404).json({ success: false, error: 'Group not found' });
      }

      res.status(200).json({
        success: true,
        message: 'Group updated successfully',
        data: {
          groupId,
          name: name.trim(),
          description: description?.trim(),
          ...(imagePath && { image: imagePath })
        }
      });
    } catch (error) {
      console.error('Update group error:', error);
      res.status(500).json({
        success: false,
        error: 'An error occurred while updating the group',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    } finally {
      connection.release();
    }
  },

  deleteGroup: async (req, res) => {
    const connection = await pool.getConnection();
    try {
      const { groupId } = req.params;
      const { userId } = req.body;

      await connection.beginTransaction();

      const [group] = await connection.query(
        `SELECT creator_id FROM \`groups\`  WHERE id = ?`,
        [groupId]
      );

      if (group.length === 0) {
        await connection.rollback();
        return res.status(404).json({
          success: false,
          error: 'Group not found'
        });
      }

      // التحقق أن المستخدم هو المنشئ
      if (group[0].creator_id !== userId) {
        await connection.rollback();
        return res.status(403).json({
          success: false,
          error: 'Only the group creator can delete the group'
        });
      }

      // حذف الأعضاء أولاً (لتفادي أخطاء المفاتيح الأجنبية)
      await connection.query(
        `DELETE FROM  \`group_members\`  WHERE group_id = ?`,
        [groupId]
      );

      // ثم حذف المجموعة
      await connection.query(
        `DELETE FROM \`groups\`  WHERE id = ?`,
        [groupId]
      );

      await connection.commit();

      res.status(200).json({
        success: true,
        message: 'Group deleted successfully'
      });

    } catch (error) {
      await connection.rollback();
      console.error('Delete group error:', error);
      res.status(500).json({
        success: false,
        error: 'Error occurred while deleting group',
        details: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    } finally {
      connection.release();
    }
  }
  ,
  getUserGroups: async (req, res) => {
    try {
      const userId = parseInt(req.params.userId);

      const [groups] = await pool.query(
        `SELECT id, name, description, image, creator_id
         FROM \`groups\` 
         WHERE creator_id = ? 
         ORDER BY created_at DESC`,
        [userId]
      );

      res.status(200).json({ success: true, data: groups });

    } catch (error) {
      console.error('Error fetching groups:', error);
      res.status(500).json({ success: false, error: 'Internal server error' });
    }
  }
  ,
  addMemberToGroup: async (req, res) => {
    const connection = await pool.getConnection();
    try {
      const { groupId, userId } = req.params; // جلب من URL params

      // تحقق فقط أن المجموعة موجودة
      const [groupCheck] = await connection.query(
        `SELECT id FROM \`groups\`  WHERE id = ?`,
        [groupId]
      );

      if (groupCheck.length === 0) {
        return res.status(404).json({ success: false, error: 'Group not found.' });
      }

      // تحقق أن العضو ليس مضاف من قبل
      const [alreadyMember] = await connection.query(
        `SELECT 1 FROM  \`group_members\`  WHERE group_id = ? AND user_id = ?`,
        [groupId, userId]
      );

      if (alreadyMember.length > 0) {
        return res.status(400).json({
          success: false,
          error: 'User is already a member of this group.',
        });
      }

      // إضافة العضو مباشرة
      await connection.query(
        `INSERT INTO  \`group_members\`  (group_id, user_id, role, joined_at)
         VALUES (?, ?, 'member', NOW())`,
        [groupId, userId]
      );

      res.status(200).json({
        success: true,
        message: 'User added to group successfully.',
      });
    } catch (error) {
      console.error('Error adding member to group:', error);
      res.status(500).json({
        success: false,
        error: 'Internal server error.',
      });
    } finally {
      connection.release();
    }
  },

  getGroupMembers: async (req, res) => {
    const connection = await pool.getConnection();
    try {
      const groupId = parseInt(req.params.groupId);

      const [members] = await connection.query(
        `SELECT u.id, u.first_name, u.last_name, u.bio, u.profile_picture
         FROM  \`group_members\`  gm
         JOIN users u ON gm.user_id = u.id
         WHERE gm.group_id = ?`,
        [groupId]
      );

      res.status(200).json({
        success: true,
        data: members
      });

    } catch (error) {
      console.error('Get group members error:', error);
      res.status(500).json({
        success: false,
        error: 'Error occurred while fetching group members'
      });
    } finally {
      connection.release();
    }
  }
  ,
  getGroupCreator: async (req, res) => {
    try {
      const groupId = req.params.groupId;

      const [result] = await pool.query(
        `SELECT creator_id FROM \`groups\` WHERE id = ?`,
        [groupId]
      );

      if (result.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'Group not found',
        });
      }

      res.status(200).json({
        success: true,
        creatorId: result[0].creator_id,
      });

    } catch (error) {
      console.error('Error getting group creator:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  },
  
  getMemberGroups: async (req, res) => {
    try {
      const userId = parseInt(req.params.userId);

      const [groups] = await pool.query(
        `SELECT g.id, g.name, g.description, g.image, g.creator_id
         FROM \`groups\`  g
         JOIN  \`group_members\`  gm ON g.id = gm.group_id
         WHERE gm.user_id = ? AND g.creator_id != ?
         ORDER BY g.created_at DESC`,
        [userId, userId]
      );

      res.status(200).json({
        success: true,
        data: groups,
      });
    } catch (error) {
      console.error('Get member groups error:', error);
      res.status(500).json({
        success: false,
        error: 'Error occurred while fetching member groups',
      });
    }
  },
    leaveGroup: async (req, res) => {
      const connection = await pool.getConnection();
      try {
        const groupId = parseInt(req.params.groupId);
        const { userId } = req.body;

        // تحقق هل المستخدم عضو فعلاً
        const [memberCheck] = await connection.query(
          `SELECT 1 FROM \`group_members\` WHERE group_id = ? AND user_id = ?`,
          [groupId, userId]
        );

        if (memberCheck.length === 0) {
          return res.status(400).json({
            success: false,
            error: 'You are not a member of this group',
          });
        }

        // احذف العضو من المجموعة
        await connection.query(
          `DELETE FROM \`group_members\`   WHERE group_id = ? AND user_id = ?`,
          [groupId, userId]
        );

        res.status(200).json({
          success: true,
          message: 'Successfully left the group',
        });

      } catch (error) {
        console.error('Leave group error:', error);
        res.status(500).json({
          success: false,
          error: 'Error occurred while leaving group',
        });
      } finally {
        connection.release();
      }
    }


};

module.exports = groupController;
