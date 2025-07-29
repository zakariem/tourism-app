const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');
const { connectDB } = require('./src/config/connectDB');

// Load environment variables
dotenv.config();

const app = express();

// Connect to MongoDB
connectDB();

// Middleware
app.use(express.json()); // Body parser for JSON
app.use(cors()); // Enable CORS for all origins (adjust for production)

// Serve static files (for uploaded images)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', require('./src/routes/authRoutes'));
app.use('/api/places', require('./src/routes/placeRoutes'));
app.use('/api/bookings', require('./src/routes/bookingRoutes'));
app.use('/api/favorites', require('./src/routes/favoritesRoutes'));

// Basic route for testing
app.get('/', (req, res) => {
    res.send('Tourism App API is running...');
});

const PORT = process.env.PORT || 9000;

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));