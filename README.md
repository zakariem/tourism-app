# 🏛️ Somalia Tourism System

A comprehensive tourism guide ecosystem for Somalia, featuring a Flutter mobile app, Node.js backend API, Python-powered AI chat service, and a modern admin dashboard for content management.

## 🏗️ System Architecture

This project consists of four main components:

1. **📱 Flutter Mobile App** (`/tourism_app`): Cross-platform mobile application with offline support
2. **🚀 Node.js Backend API** (`/tourism_app/node-server`): RESTful API with MongoDB for data management
3. **🤖 Python Chat Backend** (`/tourism_app/backend`): AI-powered chat service with multi-provider support
4. **💻 Admin Dashboard** (`/somalia-tourism-dashboard`): Next.js web interface for content management

## ✨ Key Features

### 📱 Mobile App Features
- **🗺️ Tourist Place Discovery**: Browse and explore Somalia's attractions by category
- **🌍 Multi-language Support**: Full English and Somali localization
- **👤 User Authentication**: Secure registration, login, and profile management
- **❤️ Favorites Management**: Save and organize favorite destinations
- **💬 AI Chat Assistant**: Intelligent tourism guidance with multiple AI providers
- **📱 Offline Support**: Local SQLite database for core functionality
- **🎯 Smart Recommendations**: ML-powered personalized suggestions (planned)

### 🔧 Backend Features
- **📊 RESTful API**: Complete CRUD operations for places, users, and bookings
- **🖼️ Image Management**: Upload, storage, and serving of place images
- **🔐 JWT Authentication**: Secure token-based authentication system
- **💳 Payment Integration**: Hormuud payment gateway support
- **📈 Analytics**: User behavior tracking and insights

### 🤖 AI Chat Features
- **🧠 Multi-AI Support**: Google Gemini, OpenAI GPT, and Anthropic Claude
- **🌐 Bilingual Chat**: Intelligent responses in English and Somali
- **🎯 Context-Aware**: Tourism-focused responses with local knowledge
- **⚡ Fallback System**: Graceful degradation when AI services are unavailable

### 💼 Admin Dashboard Features
- **📝 Content Management**: Add, edit, and delete tourist places
- **👥 User Management**: Monitor and manage user accounts
- **📊 Analytics Dashboard**: View usage statistics and insights
- **🖼️ Media Management**: Upload and organize place images
- **🎨 Modern UI**: Built with Next.js, Tailwind CSS, and shadcn/ui

## 🛠️ Technology Stack

### Frontend
- **Mobile**: Flutter 3.x, Dart, Provider state management
- **Admin**: Next.js 14, React, TypeScript, Tailwind CSS, shadcn/ui

### Backend
- **API Server**: Node.js, Express.js, MongoDB, Mongoose
- **Chat Service**: Python, Flask, AI APIs (Gemini, OpenAI, Claude)
- **Authentication**: JWT tokens, bcrypt password hashing
- **File Storage**: Multer for image uploads

### Database
- **Production**: MongoDB (Node.js backend)
- **Local**: SQLite (Flutter app offline storage)

### AI & ML
- **Chat AI**: Google Gemini, OpenAI GPT-4, Anthropic Claude
- **Recommendations**: TensorFlow Lite (planned implementation)

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ and npm/yarn
- Python 3.8+
- Flutter SDK 3.x
- MongoDB (local or cloud)
- AI API keys (optional, for chat features)

### 1. Clone Repository
```bash
git clone <repository-url>
cd tourism-app
```

### 2. Setup Node.js Backend
```bash
cd tourism_app/node-server
npm install

# Start MongoDB and seed database
npm run seed
npm start
# Server runs on http://localhost:9000
```

### 3. Setup Python Chat Backend
```bash
cd tourism_app/backend
pip install -r requirements.txt

# Configure AI API keys in .env file
cp env_example.txt .env
# Edit .env with your API keys

python main.py
# Chat service runs on http://localhost:5000
```

### 4. Setup Flutter Mobile App
```bash
cd tourism_app
flutter pub get
flutter run
# Choose your target device (Android/iOS/Web)
```

### 5. Setup Admin Dashboard
```bash
cd somalia-tourism-dashboard
npm install
npm run dev
# Dashboard runs on http://localhost:3000
```

## 📁 Project Structure

