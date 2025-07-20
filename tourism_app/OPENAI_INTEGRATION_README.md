# Tourism App - OpenAI Chat Integration

This guide will help you set up OpenAI API integration for your Flutter tourism app's chat support feature.

## 🚀 Quick Setup

### 1. Install Python Dependencies

```bash
# Run the setup script
python setup_backend.py

# Or manually install dependencies
pip install flask flask-cors openai python-dotenv requests
```

### 2. Get OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key

### 3. Configure Environment

Edit `backend/.env` file and add your OpenAI API key:

```env
OPENAI_API_KEY=your_actual_openai_api_key_here
FLASK_ENV=development
PORT=5000
```

### 4. Start the Backend

```bash
cd backend
python app.py
```

The server will start on `http://localhost:5000`

### 5. Test the Backend

```bash
python test_backend.py
```

### 6. Run Your Flutter App

Your Flutter app is already configured to use the new backend. Just run:

```bash
flutter run
```

## 📁 Project Structure

```
tourism_app/
├── backend/                    # Python Flask backend
│   ├── app.py                 # Main Flask application
│   ├── requirements.txt       # Python dependencies
│   ├── README.md             # Backend documentation
│   └── .env                  # Environment variables (create this)
├── lib/
│   └── services/
│       └── chat_service.dart  # Updated to use Python backend
├── setup_backend.py          # Setup script
├── test_backend.py           # Test script
└── OPENAI_INTEGRATION_README.md  # This file
```

## 🔧 API Endpoints

### Health Check
- **GET** `/health`
- Returns server status

### Chat
- **POST** `/chat`
- Request: `{"message": "your message", "language": "en"}`
- Response: `{"response": "AI response", "status": "success"}`

### Streaming Chat (Optional)
- **POST** `/chat/stream`
- Request: `{"message": "your message", "language": "en"}`
- Response: Server-sent events stream

## 🌍 Language Support

The backend supports both English and Somali languages:

- **English**: `"language": "en"`
- **Somali**: `"language": "so"`

## 🎯 Features

- ✅ OpenAI GPT-4 integration
- ✅ Bilingual support (English and Somali)
- ✅ Tourism-focused responses
- ✅ Error handling and validation
- ✅ CORS enabled for Flutter app
- ✅ Health check endpoint
- ✅ Streaming responses (optional)
- ✅ Environment-based configuration

## 🔍 Testing

### Manual Testing with curl

```bash
# Health check
curl http://localhost:5000/health

# English chat
curl -X POST http://localhost:5000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Tell me about beaches in Somalia", "language": "en"}'

# Somali chat
curl -X POST http://localhost:5000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Maxaad iigu talin lahayd haddii aan jeclahay xeebaha?", "language": "so"}'
```

### Automated Testing

```bash
python test_backend.py
```

## 🛠️ Troubleshooting

### Backend won't start
- Check if Python 3.8+ is installed
- Verify all dependencies are installed: `pip install -r backend/requirements.txt`
- Ensure `.env` file exists and has valid OpenAI API key

### Connection errors in Flutter
- Make sure backend is running on `localhost:5000`
- Check if firewall is blocking the connection
- Verify CORS settings in backend

### OpenAI API errors
- Check if API key is valid and has credits
- Verify API key is correctly set in `.env` file
- Check OpenAI service status

### Flutter app errors
- Run `flutter clean && flutter pub get`
- Check if `http` package is in `pubspec.yaml`
- Verify network permissions in Android/iOS

## 🔒 Security Notes

- Never commit your `.env` file to version control
- Keep your OpenAI API key secure
- Consider rate limiting for production use
- Use HTTPS in production

## 📱 Flutter Integration

The Flutter app has been updated to use the new backend:

- `ChatService.sendMessage()` - Regular chat
- `ChatService.sendMessageStream()` - Streaming chat (optional)
- `ChatService.checkBackendHealth()` - Health check

## 🚀 Production Deployment

For production deployment:

1. Use a production WSGI server (Gunicorn, uWSGI)
2. Set up proper environment variables
3. Use HTTPS
4. Implement rate limiting
5. Add logging and monitoring
6. Consider using a reverse proxy (Nginx)

## 📞 Support

If you encounter issues:

1. Check the logs in the backend console
2. Run the test script: `python test_backend.py`
3. Verify your OpenAI API key and credits
4. Check network connectivity

## 🎉 Success!

Once everything is set up, your Flutter app will have a powerful AI-powered chat assistant that can help users with tourism information about Somalia in both English and Somali languages! 