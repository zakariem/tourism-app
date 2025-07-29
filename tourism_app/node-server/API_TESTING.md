# API Testing Guide

## 🚀 Server Status
✅ **Server is running on:** `http://localhost:9000`  
✅ **Database:** MongoDB connected successfully  
✅ **Data:** 16 tourist places seeded  

## 📊 Database Summary
- **Total Places:** 16
- **Categories:** 6 (beach, historical, cultural, religious, urban park, suburb)
- **Database:** tourism_app
- **Collection:** places

## 🔗 Available JSON Endpoints

### 1. Get All Places
```bash
GET http://localhost:9000/api/places
```
**Response:** Array of all 16 places with full details

### 2. Get Places by Category
```bash
GET http://localhost:9000/api/places/category/{category}
```
**Available categories:**
- `beach` (4 places)
- `historical` (3 places) 
- `cultural` (4 places)
- `religious` (2 places)
- `urban park` (2 places)
- `suburb` (1 place)

### 3. Get Specific Place by ID
```bash
GET http://localhost:9000/api/places/{id}
```
**Response:** Single place object with full details

### 4. Test Image Upload
```bash
POST http://localhost:9000/api/places/test-upload
Content-Type: multipart/form-data
Body: image file
```

## 🧪 Testing Commands

### Quick Tests
```bash
# Test all endpoints
npm run test-endpoints

# Show MongoDB data
npm run show-data

# Test image upload config
npm run test-upload

# Seed database
npm run seed
```

### Manual Testing with curl
```bash
# Get all places
curl http://localhost:9000/api/places

# Get beach places
curl http://localhost:9000/api/places/category/beach

# Get specific place (replace ID)
curl http://localhost:9000/api/places/6888db3d1d62d7b6dac92dd0

# Test image upload
curl -X POST -F "image=@/path/to/image.jpg" http://localhost:9000/api/places/test-upload
```

## 📄 Sample JSON Response

### All Places Response
```json
[
  {
    "_id": "6888db3d1d62d7b6dac92dd0",
    "name_eng": "Lido Beach",
    "name_som": "Xeebta Liido",
    "desc_eng": "One of the most beautiful beaches in Mogadishu, perfect for swimming and relaxation.",
    "desc_som": "Mid ka mid ah xeebaha ugu quruxda badan Muqdisho, ku haboon dabaasha iyo nasashada.",
    "location": "Mogadishu, Somalia",
    "category": "beach",
    "image_path": "liido.jpg",
    "pricePerPerson": 0,
    "maxCapacity": 10,
    "availableDates": [],
    "createdAt": "2025-07-29T14:31:25.347Z",
    "__v": 0
  }
]
```

### Category Response
```json
[
  {
    "_id": "6888db3d1d62d7b6dac92dd0",
    "name_eng": "Lido Beach",
    "name_som": "Xeebta Liido",
    "category": "beach"
  }
]
```

## 🗂️ Places by Category

### Beach (4 places)
- Lido Beach
- Berbera Beach  
- Jowhara International Hotel
- Xeebta Jaziira (Jaziira Beach)

### Historical (3 places)
- Abaaydhaxan
- Laas Geel Cave Paintings
- Nimow

### Cultural (4 places)
- Somali National Museum
- Hargeisa Cultural Center
- Warsheikh
- Beerta Banadir

### Religious (2 places)
- Arba'a Rukun Mosque
- Sheikh Sufi Mosque

### Urban Park (2 places)
- Beerta Nabada
- Beerta Xamar

### Suburb (1 place)
- Laydy Dayniile (Dayniile)

## ✅ Test Results Summary

| Endpoint | Status | Places Count |
|----------|--------|--------------|
| GET /api/places | ✅ 200 | 16 |
| GET /api/places/category/beach | ✅ 200 | 4 |
| GET /api/places/category/historical | ✅ 200 | 3 |
| GET /api/places/{id} | ✅ 200 | 1 |
| POST /api/places/test-upload | ✅ Ready | - |

## 🔧 Flutter Integration

The Flutter app can now fetch data using:
```dart
// Get all places
final places = await PlacesService.getAllPlaces();

// Get places by category
final beachPlaces = await PlacesService.getPlacesByCategory('beach');

// Get specific place
final place = await PlacesService.getPlaceById('place_id');
```

## 🎯 Next Steps

1. **Test Flutter App** - Run the Flutter app to see places loading from the server
2. **Add Images** - Upload actual images for the places
3. **Admin Panel** - Create admin interface for managing places
4. **Authentication** - Add user authentication for admin features

---

**Server Status:** ✅ Running  
**Database:** ✅ Connected  
**Data:** ✅ 16 places loaded  
**Endpoints:** ✅ All working