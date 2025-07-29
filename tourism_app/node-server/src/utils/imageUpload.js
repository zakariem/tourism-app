const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

// Multer configuration for image uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadsDir);
    },
    filename: (req, file, cb) => {
        // Generate unique filename with timestamp and random number
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const extension = path.extname(file.originalname);
        cb(null, `place-${uniqueSuffix}${extension}`);
    }
});

// File filter to only allow images
const fileFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only JPEG, PNG, GIF, and WebP images are allowed.'), false);
    }
};

// Create multer instance with configuration
const upload = multer({ 
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    }
});

// Function to delete image file
const deleteImageFile = (imagePath) => {
    if (imagePath && imagePath.startsWith('/uploads/')) {
        const filePath = path.join(__dirname, '../..', imagePath);
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
            console.log(`Deleted image file: ${filePath}`);
        }
    }
};

// Function to validate image dimensions (optional)
const validateImageDimensions = (file) => {
    // This would require additional image processing library like sharp
    // For now, we'll just check file size
    return file.size <= 5 * 1024 * 1024; // 5MB
};

// Function to get image info
const getImageInfo = (file) => {
    return {
        originalName: file.originalname,
        filename: file.filename,
        size: file.size,
        mimetype: file.mimetype,
        path: `/uploads/${file.filename}`
    };
};

module.exports = {
    upload,
    deleteImageFile,
    validateImageDimensions,
    getImageInfo,
    uploadsDir
};