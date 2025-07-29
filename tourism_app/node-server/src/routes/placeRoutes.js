const express = require('express');
const { upload, deleteImageFile } = require('../utils/imageUpload');
const { addPlace, getAllPlaces, getPlaceById, updatePlace, deletePlace, getPlacesByCategory } = require('../controllers/placeController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const router = express.Router();

// Test endpoint for image upload (for development)
router.post('/test-upload', upload.single('image'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ message: 'No image file uploaded' });
        }
        
        res.json({
            message: 'Image uploaded successfully',
            file: {
                originalName: req.file.originalname,
                filename: req.file.filename,
                size: req.file.size,
                path: `/uploads/${req.file.filename}`
            }
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Admin routes with image upload
router.post('/', protect, authorizeRoles('admin'), upload.array('images', 5), addPlace); // Allow up to 5 images
router.put('/:id', protect, authorizeRoles('admin'), upload.array('images', 5), updatePlace);
router.delete('/:id', protect, authorizeRoles('admin'), deletePlace);

// Public routes (or for both roles)
router.get('/', getAllPlaces);
router.get('/category/:category', getPlacesByCategory);
router.get('/:id', getPlaceById);

// Error handling middleware for multer
router.use((error, req, res, next) => {
    if (error instanceof multer.MulterError) {
        if (error.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ message: 'File too large. Maximum size is 5MB.' });
        }
        if (error.code === 'LIMIT_FILE_COUNT') {
            return res.status(400).json({ message: 'Too many files. Maximum is 5 files.' });
        }
        return res.status(400).json({ message: error.message });
    }
    
    if (error.message.includes('Invalid file type')) {
        return res.status(400).json({ message: error.message });
    }
    
    next(error);
});

module.exports = router;