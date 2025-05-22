const pool = require('../database');

const CategoriesController = {
    // الحصول على كل التصنيفات بدون الصور (للقوائم)
    getAllCategories: async (req, res) => {
        try {
            const [categories] = await pool.query(`
                SELECT id, name, description 
                FROM categories
            `);
            
            res.json({ success: true, data: categories });
        } catch (error) {
            console.error('Error fetching categories:', error);
            res.status(500).json({ success: false, message: 'Failed to fetch categories' });
        }
    },

    // الحصول على تصنيف معين بالصور
    getCategoryWithImages: async (req, res) => {
        try {
            const { id } = req.params;
            const [categories] = await pool.query(`
                SELECT id, name, description, icon, image 
                FROM categories 
                WHERE id = ?
            `, [id]);
            
            if (!categories.length) {
                return res.status(404).json({ success: false, message: 'Category not found' });
            }
            
            const category = categories[0];
            const response = {
                ...category,
                icon: category.icon ? `/api/categories/${id}/icon` : null,
                image: category.image ? `/api/categories/${id}/image` : null
            };
            
            res.json({ success: true, data: response });
        } catch (error) {
            console.error('Error fetching category:', error);
            res.status(500).json({ success: false, message: 'Failed to fetch category' });
        }
    },

    // الحصول على الأيقونة فقط
    getIcon: async (req, res) => {
        try {
            const { id } = req.params;
            const [categories] = await pool.query('SELECT icon FROM categories WHERE id = ?', [id]);
            
            if (!categories.length || !categories[0].icon) {
                return res.status(404).send('Icon not found');
            }
            
            res.set('Content-Type', 'image/png');
            res.send(categories[0].icon);
        } catch (error) {
            console.error('Error fetching icon:', error);
            res.status(500).send('Failed to fetch icon');
        }
    },

    // الحصول على الصورة فقط
    getImage: async (req, res) => {
        try {
            const { id } = req.params;
            const [categories] = await pool.query('SELECT image FROM categories WHERE id = ?', [id]);
            
            if (!categories.length || !categories[0].image) {
                return res.status(404).send('Image not found');
            }
            
            res.set('Content-Type', 'image/jpeg');
            res.send(categories[0].image);
        } catch (error) {
            console.error('Error fetching image:', error);
            res.status(500).send('Failed to fetch image');
        }
    }
};

module.exports = CategoriesController;
