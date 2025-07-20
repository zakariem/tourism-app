# Tourism App Chat Backend

This is a Python Flask backend that provides chat functionality for the Tourism App using OpenAI API.

## Setup Instructions

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Set up Environment Variables

Create a `.env` file in the backend directory:

```bash
cp env_example.txt .env
```

Edit the `.env` file and add your OpenAI API key:

```
OPENAI_API_KEY=your_actual_openai_api_key_here
FLASK_ENV=development
PORT=5000
```

### 3. Get OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key and paste it in your `.env` file

### 4. Run the Backend

```bash
python app.py
```

The server will start on `http://localhost:5000`

## API Endpoints

### Health Check
- **GET** `/health`
- Returns server status

### Chat
- **POST** `/chat`
- Request body: `{"message": "your message", "language": "en"}`
- Response: `{"response": "AI response", "status": "success"}`

### Streaming Chat
- **POST** `/chat/stream`
- Request body: `{"message": "your message", "language": "en"}`
- Response: Server-sent events stream

## Features

- ✅ OpenAI GPT-4 integration
- ✅ Bilingual support (English and Somali)
- ✅ Tourism-focused responses
- ✅ Error handling
- ✅ CORS enabled for Flutter app
- ✅ Streaming responses (optional)

## Testing

You can test the API using curl:

```bash
curl -X POST http://localhost:5000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Tell me about beaches in Somalia", "language": "en"}'
``` 