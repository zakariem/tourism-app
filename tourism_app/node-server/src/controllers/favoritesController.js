const User = require('../models/User');
const Place = require('../models/Place');

// Enhanced caching system for favorites
const favoritesCache = {
    userFavorites: new Map(), // userId -> {favorites, lastUpdated}
    cacheTTL: 3 * 60 * 1000, // 3 minutes for user-specific data
    dataVersion: 0
};

// Helper function to check cache validity
function isFavoritesCacheValid(timestamp) {
    return Date.now() - timestamp < favoritesCache.cacheTTL;
}

// Helper function to invalidate user's favorites cache
function invalidateUserFavoritesCache(userId) {
    favoritesCache.userFavorites.delete(userId);
    favoritesCache.dataVersion += 1;
    console.log(`🔄 Favorites cache invalidated for user: ${userId}`);
}

// Helper function to get cached favorites
function getCachedFavorites(userId) {
    const cached = favoritesCache.userFavorites.get(userId);
    if (cached && isFavoritesCacheValid(cached.lastUpdated)) {
        return cached.favorites;
    }
    return null;
}

// Helper function to set cached favorites
function setCachedFavorites(userId, favorites) {
    favoritesCache.userFavorites.set(userId, {
        favorites,
        lastUpdated: Date.now()
    });
}

// Add a place to user's favorites
exports.addToFavorites = async (req, res) => {
    try {
        const { placeId } = req.body;
        const userId = req.user.id;

        // Check if place exists
        const place = await Place.findById(placeId);
        if (!place) {
            return res.status(404).json({ 
                message: 'Place not found',
                timestamp: Date.now()
            });
        }

        // Find user and check if place is already in favorites
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ 
                message: 'User not found',
                timestamp: Date.now()
            });
        }

        if (user.favorites.includes(placeId)) {
            return res.status(400).json({ 
                message: 'Place already in favorites',
                timestamp: Date.now()
            });
        }

        // Add place to favorites
        user.favorites.push(placeId);
        await user.save();

        // Invalidate cache for this user
        invalidateUserFavoritesCache(userId);
        
        console.log(`❤️ Place added to favorites: ${place.name_eng || place.name} for user: ${userId}`);

        res.status(200).json({ 
            message: 'Place added to favorites successfully',
            favorites: user.favorites,
            addedPlace: place.name_eng || place.name,
            timestamp: Date.now()
        });
    } catch (error) {
        console.error('❌ Error adding to favorites:', error);
        res.status(500).json({ 
            message: 'Failed to add to favorites',
            error: error.message,
            timestamp: Date.now()
        });
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
            return res.status(404).json({ 
                message: 'User not found',
                timestamp: Date.now()
            });
        }

        // Check if place is in favorites
        if (!user.favorites.includes(placeId)) {
            return res.status(400).json({ 
                message: 'Place not in favorites',
                timestamp: Date.now()
            });
        }

        // Get place name for logging
        const place = await Place.findById(placeId);
        const placeName = place ? (place.name_eng || place.name) : placeId;

        // Remove place from favorites
        user.favorites = user.favorites.filter(id => id.toString() !== placeId);
        await user.save();

        // Invalidate cache for this user
        invalidateUserFavoritesCache(userId);
        
        console.log(`💔 Place removed from favorites: ${placeName} for user: ${userId}`);

        res.status(200).json({ 
            message: 'Place removed from favorites successfully',
            favorites: user.favorites,
            removedPlace: placeName,
            timestamp: Date.now()
        });
    } catch (error) {
        console.error('❌ Error removing from favorites:', error);
        res.status(500).json({ 
            message: 'Failed to remove from favorites',
            error: error.message,
            timestamp: Date.now()
        });
    }
};

