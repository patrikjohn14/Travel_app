const axios = require('axios');

const OSRM_BASE_URL = 'https://router.project-osrm.org';

const DEFAULT_START = {
  lat: 35.349961,
  lng: 1.32057120, 
};

exports.getRoute = async (req, res) => {
  try {
    const { endLat, endLng } = req.query;

    if (!endLat || !endLng) {
      return res.status(400).json({
        success: false,
        message: 'Missing endLat or endLng',
      });
    }

    const start = `${DEFAULT_START.lng},${DEFAULT_START.lat}`;
    const end = `${endLng},${endLat}`;

    const primaryUrl = `${OSRM_BASE_URL}/route/v1/driving/${start};${end}?overview=full&geometries=geojson&steps=true`;


    const midLat = (DEFAULT_START.lat + parseFloat(endLat)) / 2 + 0.01;
    const midLng = (DEFAULT_START.lng + parseFloat(endLng)) / 2 + 0.01;
    const viaPoint = `${midLng},${midLat}`;

    const alternativeUrl = `${OSRM_BASE_URL}/route/v1/driving/${start};${viaPoint};${end}?overview=full&geometries=geojson&steps=true`;

    const [primaryRes, alternativeRes] = await Promise.all([
      axios.get(primaryUrl),
      axios.get(alternativeUrl),
    ]);

    const primary = primaryRes.data.routes[0];
    const alternative = alternativeRes.data.routes[0];

    res.json({
      success: true,
      data: {
        primaryRoute: {
          coordinates: primary.geometry.coordinates,
          distanceKm: (primary.distance / 1000).toFixed(3) * 1,
          durationMin: (primary.duration / 60).toFixed(2) * 1,
          instructions: primary.legs[0].steps.map(step => ({
            type: step.maneuver.type,
            modifier: step.maneuver.modifier || '',
            name: step.name || '',
            distance: (step.distance / 1000).toFixed(4) * 1,
            duration: (step.duration / 60).toFixed(4) * 1,
          })),
        },
        alternativeRoute: {
          coordinates: alternative.geometry.coordinates,
          distanceKm: (alternative.distance / 1000).toFixed(3) * 1,
          durationMin: (alternative.duration / 60).toFixed(2) * 1,
        },
      },
    });
  } catch (error) {
    console.error('Error fetching route:', error.message);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
};
