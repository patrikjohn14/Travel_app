const pool = require('../database');

const searchController = {
  searchUsers: async (req, res) => {
    try {
      const { userId } = req.params;
      const { query } = req.query;
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;

      if (!userId || isNaN(userId)) {
        return res.status(400).json({
          success: false,
          message: 'معرف المستخدم غير صالح'
        });
      }

      let sql = `
        SELECT id, first_name, last_name, bio
        FROM users
        WHERE id != ?
      `;
      let countSql = `SELECT COUNT(*) as total FROM users WHERE id != ?`;
      const params = [userId];
      const countParams = [userId];


      if (query && query.trim() !== '') {
        const searchTerm = `%${query.trim()}%`;
        sql += ` AND (
          LOWER(CONCAT(first_name, ' ', last_name)) LIKE LOWER(?) OR
          LOWER(first_name) LIKE LOWER(?) OR 
          LOWER(last_name) LIKE LOWER(?)
        )`;
        countSql += ` AND (
          LOWER(CONCAT(first_name, ' ', last_name)) LIKE LOWER(?) OR
          LOWER(first_name) LIKE LOWER(?) OR 
          LOWER(last_name) LIKE LOWER(?)
        )`;
        params.push(searchTerm, searchTerm, searchTerm);
        countParams.push(searchTerm, searchTerm, searchTerm);
      }

      sql += ` ORDER BY first_name ASC LIMIT ? OFFSET ?`;
      params.push(limit, offset);

      const [users, [total]] = await Promise.all([
        pool.query(sql, params),
        pool.query(countSql, countParams)
      ]);

      res.status(200).json({
        success: true,
        data: {
          users,
          pagination: {
            total: total.total,
            page,
            limit,
            totalPages: Math.ceil(total.total / limit)
          }
        }
      });

    } catch (error) {
      console.error('Search users error:', error);
      res.status(500).json({
        success: false,
        message: 'حدث خطأ أثناء البحث',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
};

module.exports = searchController;

