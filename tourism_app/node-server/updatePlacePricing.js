const mongoose = require('mongoose');
const Place = require('./src/models/Place');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tourism_app', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Update places with zero pricing to have default pricing
async function updatePlacePricing() {
  try {
    console.log('Updating places with zero pricing...');
    
    // Find all places with pricePerPerson of 0 or null
    const placesToUpdate = await Place.find({
      $or: [
        { pricePerPerson: 0 },
        { pricePerPerson: null },
        { pricePerPerson: { $exists: false } }
      ]
    });
    
    console.log(`Found ${placesToUpdate.length} places to update`);
    
    // Update each place with appropriate pricing based on category
    for (const place of placesToUpdate) {
      let newPrice = 5.0; // Default price
      
      // Set different prices based on category
      switch (place.category) {
        case 'beach':
          newPrice = 8.0;
          break;
        case 'historical':
          newPrice = 12.0;
          break;
        case 'cultural':
          newPrice = 10.0;
          break;
        case 'religious':
          newPrice = 5.0;
          break;
        case 'suburb':
          newPrice = 6.0;
          break;
        case 'urban park':
          newPrice = 7.0;
          break;
        default:
          newPrice = 5.0;
      }
      
      await Place.findByIdAndUpdate(place._id, {
        pricePerPerson: newPrice
      });
      
      console.log(`Updated ${place.name_eng}: $${newPrice} per person`);
    }
    
    console.log('✅ All places updated successfully!');
    
    // Display updated places
    const updatedPlaces = await Place.find({}, 'name_eng category pricePerPerson');
    console.log('\n📋 Current place pricing:');
    updatedPlaces.forEach(place => {
      console.log(`${place.name_eng} (${place.category}): $${place.pricePerPerson}`);
    });
    
  } catch (error) {
    console.error('❌ Error updating place pricing:', error);
  } finally {
    mongoose.connection.close();
  }
}

// Run the update
updatePlacePricing();