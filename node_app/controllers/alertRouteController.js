const pool = require('../database');

exports.checkAlertByCoordinates = async (req, res) => {
  try {
    const { lat, lng } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({
        success: false,
        message: 'Missing coordinates',
      });
    }

    const [rows] = await pool.query(
      `SELECT * FROM alert WHERE 
       ABS(latitude - ?) < 0.0001 AND ABS(longitude - ?) < 0.0001`,
      [parseFloat(lat), parseFloat(lng)]
    );

    if (rows.length > 0) {
      return res.status(200).json({
        success: true,
        hasAlert: true,
        message: rows[0].description || 'Alert exists for this location',
        alert: rows[0]
      });
    } else {
      return res.status(200).json({
        success: true,
        hasAlert: false,
        message: 'No alert at this location'
      });
    }

  } catch (error) {
    console.error('Error checking alert:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error while checking alert'
    });
  }
};
