const express = require('express');
const {
    addToFavorites,
    removeFromFavorites,
    getFavorites,
    isFavorite,
    toggleFavorite
} = require('../controllers/favoritesController');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

// All routes are protected and require authentication
router.use(protect);

// GET /api/favorites - Get user's favorite places
router.get('/', getFavorites);

// POST /api/favorites - Add a place to favorites
router.post('/', addToFavorites);

// POST /api/favorites/toggle - Toggle favorite status
router.post('/toggle', toggleFavorite);

// GET /api/favorites/check/:placeId - Check if place is favorite
router.get('/check/:placeId', isFavorite);

// DELETE /api/favorites/:placeId - Remove place from favorites
router.delete('/:placeId', removeFromFavorites);

module.exports = router;