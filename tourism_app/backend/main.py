#!/usr/bin/env python3
"""
Somalia Tourism Backend
Simple backend for basic health checks and legacy endpoints
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv
import json

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)














        

    

    

    

        

        

    

    

    

    



# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    """Simple health check"""
    return jsonify({
        'status': 'healthy', 
        'service': 'Somalia Tourism Backend',
        'timestamp': time.time()
    })

# Legacy chat endpoint (existing functionality)
def get_local_tourism_response(message, language):
    """Local tourism response without AI"""
    message_lower = message.lower()
    
    # Handle greetings
    if any(greeting in message_lower for greeting in ['hello', 'hi', 'salaam', 'hey']):
        if language == 'so':
            return "Salaam! Ku soo dhawoow kaaliyaha dalxiiska Soomaaliya. Sidee kuu caawin karaa?"
        else:
            return "Hello! Welcome to Somalia Tourism Assistant. How can I help you?"
    
    # Handle cost/price queries
    if any(word in message_lower for word in ['cost', 'price', 'expensive', 'cheap', 'budget']):
        if language == 'so':
            return "Qiimaha dalxiiska Soomaaliya: Xeebaha $3-12, Meelaha taariikhiga ah $5-25, Hoyga $15-200 habeen kasta."
        else:
            return "Somalia tourism costs: Beaches $3-12, Historical sites $5-25, Accommodation $15-200 per night."
    
    # Handle place recommendations
    if any(word in message_lower for word in ['place', 'visit', 'recommend', 'where', 'best']):
        places = random.sample(list(SOMALIA_TOURISM_DATA['places']['beaches'] + 
                                  SOMALIA_TOURISM_DATA['places']['historical']), 3)
        if language == 'so':
            response = "Meelaha aan kugula talinayo:\n"
            for place in places:
                response += f"• {place['name']} - {place['location']} ({place['cost']})\n"
        else:
            response = "I recommend these places:\n"
            for place in places:
                response += f"• {place['name']} - {place['location']} ({place['cost']})\n"
        return response
    
    # Default response
    if language == 'so':
        return "Waxaan kaa caawin karaa su'aalaha ku saabsan dalxiiska Soomaaliya. Wax ka weydiiso xeebaha, meelaha taariikhiga ah, qiimaha, ama wax kale!"
    else:
        return "I can help you with questions about Somalia tourism. Ask me about beaches, historical sites, costs, or anything else!"

@app.route('/chat', methods=['POST'])
def chat():
    """Legacy chat endpoint"""
    try:
        data = request.get_json()
        message = data.get('message', '')
        language = data.get('language', 'en')
        
        if not message:
            return jsonify({'error': 'Message is required'}), 400
        
        # Get local response
        response = get_local_tourism_response(message, language)
        
        return jsonify({
            'response': response,
            'language': language,
            'source': 'local_knowledge'
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500







if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    
    print("🚀 Starting Somalia Tourism Backend...")
    print(f"📍 Server running on port {port}")
    print("🔗 Available endpoints:")
    print("   - POST /chat (Tourism responses)")
    print("   - GET /health (Health check)")
    
    app.run(host='0.0.0.0', port=port, debug=debug)