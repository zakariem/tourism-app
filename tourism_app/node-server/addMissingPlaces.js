const mongoose = require('mongoose');
const Place = require('./src/models/Place');
require('dotenv').config();

const missingPlaces = [
  {
    name_eng: 'Beerta Darusalam',
    name_som: 'Beerta Darusalam',
    desc_eng: 'A beautiful park in Mogadishu known for its peaceful atmosphere and green spaces.',
    desc_som: 'Beerta Darusalam waxay ku taallaa Muqdisho, waxay ka mid tahay meelaha aadka loo booqdo.',
    location: 'Mogadishu, Somalia',
    category: 'urban park',
    image_path: 'beerta-darusalam.png',
    pricePerPerson: 0,
    maxCapacity: 50,
    availableDates: []
  },
  {
    name_eng: 'Jimcale',
    name_som: 'Jimcale',
    desc_eng: 'A historic district in Mogadishu with rich cultural heritage and traditional architecture.',
    desc_som: 'Jimcale waa degmo taariikhi ah oo ku taallaa Muqdisho, waxay leedahay dhaqan iyo qaab dhismeedkii hore.',
    location: 'Mogadishu, Somalia',
    category: 'cultural',
    image_path: 'jimcale-1.png',
    pricePerPerson: 0,
    maxCapacity: 30,
    availableDates: []
  }
];

async function addMissingPlaces() {
  try {
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/tourism_app');
    console.log('✅ Connected to MongoDB\n');

    console.log('📝 Adding missing places to database...\n');

    for (const placeData of missingPlaces) {
      // Check if place already exists
      const existingPlace = await Place.findOne({ name_eng: placeData.name_eng });
      
      if (existingPlace) {
        console.log(`   ⚠️ Place already exists: ${placeData.name_eng}`);
        continue;
      }

      // Create new place
      const newPlace = new Place(placeData);
      await newPlace.save();
      
      console.log(`   ✅ Added: ${placeData.name_eng}`);
    }

    // Show updated places count
    const totalPlaces = await Place.countDocuments();
    console.log(`\n📊 Total places in database: ${totalPlaces}`);

    // Show all places
    const allPlaces = await Place.find({}, 'name_eng category');
    console.log('\n📋 All places in database:');
    allPlaces.forEach(place => {
      console.log(`   🏛️ ${place.name_eng} (${place.category})`);
    });

    mongoose.connection.close();
    console.log('\n✅ Database connection closed');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

addMissingPlaces();