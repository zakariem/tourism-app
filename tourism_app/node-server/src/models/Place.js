const mongoose = require('mongoose');

const PlaceSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        required: true
    },
    location: {
        type: String,
        required: true
    },
    images: [
        {
            url: {
                type: String,
                required: true
            },
            public_id: { // Useful if using cloud storage like Cloudinary
                type: String
            }
        }
    ],
    pricePerPerson: {
        type: Number,
        required: true,
        min: 0
    },
    maxCapacity: {
        type: Number,
        required: true,
        min: 1
    },
    availableDates: [
        {
            type: Date
        }
    ],
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Place', PlaceSchema);