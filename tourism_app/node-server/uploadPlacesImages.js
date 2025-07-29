const mongoose = require('mongoose');
const Place = require('./src/models/Place');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Map of image files to place names (based on the existing places in the database)
const imageToPlaceMap = {
  'liido.jpg': 'Lido Beach',
  'liido2.png': 'Lido Beach',
  'liido3.png': 'Lido Beach', 
  'liido4.png': 'Lido Beach',
  'abaaydhaxan.png': 'Abaaydhaxan',
  'national_museum.jpg': 'Somali National Museum',
  'arbaa_rukun.jpg': 'Arba\'a Rukun Mosque',
  'laas_geel.jpg': 'Laas Geel Cave Paintings',
  'hargeisa_cultural.jpg': 'Hargeisa Cultural Center',
  'berbera_beach.jpg': 'Berbera Beach',
  'sheikh_sufi.jpg': 'Sheikh Sufi Mosque',
  'nimow.png': 'Nimow',
  'nimow-2.png': 'Nimow',
  'warshiikh.png': 'Warsheikh',
  'warshiikh-2.png': 'Warsheikh',
  'beerta-nabada.png': 'Beerta Nabada',
  'beerta-xamar.png': 'Beerta Xamar',
  'beerta-banadir.png': 'Beerta Banadir',
  'beerta-darusalam.png': 'Beerta Darusalam',
  'jaziira.png': 'Xeebta Jaziira (Jaziira Beach)',
  'jaziira-2.png': 'Xeebta Jaziira (Jaziira Beach)',
  'dayniile.png': 'Laydy Dayniile (Dayniile)',
  'jimcale-1.png': 'Jimcale',
  'jimcale-2.png': 'Jimcale',
  'jimcale-3.png': 'Jimcale'
};

// Convert image file to base64
function convertImageToBase64(imagePath) {
  try {
    const fullPath = path.join(__dirname, '../assets/places', imagePath);
    if (fs.existsSync(fullPath)) {
      const imageBuffer = fs.readFileSync(fullPath);
      const base64 = imageBuffer.toString('base64');
      
      // Determine MIME type based on file extension
      const ext = path.extname(imagePath).toLowerCase();
      let mimeType = 'image/jpeg'; // default
      if (ext === '.png') mimeType = 'image/png';
      else if (ext === '.jpg' || ext === '.jpeg') mimeType = 'image/jpeg';
      else if (ext === '.gif') mimeType = 'image/gif';
      else if (ext === '.webp') mimeType = 'image/webp';
      
      return `data:${mimeType};base64,${base64}`;
    } else {
      console.log(`⚠️ Image file not found: ${fullPath}`);
      return null;
    }
  } catch (error) {
    console.log(`❌ Error converting image ${imagePath}: ${error.message}`);
    return null;
  }
}

// Get all image files from the places folder
function getAllImageFiles() {
  const placesDir = path.join(__dirname, '../assets/places');
  if (!fs.existsSync(placesDir)) {
    console.log(`❌ Places directory not found: ${placesDir}`);
    return [];
  }
  
  const files = fs.readdirSync(placesDir);
  return files.filter(file => {
    const ext = path.extname(file).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
  });
}

async function uploadPlacesImages() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/tourism_app');
    console.log('✅ Connected to MongoDB\n');

    const imageFiles = getAllImageFiles();
    console.log(`📸 Found ${imageFiles.length} image files in places folder:\n`);
    imageFiles.forEach(file => console.log(`   📁 ${file}`));
    console.log();

    let successCount = 0;
    let errorCount = 0;
    let skippedCount = 0;

    // First, let's see what places exist in the database
    const existingPlaces = await Place.find({});
    console.log(`📋 Found ${existingPlaces.length} places in database:\n`);
    existingPlaces.forEach(place => console.log(`   🏛️ ${place.name_eng}`));
    console.log();

    // Process each image file
    for (const imageFile of imageFiles) {
      const placeName = imageToPlaceMap[imageFile];
      
      if (placeName) {
        // Find the place in the database
        const place = await Place.findOne({ name_eng: placeName });
        
        if (place) {
          const base64Data = convertImageToBase64(imageFile);
          
          if (base64Data) {
            // Update the place with image data
            await Place.findByIdAndUpdate(place._id, {
              image_data: base64Data,
              image_path: imageFile // Also update the image_path
            });
            
            console.log(`   ✅ Updated: ${placeName} with ${imageFile}`);
            successCount++;
          } else {
            console.log(`   ❌ Failed to convert: ${placeName} (${imageFile})`);
            errorCount++;
          }
        } else {
          console.log(`   ⚠️ Place not found in database: ${placeName} (${imageFile})`);
          errorCount++;
        }
      } else {
        console.log(`   ⚠️ No mapping found for: ${imageFile}`);
        skippedCount++;
      }
    }

    console.log('\n📊 Summary:');
    console.log(`   - Successfully updated: ${successCount} places`);
    console.log(`   - Failed to update: ${errorCount} places`);
    console.log(`   - Skipped (no mapping): ${skippedCount} images`);
    console.log(`   - Total images processed: ${imageFiles.length}`);
    console.log(`   - Images stored as base64 in MongoDB`);
    console.log(`   - Images accessible via image_data field`);

    // Show sample data
    const samplePlace = await Place.findOne({ image_data: { $exists: true, $ne: null } });
    if (samplePlace) {
      console.log('\n📄 Sample place with image data:');
      console.log(`   Name: ${samplePlace.name_eng}`);
      console.log(`   Category: ${samplePlace.category}`);
      console.log(`   Image path: ${samplePlace.image_path}`);
      console.log(`   Image data length: ${samplePlace.image_data ? samplePlace.image_data.length : 0} characters`);
    }

    mongoose.connection.close();
    console.log('\n✅ Database connection closed');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

uploadPlacesImages();