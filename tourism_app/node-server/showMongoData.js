const mongoose = require('mongoose');
const Place = require('./src/models/Place');
require('dotenv').config();

async function showMongoData() {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/tourism_app');
        console.log('✅ Connected to MongoDB\n');

        // Get all places
        const places = await Place.find({});
        console.log(`📊 Total places in database: ${places.length}\n`);

        // Show places by category
        const categories = await Place.aggregate([
            {
                $group: {
                    _id: '$category',
                    count: { $sum: 1 },
                    places: { $push: '$name_eng' }
                }
            },
            { $sort: { count: -1 } }
        ]);

        console.log('📋 Places by Category:');
        categories.forEach(cat => {
            console.log(`\n   ${cat._id.toUpperCase()} (${cat.count} places):`);
            cat.places.forEach(place => {
                console.log(`     - ${place}`);
            });
        });

        // Show sample place with full details
        if (places.length > 0) {
            console.log('\n📄 Sample Place (Full Details):');
            const samplePlace = places[0];
            console.log(JSON.stringify(samplePlace.toObject(), null, 2));
        }

        // Show database statistics
        console.log('\n📈 Database Statistics:');
        console.log(`   - Total places: ${places.length}`);
        console.log(`   - Categories: ${categories.length}`);
        console.log(`   - Database: tourism_app`);
        console.log(`   - Collection: places`);

        // Show recent places
        const recentPlaces = await Place.find({})
            .sort({ createdAt: -1 })
            .limit(5)
            .select('name_eng category createdAt');

        console.log('\n🕒 Recent Places:');
        recentPlaces.forEach((place, index) => {
            console.log(`   ${index + 1}. ${place.name_eng} (${place.category}) - ${new Date(place.createdAt).toLocaleDateString()}`);
        });

        mongoose.connection.close();
        console.log('\n✅ Database connection closed');

    } catch (error) {
        console.error('❌ Error:', error.message);
        process.exit(1);
    }
}

showMongoData();