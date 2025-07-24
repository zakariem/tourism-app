const Place = require('../models/Place');

// Admin: Add a new place
exports.addPlace = async (req, res) => {
    const { name, description, location, pricePerPerson, maxCapacity, availableDates } = req.body;
    const images = req.files.map(file => ({ url: `/uploads/${file.filename}` })); // Assuming /uploads is your static folder

    try {
        const place = new Place({
            name,
            description,
            location,
            pricePerPerson,
            maxCapacity,
            availableDates: JSON.parse(availableDates), // Dates might come as a stringified array
            images
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
    const { name, description, location, pricePerPerson, maxCapacity, availableDates } = req.body;
    const newImages = req.files ? req.files.map(file => ({ url: `/uploads/${file.filename}` })) : [];

    try {
        const place = await Place.findById(req.params.id);

        if (place) {
            place.name = name || place.name;
            place.description = description || place.description;
            place.location = location || place.location;
            place.pricePerPerson = pricePerPerson || place.pricePerPerson;
            place.maxCapacity = maxCapacity || place.maxCapacity;
            place.availableDates = availableDates ? JSON.parse(availableDates) : place.availableDates;
            place.images = [...place.images, ...newImages]; // Append new images

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
            await place.deleteOne(); // Use deleteOne() instead of remove()
            res.json({ message: 'Place removed' });
        } else {
            res.status(404).json({ message: 'Place not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};