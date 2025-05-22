// middlewares/sessionMiddleware.js
const { verifySession } = require('../controllers/sessionController');

const checkSession = async (req, res, next) => {
  const sessionId = req.headers['session-id'];

  if (!sessionId) {
    return res.status(401).json({ 
      success: false,
      message: 'Session ID is required' 
    });
  }

  const userId = await verifySession(sessionId);

  if (!userId) {
    return res.status(401).json({ 
      success: false,
      message: 'Invalid or expired session' 
    });
  }

  req.userId = userId;
  next();
};

module.exports = { checkSession };
