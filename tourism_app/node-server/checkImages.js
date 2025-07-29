const mongoose = require('mongoose');
const Place = require('./src/models/Place');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function checkImages() {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/tourism_app');
        console.log('✅ Connected to MongoDB\n');

        const places = await Place.find({}).select('name_eng image_path');
        
        console.log('📸 Current Image Paths in Database:');
        places.forEach(place => {
            console.log(`   ${place.name_eng}: ${place.image_path}`);
        });

        console.log('\n🔍 Checking uploads directory...');
        const uploadsDir = path.join(__dirname, 'uploads');
        
        if (fs.existsSync(uploadsDir)) {
            const files = fs.readdirSync(uploadsDir);
            console.log(`   Uploads directory exists with ${files.length} files`);
            if (files.length > 0) {
                files.forEach(file => console.log(`     - ${file}`));
            }
        } else {
            console.log('   Uploads directory does not exist');
        }

        console.log('\n💡 Solutions:');
        console.log('1. Add actual image files to uploads/ directory');
        console.log('2. Update database with correct image paths');
        console.log('3. Use placeholder images for testing');

        mongoose.connection.close();
    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

checkImages();