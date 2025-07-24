const express = require('express');
const multer = require('multer');
const path = require('path');
const { addPlace, getAllPlaces, getPlaceById, updatePlace, deletePlace } = require('../controllers/placeController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const router = express.Router();

// Multer setup for image uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/'); // Make sure this directory exists
    },
    filename: (req, file, cb) => {
        cb(null, `${Date.now()}-${file.originalname}`);
    }
});

const upload = multer({ storage });

// Admin routes
router.post('/', protect, authorizeRoles('admin'), upload.array('images', 5), addPlace); // Allow up to 5 images
router.put('/:id', protect, authorizeRoles('admin'), upload.array('images', 5), updatePlace);
router.delete('/:id', protect, authorizeRoles('admin'), deletePlace);

// Public routes (or for both roles)
router.get('/', getAllPlaces);
router.get('/:id', getPlaceById);

module.exports = router;