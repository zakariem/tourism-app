# Tourism App Node.js Server

This server provides the backend API for the Tourism App Flutter application.

## Setup Instructions

### 1. Install Dependencies
```bash
npm install
```

### 2. Set up MongoDB
Make sure MongoDB is running on your system. The server will connect to `mongodb://localhost:27017/tourism_app` by default.

### 3. Seed the Database
Run the seeder to populate the database with tourist places data:
```bash
npm run seed
```

### 4. Start the Server
```bash
npm start
```

The server will run on `http://localhost:9000`

## API Endpoints

### Places
- `GET /api/places` - Get all tourist places
- `GET /api/places/category/:category` - Get places by category
- `GET /api/places/:id` - Get a specific place by ID
- `POST /api/places` - Add a new place (Admin only, with image upload)
- `PUT /api/places/:id` - Update a place (Admin only, with image upload)
- `DELETE /api/places/:id` - Delete a place (Admin only)

### Image Upload
- `POST /api/places/test-upload` - Test image upload (for development)

### Categories Available
- `beach` - Beach locations
- `historical` - Historical sites
- `cultural` - Cultural centers
- `religious` - Religious sites
- `suburb` - Suburban areas
- `urban park` - Urban parks

## Database Schema

The Place model includes:
- `name_eng` - English name
- `name_som` - Somali name
- `desc_eng` - English description
- `desc_som` - Somali description
- `location` - Location string
- `category` - Category (enum)
- `image_path` - Image filename
- `pricePerPerson` - Optional pricing
- `maxCapacity` - Optional capacity
- `availableDates` - Optional available dates

## Image Upload Features

### Supported Formats
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)

### File Limits
- Maximum file size: 5MB
- Maximum files per upload: 5
- Automatic file renaming with timestamps
- File type validation

### Upload Directory
Images are stored in the `uploads/` directory and served statically at `/uploads/` path.

## Testing the API

You can test the API endpoints using curl or a tool like Postman:

```bash
# Get all places
curl http://localhost:9000/api/places

# Get places by category
curl http://localhost:9000/api/places/category/beach

# Test image upload
curl -X POST -F "image=@/path/to/your/image.jpg" http://localhost:9000/api/places/test-upload

# Add a new place with image (requires authentication)
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "name_eng=Lido Beach" \
  -F "name_som=Xeebta Liido" \
  -F "desc_eng=Beautiful beach in Mogadishu" \
  -F "desc_som=Xeeb quruxsan oo ku yaal Muqdisho" \
  -F "location=Mogadishu, Somalia" \
  -F "category=beach" \
  -F "image=@/path/to/beach-image.jpg" \
  http://localhost:9000/api/places
```

## File Structure

```
node-server/
├── src/
│   ├── controllers/
│   │   └── placeController.js
│   ├── routes/
│   │   └── placeRoutes.js
│   ├── utils/
│   │   └── imageUpload.js
│   └── models/
│       └── Place.js
├── uploads/          # Image upload directory
├── seedPlaces.js     # Database seeder
└── server.js         # Main server file
```