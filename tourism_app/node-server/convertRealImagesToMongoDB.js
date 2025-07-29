const mongoose = require('mongoose');
const Place = require('./src/models/Place');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

// Map of place names to their image files
const placeImageMap = {
  'Lido Beach': 'liido.jpg',
  'Abaaydhaxan': 'abaaydhaxan.png',
  'Somali National Museum': 'national_museum.jpg',
  'Arba\'a Rukun Mosque': 'arbaa_rukun.jpg',
  'Laas Geel Cave Paintings': 'laas_geel.jpg',
  'Hargeisa Cultural Center': 'hargeisa_cultural.jpg',
  'Berbera Beach': 'berbera_beach.jpg',
  'Sheikh Sufi Mosque': 'sheikh_sufi.jpg',
  // 'Jowhara International Hotel': 'jowhara_hotel.jpg', // This image doesn't exist
  'Nimow': 'nimow-2.png',
  'Warsheikh': 'warshiikh.png',
  'Beerta Nabada': 'beerta-nabada.png',
  'Beerta Xamar': 'beerta-xamar.png',
  'Beerta Banadir': 'beerta-banadir.png',
  'Xeebta Jaziira (Jaziira Beach)': 'jaziira.png',
  'Laydy Dayniile (Dayniile)': 'dayniile.png'
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

// Clean up uploads folder
function cleanupUploadsFolder() {
  const uploadsDir = path.join(__dirname, 'uploads');
  if (fs.existsSync(uploadsDir)) {
    const files = fs.readdirSync(uploadsDir);
    console.log(`🗑️ Cleaning up uploads folder (${files.length} files)...`);
    
    for (const file of files) {
      const filePath = path.join(uploadsDir, file);
      fs.unlinkSync(filePath);
      console.log(`   🗑️ Deleted: ${file}`);
    }
    
    // Remove the uploads directory
    fs.rmdirSync(uploadsDir);
    console.log('   🗑️ Removed uploads directory');
  } else {
    console.log('📁 Uploads folder not found, nothing to clean up');
  }
}

async function convertRealImagesToMongoDB() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/tourism_app');
    console.log('✅ Connected to MongoDB\n');

    const places = await Place.find({});
    console.log(`📸 Converting real images for ${places.length} places...\n`);

    let successCount = 0;
    let errorCount = 0;

    for (const place of places) {
      const imageFileName = placeImageMap[place.name_eng];
      
      if (imageFileName) {
        const base64Data = convertImageToBase64(imageFileName);
        
        if (base64Data) {
          // Update the place with real image data
          await Place.findByIdAndUpdate(place._id, {
            image_data: base64Data
          });
          
          console.log(`   ✅ Updated: ${place.name_eng} with ${imageFileName}`);
          successCount++;
        } else {
          console.log(`   ❌ Failed to convert: ${place.name_eng} (${imageFileName})`);
          errorCount++;
        }
      } else {
        console.log(`   ⚠️ No image mapping found for: ${place.name_eng}`);
        errorCount++;
      }
    }

    console.log('\n📊 Summary:');
    console.log(`   - Successfully updated: ${successCount} places`);
    console.log(`   - Failed to update: ${errorCount} places`);
    console.log(`   - Images stored as base64 in MongoDB`);
    console.log(`   - Images accessible via image_data field`);

    // Clean up uploads folder
    console.log('\n🧹 Cleaning up uploads folder...');
    cleanupUploadsFolder();

    // Show sample data
    const samplePlace = await Place.findOne({});
    if (samplePlace) {
      console.log('\n📄 Sample place with real image data:');
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

convertRealImagesToMongoDB();