const pool = require('../database');

const favoriteController = {
  // Add to favorites
  addToFavorite: async (req, res) => {
    try {
      const { user_id, place_id } = req.body;
      
      if (!user_id || !place_id) {
        return res.status(400).json({ 
          success: false, 
          message: 'User ID and Place ID are required' 
        });
      }
      
      // التحقق من عدم وجود تكرار في قاعدة البيانات
      const [existing] = await pool.query(
        'SELECT * FROM favorites WHERE user_id = ? AND place_id = ?',
        [user_id, place_id]
      );
      
      if (existing.length > 0) {
        return res.status(409).json({ 
          success: false, 
          message: 'This place is already in favorites' 
        });
      }
      
      // إضافة المفضلة
      const [result] = await pool.query(
        'INSERT INTO favorites (user_id, place_id) VALUES (?, ?)',
        [user_id, place_id]
      );
      
      res.status(201).json({ 
        success: true,
        message: 'تمت الإضافة إلى المفضلة',
        data: {
          id: result.insertId,
          user_id,
          place_id
        }
      });
    } catch (error) {
      console.error('Add favorite error:', error);
      res.status(500).json({ 
        success: false,
        message: 'Failed to add favorite'
      });
    }
  },
  
  // Remove from favorites
  removeFromFavorite: async (req, res) => {
    try {
      const placeId = req.params.placeId;
      const  user_id  = req.params.userId;
      
      // التحقق من وجود البيانات المطلوبة
      if (!user_id || !placeId) {
        return res.status(400).json({ 
          success: false, 
          message: 'User ID and Place ID are required' 
        });
      }
      
      // حذف المفضلة
      const [result] = await pool.query(
        'DELETE FROM favorites WHERE user_id = ? AND place_id = ?',
        [user_id, placeId]
      );
      
      if (result.affectedRows === 0) {
        return res.status(404).json({ 
          success: false, 
          message: 'Favorite not found' 
        });
      }
      
      res.status(200).json({ 
        success: true,
        message: 'تمت إزالة العنصر من المفضلة'
      });
    } catch (error) {
      console.error('Remove favorite error:', error);
      res.status(500).json({ 
        success: false,
        message: 'Failed to remove favorite'
      });
    }
  },
  
  // Get user favorites
  getUserFavorites: async (req, res) => {
    try {
      const userId = req.params.userId;
      
      if (!userId) {
        return res.status(400).json({ 
          success: false, 
          message: 'User ID is required' 
        });
      }
      
      // الحصول على قائمة المفضلة للمستخدم
      const [favorites] = await pool.query(
        `SELECT f.*, p.name, p.description, p.image_picture, p.province, p.municipality, p.rate 
         FROM favorites f
         JOIN places p ON f.place_id = p.id
         WHERE f.user_id = ?`,
        [userId]
      );
      
      res.status(200).json({
        success: true,
        data: favorites
      });
    } catch (error) {
      console.error('Get user favorites error:', error);
      res.status(500).json({ 
        success: false,
        message: 'Failed to get favorites'
      });
    }
  }
};

module.exports = favoriteController;
