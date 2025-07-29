const Place = require('../models/Place');
const { deleteImageFile } = require('../utils/imageUpload');

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
        res.status(201).json(createdPlace);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get all places (for both tourist and admin)
exports.getAllPlaces = async (req, res) => {
    try {
        const places = await Place.find({});
        res.json(places);
    } catch (error) {
        res.status(500).json({ message: error.message });
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
            res.json(updatedPlace);
        } else {
            res.status(404).json({ message: 'Place not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
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
            res.json({ message: 'Place removed' });
        } else {
            res.status(404).json({ message: 'Place not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};