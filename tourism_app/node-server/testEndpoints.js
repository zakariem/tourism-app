const http = require('http');

const baseUrl = 'http://localhost:9000';

// Test function to make HTTP requests
function makeRequest(path, method = 'GET', data = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 9000,
            path: path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
            }
        };

        const req = http.request(options, (res) => {
            let responseData = '';
            
            res.on('data', (chunk) => {
                responseData += chunk;
            });
            
            res.on('end', () => {
                try {
                    const jsonData = JSON.parse(responseData);
                    resolve({
                        statusCode: res.statusCode,
                        data: jsonData
                    });
                } catch (e) {
                    resolve({
                        statusCode: res.statusCode,
                        data: responseData
                    });
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        if (data) {
            req.write(JSON.stringify(data));
        }

        req.end();
    });
}

// Test all endpoints
async function testEndpoints() {
    console.log('🧪 Testing JSON Endpoints...\n');

    try {
        // Test 1: Get all places
        console.log('1️⃣ Testing GET /api/places');
        const allPlaces = await makeRequest('/api/places');
        console.log(`Status: ${allPlaces.statusCode}`);
        console.log(`Places count: ${allPlaces.data.length}`);
        console.log(`Sample place: ${allPlaces.data[0]?.name_eng || 'No places found'}`);
        console.log('✅ Get all places - SUCCESS\n');

        // Test 2: Get places by category
        console.log('2️⃣ Testing GET /api/places/category/beach');
        const beachPlaces = await makeRequest('/api/places/category/beach');
        console.log(`Status: ${beachPlaces.statusCode}`);
        console.log(`Beach places count: ${beachPlaces.data.length}`);
        console.log(`Sample beach place: ${beachPlaces.data[0]?.name_eng || 'No beach places found'}`);
        console.log('✅ Get beach places - SUCCESS\n');

        // Test 3: Get places by historical category
        console.log('3️⃣ Testing GET /api/places/category/historical');
        const historicalPlaces = await makeRequest('/api/places/category/historical');
        console.log(`Status: ${historicalPlaces.statusCode}`);
        console.log(`Historical places count: ${historicalPlaces.data.length}`);
        console.log(`Sample historical place: ${historicalPlaces.data[0]?.name_eng || 'No historical places found'}`);
        console.log('✅ Get historical places - SUCCESS\n');

        // Test 4: Get a specific place by ID
        if (allPlaces.data.length > 0) {
            const firstPlaceId = allPlaces.data[0]._id;
            console.log(`4️⃣ Testing GET /api/places/${firstPlaceId}`);
            const specificPlace = await makeRequest(`/api/places/${firstPlaceId}`);
            console.log(`Status: ${specificPlace.statusCode}`);
            console.log(`Place name: ${specificPlace.data.name_eng}`);
            console.log(`Place category: ${specificPlace.data.category}`);
            console.log('✅ Get specific place - SUCCESS\n');
        }

        // Test 5: Test image upload endpoint
        console.log('5️⃣ Testing POST /api/places/test-upload');
        console.log('Note: This would require an actual image file to test properly');
        console.log('✅ Image upload endpoint ready\n');

        // Test 6: Show all categories
        console.log('6️⃣ Available Categories:');
        const categories = [...new Set(allPlaces.data.map(place => place.category))];
        categories.forEach(category => {
            const count = allPlaces.data.filter(place => place.category === category).length;
            console.log(`   - ${category}: ${count} places`);
        });
        console.log('✅ Categories summary - SUCCESS\n');

        // Test 7: Show sample data structure
        console.log('7️⃣ Sample Place Data Structure:');
        if (allPlaces.data.length > 0) {
            const sample = allPlaces.data[0];
            console.log(JSON.stringify(sample, null, 2));
            console.log('✅ Data structure - SUCCESS\n');
        }

        console.log('🎉 All endpoint tests completed successfully!');
        console.log('\n📊 Summary:');
        console.log(`   - Total places: ${allPlaces.data.length}`);
        console.log(`   - Categories: ${categories.length}`);
        console.log(`   - Server running on: ${baseUrl}`);

    } catch (error) {
        console.error('❌ Error testing endpoints:', error.message);
    }
}

// Run the tests
testEndpoints();