```
tourism-app/
├── 📱 tourism_app/                    # Flutter Mobile App
│   ├── lib/
│   │   ├── models/                    # Data models
│   │   ├── providers/                 # State management
│   │   ├── screens/                   # UI screens
│   │   ├── services/                  # API & database services
│   │   ├── utils/                     # Utilities & constants
│   │   └── widgets/                   # Reusable UI components
│   ├── assets/                        # Images, icons, ML models
│   ├── android/                       # Android configuration
│   ├── ios/                          # iOS configuration
│   ├── 🚀 node-server/               # Node.js Backend API
│   │   ├── src/
│   │   │   ├── controllers/           # Route controllers
│   │   │   ├── models/               # MongoDB models
│   │   │   ├── routes/               # API routes
│   │   │   └── utils/                # Utilities
│   │   ├── uploads/                  # Image storage
│   │   └── server.js                 # Main server file
│   └── 🤖 backend/                   # Python Chat Backend
│       ├── main.py                   # Flask app
│       ├── api_config.py            # AI configuration
│       └── requirements.txt         # Python dependencies
├── 💻 somalia-tourism-dashboard/     # Next.js Admin Dashboard
│   ├── app/                         # Next.js app router
│   ├── components/                  # React components
│   ├── lib/                        # Utilities
│   └── public/                      # Static assets
└── README.md                        # This file
```

## 🔧 Configuration

### Environment Variables

#### Node.js Backend (.env)
```env
MONGO_URI=mongodb://localhost:27017/tourism_app
JWT_SECRET=your_jwt_secret_key
PORT=9000
```

#### Python Chat Backend (.env)
```env
GEMINI_API_KEY=your_gemini_api_key
OPENAI_API_KEY=your_openai_api_key
CLAUDE_API_KEY=your_claude_api_key
FLASK_ENV=development
PORT=5000
```

### Flutter Configuration
- Update API endpoints in `lib/providers/auth_provider.dart`
- Configure Android permissions in `android/app/src/main/AndroidManifest.xml`
- Add internet permission: `<uses-permission android:name="android.permission.INTERNET" />`

## 📊 API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/profile` - Update user profile

### Places Endpoints
- `GET /api/places` - Get all places
- `GET /api/places/category/:category` - Get places by category
- `GET /api/places/:id` - Get specific place
- `POST /api/places` - Create new place (Admin)
- `PUT /api/places/:id` - Update place (Admin)
- `DELETE /api/places/:id` - Delete place (Admin)

### Categories
- `beach` - Beach locations
- `historical` - Historical sites
- `cultural` - Cultural centers
- `religious` - Religious sites
- `suburb` - Suburban areas
- `urban park` - Urban parks

## 🚨 Troubleshooting

### Common Issues

#### Flutter App Crashes on Android
- **Missing Internet Permission**: Add `<uses-permission android:name="android.permission.INTERNET" />` to AndroidManifest.xml
- **Network Security**: Configure network security for HTTP traffic in production
- **Database Issues**: Check SQLite initialization in main.dart

#### Backend Connection Issues
- **MongoDB**: Ensure MongoDB is running and accessible
- **CORS**: Check CORS configuration for cross-origin requests
- **Port Conflicts**: Ensure ports 9000 (Node.js) and 5000 (Python) are available

#### Chat Service Issues
- **API Keys**: Verify AI API keys are correctly configured
- **Rate Limits**: Check API usage limits and quotas
- **Fallback**: App provides offline responses when AI services are unavailable

### Debug Commands
```bash
# Check Node.js backend health
curl http://localhost:9000/api/health

# Check Python chat backend
curl http://localhost:5000/health

# View MongoDB data
cd tourism_app/node-server
npm run show-data

# Flutter verbose logging
flutter run --verbose
```

## 🔮 Roadmap

### Phase 1 (Current)
- ✅ Core mobile app functionality
- ✅ Backend API with authentication
- ✅ AI chat integration
- ✅ Admin dashboard

### Phase 2 (Planned)
- 🔄 ML-powered recommendations
- 🔄 Real-time notifications
- 🔄 Social features (reviews, ratings)
- 🔄 Advanced analytics

### Phase 3 (Future)
- 📱 iOS App Store deployment
- 🌐 Web version of mobile app
- 🗺️ Interactive maps integration
- 💳 Enhanced payment options

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is for educational and demonstration purposes. All rights reserved.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- MongoDB for the database solution
- AI providers (Google, OpenAI, Anthropic) for chat capabilities
- shadcn/ui for beautiful UI components
- The open-source community for various packages and tools

---

**Built with ❤️ for Somalia's tourism industry**
