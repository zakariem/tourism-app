const Place = require('../models/Place');
const { deleteImageFile } = require('../utils/imageUpload');

// Enhanced caching system for better performance
const cache = {
    allPlaces: null,
    placesByCategory: {},
    lastUpdated: 0,
    cacheTTL: 5 * 60 * 1000, // 5 minutes
    dataVersion: 0
};

// Helper function to check cache validity
function isCacheValid(timestamp) {
    return Date.now() - timestamp < cache.cacheTTL;
}

// Helper function to invalidate cache
function invalidateCache() {
    cache.allPlaces = null;
    cache.placesByCategory = {};
    cache.dataVersion += 1;
    console.log('🔄 Cache invalidated, version:', cache.dataVersion);
}

// Admin: Add a new place
exports.addPlace = async (req, res) => {
    const { 
        name_eng, 
        name_som, 
        desc_eng, 
        desc_som, 
        location, 
        category, 
        image_path,
        pricePerPerson, 
        maxCapacity, 
        availableDates 
    } = req.body;

    try {
        // Handle image upload if files are provided
        let finalImagePath = image_path;
        if (req.files && req.files.length > 0) {
            // Use the first uploaded image
            const uploadedImage = req.files[0];
            finalImagePath = `/uploads/${uploadedImage.filename}`;
        }

        const place = new Place({
            name_eng,
            name_som,
            desc_eng,
            desc_som,
            location,
            category,
            image_path: finalImagePath,
            pricePerPerson: pricePerPerson || 0,
            maxCapacity: maxCapacity || 10,
            availableDates: availableDates ? JSON.parse(availableDates) : []
        });

        const createdPlace = await place.save();
        
        // Invalidate cache when new place is added
        invalidateCache();
        
        console.log(`✅ New place added: ${createdPlace.name_eng}`);
        res.status(201).json({
            data: createdPlace,
            message: 'Place added successfully',
            timestamp: Date.now()
        });
    } catch (error) {
        console.error('❌ Error adding place:', error);
        res.status(500).json({ 
            message: 'Failed to add place',
            error: error.message,
            timestamp: Date.now()
        });
    }
};

// Get all places with caching (for both tourist and admin)
exports.getAllPlaces = async (req, res) => {
    try {
        // Check cache first
        if (cache.allPlaces && isCacheValid(cache.lastUpdated)) {
            return res.json({
                data: cache.allPlaces,
                cached: true,
                version: cache.dataVersion,
                timestamp: cache.lastUpdated
            });
        }

        // Load from database with optimized query
        const places = await Place.find({}).lean(); // .lean() for better performance
        
        // Update cache
        cache.allPlaces = places;
        cache.lastUpdated = Date.now();
        
        console.log(`📊 Loaded ${places.length} places from database`);
        
        res.json({
            data: places,
            cached: false,
            version: cache.dataVersion,
            timestamp: cache.lastUpdated,
            count: places.length
        });
    } catch (error) {
        console.error('❌ Error loading places:', error);
        res.status(500).json({ 
            message: 'Failed to load places',
            error: error.message,
            timestamp: Date.now()
        });
    }
};

// Get places by category
exports.getPlacesByCategory = async (req, res) => {
    try {
        const { category } = req.params;
        const places = await Place.find({ category });
        res.json(places);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get a single place by ID
exports.getPlaceById = async (req, res) => {
    try {
        const place = await Place.findById(req.params.id);
        if (place) {
            res.json(place);
        } else {
            res.status(404).json({ message: 'Place not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Admin: Update a place
exports.updatePlace = async (req, res) => {
    const { 
        name_eng, 
        name_som, 
        desc_eng, 
        desc_som, 
        location, 
        category, 
        image_path,
        pricePerPerson, 
        maxCapacity, 
        availableDates 
    } = req.body;

    try {
        const place = await Place.findById(req.params.id);

        if (place) {
            // Handle image upload if files are provided
            let finalImagePath = image_path || place.image_path;
            if (req.files && req.files.length > 0) {
                // Delete old image if it exists
                if (place.image_path && place.image_path !== finalImagePath) {
                    deleteImageFile(place.image_path);
                }
                // Use the first uploaded image
                const uploadedImage = req.files[0];
                finalImagePath = `/uploads/${uploadedImage.filename}`;
            }

            place.name_eng = name_eng || place.name_eng;
            place.name_som = name_som || place.name_som;
            place.desc_eng = desc_eng || place.desc_eng;
            place.desc_som = desc_som || place.desc_som;
            place.location = location || place.location;
            place.category = category || place.category;
            place.image_path = finalImagePath;
            place.pricePerPerson = pricePerPerson || place.pricePerPerson;
            place.maxCapacity = maxCapacity || place.maxCapacity;
            place.availableDates = availableDates ? JSON.parse(availableDates) : place.availableDates;

            const updatedPlace = await place.save();
            
            // Invalidate cache when place is updated
            invalidateCache();
            
            console.log(`🔄 Place updated: ${updatedPlace.name_eng}`);
            res.json({
                data: updatedPlace,
                message: 'Place updated successfully',
                timestamp: Date.now()
            });
        } else {
            res.status(404).json({ 
                message: 'Place not found',
                timestamp: Date.now()
            });
        }
    } catch (error) {
        console.error('❌ Error updating place:', error);
        res.status(500).json({ 
            message: 'Failed to update place',
            error: error.message,
            timestamp: Date.now()
        });
    }
};

// Admin: Delete a place
exports.deletePlace = async (req, res) => {
    try {
        const place = await Place.findById(req.params.id);

        if (place) {
            // Delete associated image file
            if (place.image_path) {
                deleteImageFile(place.image_path);
            }
            
            await place.deleteOne();
            
            // Invalidate cache when place is deleted
            invalidateCache();
            
            console.log(`🗑️ Place deleted: ${place.name_eng}`);
            res.json({ 
                message: 'Place deleted successfully',
                deletedPlace: place.name_eng,
                timestamp: Date.now()
            });
        } else {
            res.status(404).json({ 
                message: 'Place not found',
                timestamp: Date.now()
            });
        }
    } catch (error) {
        console.error('❌ Error deleting place:', error);
        res.status(500).json({ 
            message: 'Failed to delete place',
            error: error.message,
            timestamp: Date.now()
        });
    }
};

// Get cache statistics and data version
exports.getCacheStats = async (req, res) => {
    try {
        const stats = {
            cache: {
                isValid: cache.allPlaces && isCacheValid(cache.lastUpdated),
                lastUpdated: cache.lastUpdated,
                dataVersion: cache.dataVersion,
                placesCount: cache.allPlaces ? cache.allPlaces.length : 0,
                categoryCacheCount: Object.keys(cache.placesByCategory).length,
                ttl: cache.cacheTTL
            },
            database: {
                totalPlaces: await Place.countDocuments({})
            },
            timestamp: Date.now()
        };
        
        res.json(stats);
    } catch (error) {
        console.error('❌ Error getting cache stats:', error);
        res.status(500).json({ 
            message: 'Failed to get cache statistics',
            error: error.message,
            timestamp: Date.now()
        });
    }
};

// Clear cache manually (admin only)
exports.clearCache = async (req, res) => {
    try {
        invalidateCache();
        res.json({ 
            message: 'Cache cleared successfully',
            newVersion: cache.dataVersion,
            timestamp: Date.now()
        });
    } catch (error) {
        console.error('❌ Error clearing cache:', error);
        res.status(500).json({ 
            message: 'Failed to clear cache',
            error: error.message,
            timestamp: Date.now()
        });
    }
};