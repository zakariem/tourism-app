const fs = require('fs');
const path = require('path');

// Test script to verify image upload functionality
console.log('🧪 Testing Image Upload Configuration...\n');

// Check if uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (fs.existsSync(uploadsDir)) {
    console.log('✅ Uploads directory exists');
    
    // List files in uploads directory
    const files = fs.readdirSync(uploadsDir);
    console.log(`📁 Found ${files.length} files in uploads directory`);
    
    if (files.length > 0) {
        console.log('📋 Files in uploads directory:');
        files.forEach(file => {
            const filePath = path.join(uploadsDir, file);
            const stats = fs.statSync(filePath);
            console.log(`  - ${file} (${(stats.size / 1024).toFixed(2)} KB)`);
        });
    }
} else {
    console.log('❌ Uploads directory does not exist');
    console.log('💡 The directory will be created automatically when the server starts');
}

// Test multer configuration
try {
    const { upload } = require('./src/utils/imageUpload');
    console.log('\n✅ Multer configuration loaded successfully');
    console.log('✅ Image upload utility is ready');
} catch (error) {
    console.log('\n❌ Error loading multer configuration:', error.message);
}

console.log('\n🚀 To test image upload:');
console.log('1. Start the server: npm start');
console.log('2. Test upload endpoint:');
console.log('   curl -X POST -F "image=@/path/to/test-image.jpg" http://localhost:9000/api/places/test-upload');
console.log('\n📝 Supported image formats: JPEG, PNG, GIF, WebP');
console.log('📏 Maximum file size: 5MB');