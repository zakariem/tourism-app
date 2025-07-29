const mongoose = require('mongoose');
const Place = require('./src/models/Place');
require('dotenv').config();

// Generate a simple colored rectangle as base64 PNG
function generateBase64Image(placeName, color = '#4CAF50') {
    // Create a simple 200x150 colored rectangle
    const width = 200;
    const height = 150;
    
    // Create a canvas-like structure for the image
    const canvas = {
        width: width,
        height: height,
        data: new Uint8Array(width * height * 4) // RGBA
    };
    
    // Fill with the specified color
    const r = parseInt(color.slice(1, 3), 16);
    const g = parseInt(color.slice(3, 5), 16);
    const b = parseInt(color.slice(5, 7), 16);
    
    for (let i = 0; i < canvas.data.length; i += 4) {
        canvas.data[i] = r;     // Red
        canvas.data[i + 1] = g; // Green
        canvas.data[i + 2] = b; // Blue
        canvas.data[i + 3] = 255; // Alpha (opaque)
    }
    
    // For simplicity, let's create a data URL with a colored rectangle
    // This is a simplified approach - in production you'd use a proper image library
    const svgContent = `<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
        <rect width="${width}" height="${height}" fill="${color}"/>
        <text x="${width/2}" y="${height/2}" font-family="Arial, sans-serif" font-size="16" text-anchor="middle" fill="white">${placeName}</text>
        <text x="${width/2}" y="${height/2 + 20}" font-family="Arial, sans-serif" font-size="12" text-anchor="middle" fill="white">Tourist Place</text>
    </svg>`;
    
    // Convert SVG to base64
    const base64 = Buffer.from(svgContent).toString('base64');
    return `data:image/svg+xml;base64,${base64}`;
}

async function addImagesToMongoDB() {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/tourism_app');
        console.log('✅ Connected to MongoDB\n');

        const places = await Place.find({});
        console.log(`📸 Adding images to ${places.length} places...\n`);

        for (const place of places) {
            // Generate a unique color for each category
            const colors = {
                'beach': '#2196F3',
                'historical': '#FF9800',
                'cultural': '#9C27B0',
                'religious': '#4CAF50',
                'suburb': '#607D8B',
                'urban park': '#00BCD4'
            };
            
            const color = colors[place.category] || '#4CAF50';
            const imageData = generateBase64Image(place.name_eng, color);
            
            // Update the place with image data
            await Place.findByIdAndUpdate(place._id, {
                image_data: imageData
            });
            
            console.log(`   ✅ Added image for: ${place.name_eng} (${place.category})`);
        }

        console.log('\n📊 Summary:');
        console.log(`   - Updated ${places.length} places with image data`);
        console.log(`   - Images stored as base64 in MongoDB`);
        console.log(`   - Images accessible via image_data field`);

        // Show sample data
        const samplePlace = await Place.findOne({});
        if (samplePlace) {
            console.log('\n📄 Sample place with image data:');
            console.log(`   Name: ${samplePlace.name_eng}`);
            console.log(`   Category: ${samplePlace.category}`);
            console.log(`   Image data length: ${samplePlace.image_data ? samplePlace.image_data.length : 0} characters`);
        }

        mongoose.connection.close();
        console.log('\n✅ Database connection closed');

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

addImagesToMongoDB();