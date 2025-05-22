const express = require('express');
const app = express();
const router = express.Router();
const { login } = require('../controllers/authController');
const { register } = require('../controllers/registerController');
const categoriesController = require('../controllers/categoriesController');
const { checkSession } = require('../middlewares/sessionMiddleware');
const userController = require('../controllers/userController');
const placeController = require('../controllers/placeController');
const sessionMiddleware = require('../controllers/sessionController');
const notificationController = require('../controllers/notificationController');
const favoriteController = require('../controllers/favoriteController');
const searchController = require('../controllers/searchController');
const friendController = require('../controllers/friendController');
const groupController = require('../controllers/groupController');
const upload = require('../middlewares/upload');
const uploadProfile = require('../middlewares/uploadProfile');
const messageController = require('../controllers/messageController');
const routeController = require('../controllers/routeController');
const alertController = require('../controllers/alertRouteController');

router.post('/login', login);
router.post('/register', register);


router.get('/categories', categoriesController.getAllCategories);
router.get('/categories/:id', categoriesController.getCategoryWithImages);
router.get('/categories/:id/icon', categoriesController.getIcon);
router.get('/categories/:id/image', categoriesController.getImage);


router.get('/protected', checkSession, (req, res) => {
  res.json({
    success: true,
    message: 'تم السماح بالوصول',
    userId: req.userId
  });
});


router.put('/users/:id', uploadProfile.single('profile_picture'), userController.updateUserProfile);
router.get('/users/:id', userController.getUserProfile);

router.get('/places', placeController.getAllPlaces);
router.get('/categories/:categoryId/places', placeController.getPlacesByCategoryId);

// Route تسجيل الخروج
router.post('/logout', async (req, res) => {
  try {
    const sessionId = req.headers['session-id'];
    const isDestroyed = await sessionMiddleware.destroySession(sessionId);

    if (isDestroyed) {
      res.json({ success: true, message: 'Logged out successfully' });
    } else {
      res.status(500).json({ success: false, message: 'Failed to destroy session' });
    }
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

// Routes الإشعارات (معدلة باستخدام checkSession بدل authMiddleware)
router.get('/notifications', async (req, res) => {
  try {
    const { limit = 20, unreadOnly = false } = req.query;

    const notifications = unreadOnly
      ? await notificationController.getUnreadNotifications(req.userId, parseInt(limit))
      : await notificationController.getAllUserNotifications(req.userId, parseInt(limit));

    res.json({
      success: true,
      data: notifications,
      meta: {
        total: notifications.length,
        unread: notifications.filter(n => !n.is_read).length
      }
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
  }
});

router.put('/notifications/:id/read', async (req, res) => {
  try {
    await notificationController.markAsRead(req.userId, req.params.id);
    res.json({ success: true, message: 'Notification marked as read' });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ success: false, message: 'Failed to mark notification as read' });
  }
});

router.put('/notifications/mark-all-read', async (req, res) => {
  try {
    await notificationController.markAllAsRead(req.userId);
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({ success: false, message: 'Failed to mark all notifications as read' });
  }
});

router.delete('/notifications/:id', async (req, res) => {
  try {
    await notificationController.deleteNotification(req.userId, req.params.id);
    res.json({ success: true, message: 'Notification deleted successfully' });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete notification' });
  }
});

router.post('/favorites/', favoriteController.addToFavorite);


router.delete('/favorites/:userId/:placeId', favoriteController.removeFromFavorite);

router.get('/favorites/user/:userId', favoriteController.getUserFavorites);

router.get('/users/search/:userId', searchController.searchUsers);


router.get('/search/:userId', friendController.searchUsers);

router.post('/request/:senderId', friendController.sendFriendRequest);

router.get('/requests/:userId', friendController.getFriendRequests);

router.put('/accept/:requestId', friendController.acceptFriendRequest);

router.put('/reject/:requestId', friendController.rejectFriendRequest);

router.get('/friends/:userId', friendController.getFriendsList);

router.delete('/friends/:userId/:friendId', friendController.removeFriend);

router.get('/sent-requests/:userId', friendController.getSentRequests);

router.delete('/cancel-request/:requestId', friendController.cancelFriendRequest);

router.post('/create-group/:creatorId', upload.single('image'), groupController.createGroup);

router.get('/user-groups/:userId', groupController.getUserGroups);

router.delete('/groups/:groupId', groupController.deleteGroup);

router.put('/groups/:groupId', upload.single('image'), groupController.updateGroup);

router.post('/groups/:groupId/add-member/:userId', groupController.addMemberToGroup);

router.get('/groups/:groupId/members', groupController.getGroupMembers);

router.get('/groups/:groupId/creator', groupController.getGroupCreator);

router.get('/member-groups/:userId', groupController.getMemberGroups);

router.post('/groups/:groupId/leave', groupController.leaveGroup);

router.get('/groups/:groupId/messages', messageController.getGroupMessages);

router.post('/groups/:groupId/messages', messageController.sendGroupMessage);

router.get('/user-chats/:userId', messageController.getUserChats);

router.get('/user-groups/:userId', groupController.getUserGroups);

router.get('/routes', routeController.getRoute);

router.get('/alerts/check', alertController.checkAlertByCoordinates)
module.exports = router;
