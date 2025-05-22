const fs = require('fs'); // لإدارة قراءة الملفات
const pool = require('../database');

const PlaceController = {
    // دالة جلب الأماكن باستخدام معرّف التصنيف
    getPlacesByCategoryId: async (req, res) => {
        try {
            const { categoryId } = req.params;
            const [places] = await pool.query(
                `
                SELECT id, category_id, name, description, country, province, municipality, 
                       neighborhood, latitude, longitude, map_link, image_picture, rate
                FROM places
                WHERE category_id = ?
            `,
                [categoryId]
            );

            if (!places.length) {
                return res.status(404).json({
                    success: false,
                    message: 'No places found for this category',
                });
            }

            const placesWithBase64 = places.map((place) => {
                let imageBase64 = null;

                if (place.image_picture) {
                    try {
                        if (typeof place.image_picture === 'string') {
                            const imageData = fs.readFileSync(place.image_picture);
                            imageBase64 = imageData.toString('base64');
                        } else {
                            imageBase64 = Buffer.from(place.image_picture).toString('base64');
                        }
                    } catch (readError) {
                        console.error(`Error reading image file for place ID ${place.id}:`, readError);
                    }
                }

                return { ...place, image_picture: imageBase64 };
            });

            res.json({ success: true, data: placesWithBase64 });
        } catch (error) {
            console.error('Error fetching places by category ID:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to fetch places',
            });
        }
    },

    // دالة جلب جميع الأماكن
    getAllPlaces: async (req, res) => {
        try {
            const [places] = await pool.query(
                `
                SELECT id, category_id, name, description, country, province, municipality, 
                       neighborhood, latitude, longitude, map_link, image_picture, rate
                FROM places
            `
            );

            if (!places.length) {
                return res.status(404).json({
                    success: false,
                    message: 'No places found',
                });
            }

            const placesWithImages = places.map((place) => {
                let imageBase64 = null;

                if (place.image_picture) {
                    try {
                        if (typeof place.image_picture === 'string') {
                            const imageData = fs.readFileSync(place.image_picture);
                            imageBase64 = imageData.toString('base64');
                        } else {
                            imageBase64 = Buffer.from(place.image_picture).toString('base64');
                        }
                    } catch (readError) {
                        console.error(`Error reading image for place ID ${place.id}:`, readError);
                    }
                }

                return {
                    ...place,
                    image_picture: imageBase64,
                };
            });

            res.json({
                success: true,
                data: placesWithImages,
            });
        } catch (error) {
            console.error('Error fetching all places:', error);
            res.status(500).json({
                success: false,
                message: 'Failed to fetch places',
            });
        }
    },
};

module.exports = PlaceController;