// Get user's favorite places with caching
exports.getFavorites = async (req, res) => {
    try {
        const userId = req.user.id;

        // Check cache first
        const cachedFavorites = getCachedFavorites(userId);
        if (cachedFavorites) {
            return res.status(200).json({ 
                favorites: cachedFavorites,
                count: cachedFavorites.length,
                cached: true,
                version: favoritesCache.dataVersion,
                timestamp: Date.now()
            });
        }

        // Find user and populate favorites with place details
        const user = await User.findById(userId).populate({
            path: 'favorites',
            model: 'Place'
        }).lean(); // .lean() for better performance

        if (!user) {
            return res.status(404).json({ 
                message: 'User not found',
                timestamp: Date.now()
            });
        }

        // Cache the favorites
        setCachedFavorites(userId, user.favorites);
        
        console.log(`📊 Loaded ${user.favorites.length} favorites for user: ${userId}`);

        res.status(200).json({ 
            favorites: user.favorites,
            count: user.favorites.length,
            cached: false,
            version: favoritesCache.dataVersion,
            timestamp: Date.now()
        });
    } catch (error) {
        console.error('❌ Error loading favorites:', error);
        res.status(500).json({ 
            message: 'Failed to load favorites',
            error: error.message,
            timestamp: Date.now()
        });
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
            return res.status(404).json({ 
                message: 'Place not found',
                timestamp: Date.now()
            });
        }

        // Find user
        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ 
                message: 'User not found',
                timestamp: Date.now()
            });
        }

        const isFavorite = user.favorites.includes(placeId);
        const placeName = place.name_eng || place.name;
        
        if (isFavorite) {
            // Remove from favorites
            user.favorites = user.favorites.filter(id => id.toString() !== placeId);
            console.log(`💔 Toggled OFF: ${placeName} for user: ${userId}`);
        } else {
            // Add to favorites
            user.favorites.push(placeId);
            console.log(`❤️ Toggled ON: ${placeName} for user: ${userId}`);
        }

        await user.save();

        // Invalidate cache for this user
        invalidateUserFavoritesCache(userId);

        res.status(200).json({ 
            message: isFavorite ? 'Place removed from favorites' : 'Place added to favorites',
            isFavorite: !isFavorite,
            favorites: user.favorites,
            placeName: placeName,
            timestamp: Date.now()
        });
    } catch (error) {
        console.error('❌ Error toggling favorite:', error);
        res.status(500).json({ 
            message: 'Failed to toggle favorite',
            error: error.message,
            timestamp: Date.now()
        });
    }
};

// Get favorites cache statistics
exports.getFavoritesCacheStats = async (req, res) => {
    try {
        const stats = {
            cache: {
                totalCachedUsers: favoritesCache.userFavorites.size,
                dataVersion: favoritesCache.dataVersion,
                ttl: favoritesCache.cacheTTL,
                cacheDetails: []
            },
            timestamp: Date.now()
        };
        
        // Add details for each cached user (without exposing sensitive data)
        for (const [userId, data] of favoritesCache.userFavorites.entries()) {
            stats.cache.cacheDetails.push({
                userId: userId.substring(0, 8) + '...', // Partial ID for privacy
                favoritesCount: data.favorites.length,
                lastUpdated: data.lastUpdated,
                isValid: isFavoritesCacheValid(data.lastUpdated)
            });
        }
        
        res.json(stats);
    } catch (error) {
        console.error('❌ Error getting favorites cache stats:', error);
        res.status(500).json({ 
            message: 'Failed to get cache statistics',
            error: error.message,
            timestamp: Date.now()
        });
    }
};

// Clear favorites cache (admin only)
exports.clearFavoritesCache = async (req, res) => {
    try {
        const clearedUsers = favoritesCache.userFavorites.size;
        favoritesCache.userFavorites.clear();
        favoritesCache.dataVersion += 1;
        
        console.log(`🧹 Favorites cache cleared for ${clearedUsers} users`);
        
        res.json({ 
            message: 'Favorites cache cleared successfully',
            clearedUsers: clearedUsers,
            newVersion: favoritesCache.dataVersion,
            timestamp: Date.now()
        });
    } catch (error) {
        console.error('❌ Error clearing favorites cache:', error);
        res.status(500).json({ 
            message: 'Failed to clear cache',
            error: error.message,
            timestamp: Date.now()
        });
    }
};