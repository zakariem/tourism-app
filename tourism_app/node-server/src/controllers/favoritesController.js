const User = require('../models/User');
const Place = require('../models/Place');

// Add a place to user's favorites
exports.addToFavorites = async (req, res) => {
    try {
        const { placeId } = req.body;
        const userId = req.user.id;

        // Check if place exists
        const place = await Place.findById(placeId);
        if (!place) {
            return res.status(404).json({ message: 'Place not found' });
        }

        // Find user and check if place is already in favorites
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        if (user.favorites.includes(placeId)) {
            return res.status(400).json({ message: 'Place already in favorites' });
        }

        // Add place to favorites
        user.favorites.push(placeId);
        await user.save();

        res.status(200).json({ 
            message: 'Place added to favorites successfully',
            favorites: user.favorites
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Remove a place from user's favorites
exports.removeFromFavorites = async (req, res) => {
    try {
        const { placeId } = req.params;
        const userId = req.user.id;

        // Find user
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Check if place is in favorites
        if (!user.favorites.includes(placeId)) {
            return res.status(400).json({ message: 'Place not in favorites' });
        }

        // Remove place from favorites
        user.favorites = user.favorites.filter(id => id.toString() !== placeId);
        await user.save();

        res.status(200).json({ 
            message: 'Place removed from favorites successfully',
            favorites: user.favorites
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get user's favorite places
exports.getFavorites = async (req, res) => {
    try {
        const userId = req.user.id;

        // Find user and populate favorites with place details
        const user = await User.findById(userId).populate({
            path: 'favorites',
            model: 'Place'
        });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ 
            favorites: user.favorites,
            count: user.favorites.length
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Check if a place is in user's favorites
exports.isFavorite = async (req, res) => {
    try {
        const { placeId } = req.params;
        const userId = req.user.id;

        // Find user
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const isFavorite = user.favorites.includes(placeId);
        
        res.status(200).json({ 
            isFavorite,
            placeId
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Toggle favorite status (add if not favorite, remove if favorite)
exports.toggleFavorite = async (req, res) => {
    try {
        const { placeId } = req.body;
        const userId = req.user.id;

        // Check if place exists
        const place = await Place.findById(placeId);
        if (!place) {
            return res.status(404).json({ message: 'Place not found' });
        }

        // Find user
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const isFavorite = user.favorites.includes(placeId);
        
        if (isFavorite) {
            // Remove from favorites
            user.favorites = user.favorites.filter(id => id.toString() !== placeId);
        } else {
            // Add to favorites
            user.favorites.push(placeId);
        }

        await user.save();

        res.status(200).json({ 
            message: isFavorite ? 'Place removed from favorites' : 'Place added to favorites',
            isFavorite: !isFavorite,
            favorites: user.favorites
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};