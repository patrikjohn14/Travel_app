const pool = require('../database');

const CategoriesController = {
    getAllCategories: async (req, res) => {
        try {
            const [categories] = await pool.query(`
                SELECT id, name, description, icon, image
                FROM categories
            `);
            
            // تحويل الأيقونات والصور إلى Base64
            const categoriesWithBase64 = categories.map(category => {
                const iconBase64 = category.icon ? category.icon.toString('base64') : null;
                const imageBase64 = category.image ? category.image.toString('base64') : null;
                return {
                    ...category,
                    icon: iconBase64,
                    image: imageBase64
                };
            });

            res.json({ success: true, data: categoriesWithBase64 });
        } catch (error) {
            console.error('Error fetching categories:', error);
            res.status(500).json({ success: false, message: 'Failed to fetch categories' });
        }
    },

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
            const iconBase64 = category.icon ? category.icon.toString('base64') : null;
            const imageBase64 = category.image ? category.image.toString('base64') : null;

            const response = {
                ...category,
                icon: iconBase64,
                image: imageBase64
            };
            
            res.json({ success: true, data: response });
        } catch (error) {
            console.error('Error fetching category:', error);
            res.status(500).json({ success: false, message: 'Failed to fetch category' });
        }
    },

    getIcon: async (req, res) => {
        try {
            const { id } = req.params;
            const [categories] = await pool.query('SELECT icon FROM categories WHERE id = ?', [id]);
            
            if (!categories.length || !categories[0].icon) {
                return res.status(404).send('Icon not found');
            }
            
            const iconBase64 = categories[0].icon.toString('base64');
            res.json({ icon: iconBase64 });
        } catch (error) {
            console.error('Error fetching icon:', error);
            res.status(500).send('Failed to fetch icon');
        }
    },

    getImage: async (req, res) => {
        try {
            const { id } = req.params;
            const [categories] = await pool.query('SELECT image FROM categories WHERE id = ?', [id]);
            
            if (!categories.length || !categories[0].image) {
                return res.status(404).send('Image not found');
            }
            
            const imageBase64 = categories[0].image.toString('base64');
            res.json({ image: imageBase64 });
        } catch (error) {
            console.error('Error fetching image:', error);
            res.status(500).send('Failed to fetch image');
        }
    }
};

module.exports = CategoriesController;
