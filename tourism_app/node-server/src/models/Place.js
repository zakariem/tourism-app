const mongoose = require('mongoose');

const PlaceSchema = new mongoose.Schema({
    name_eng: { type: String, required: true, trim: true },
    name_som: { type: String, required: true, trim: true },
    desc_eng: { type: String, required: true },
    desc_som: { type: String, required: true },
    location: { type: String, required: true },
    category: {
        type: String,
        required: true,
        enum: ['beach', 'historical', 'cultural', 'religious', 'suburb', 'urban park']
    },
    image_path: { type: String, required: true },
    image_data: { type: String }, // Base64 encoded image data
    pricePerPerson: { type: Number, min: 0, default: 5.0 }, // Default $5 per person
    maxCapacity: { type: Number, min: 1, default: 10 },
    availableDates: [{ type: Date }],
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Place', PlaceSchema);