const fs = require('fs');
const path = require('path');

// Create a simple colored rectangle image
function createSimpleImage(filename, placeName, color = '#4CAF50') {
    // Create a simple 200x150 colored rectangle as a data URL
    // This will be a base64 encoded PNG
    const width = 200;
    const height = 150;
    
    // Create a simple colored rectangle using canvas-like approach
    // For now, let's create a simple text file that describes the image
    const imageDescription = `Placeholder image for ${placeName}
Color: ${color}
Size: ${width}x${height}
This is a placeholder image that should be replaced with actual photos.`;

    const uploadsDir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(uploadsDir)) {
        fs.mkdirSync(uploadsDir, { recursive: true });
    }

    // For now, let's create a simple text file as placeholder
    const filePath = path.join(uploadsDir, filename);
    fs.writeFileSync(filePath, imageDescription);
    console.log(`   ✅ Created: ${filename} (text placeholder)`);
}

async function createSimpleImages() {
    try {
        const places = [
            { name: 'Lido Beach', filename: 'liido.jpg', color: '#2196F3' },
            { name: 'Abaaydhaxan', filename: 'abaaydhaxan.png', color: '#FF9800' },
            { name: 'Somali National Museum', filename: 'national_museum.jpg', color: '#9C27B0' },
            { name: 'Arba\'a Rukun Mosque', filename: 'arbaa_rukun.jpg', color: '#4CAF50' },
            { name: 'Laas Geel Cave Paintings', filename: 'laas_geel.jpg', color: '#795548' },
            { name: 'Hargeisa Cultural Center', filename: 'hargeisa_cultural.jpg', color: '#607D8B' },
            { name: 'Berbera Beach', filename: 'berbera_beach.jpg', color: '#00BCD4' },
            { name: 'Sheikh Sufi Mosque', filename: 'sheikh_sufi.jpg', color: '#8BC34A' },
            { name: 'Jowhara International Hotel', filename: 'jowhara_hotel.jpg', color: '#FF5722' },
            { name: 'Nimow', filename: 'nimow-2.png', color: '#E91E63' },
            { name: 'Warsheikh', filename: 'warshiikh.png', color: '#3F51B5' },
            { name: 'Beerta Nabada', filename: 'beerta-nabada.png', color: '#009688' },
            { name: 'Beerta Xamar', filename: 'beerta-xamar.png', color: '#FFC107' },
            { name: 'Beerta Banadir', filename: 'beerta-banadir.png', color: '#673AB7' },
            { name: 'Xeebta Jaziira', filename: 'jaziira.png', color: '#FFEB3B' },
            { name: 'Laydy Dayniile', filename: 'dayniile.png', color: '#CDDC39' }
        ];

        console.log('📸 Creating simple placeholder images...\n');

        for (const place of places) {
            createSimpleImage(place.filename, place.name, place.color);
        }

        console.log('\n📊 Summary:');
        console.log(`   - Created ${places.length} placeholder images`);
        console.log(`   - Images stored in uploads/ directory`);
        console.log(`   - Images accessible at http://localhost:9000/uploads/`);

        console.log('\n🔗 Test URLs:');
        places.slice(0, 3).forEach(place => {
            console.log(`   - ${place.name}: http://localhost:9000/uploads/${place.filename}`);
        });

        console.log('\n💡 Note: These are text placeholders. For real images, replace with actual photos.');

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

createSimpleImages();