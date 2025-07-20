from flask import Flask, request, jsonify
from flask_cors import CORS
import openai
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Configure OpenAI API
openai.api_key = os.getenv('OPENAI_API_KEY')

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'message': 'Tourism Chat API is running'})

@app.route('/chat', methods=['POST'])
def chat():
    """Chat endpoint that integrates with OpenAI API"""
    try:
        data = request.get_json()
        
        if not data or 'message' not in data:
            return jsonify({'error': 'Message is required'}), 400
        
        message = data['message']
        language = data.get('language', 'en')
        
        # Define system prompts based on language
        system_prompts = {
            'en': """You are a helpful tourism assistant for Somalia. Provide accurate and helpful information about tourist destinations, cultural sites, and travel tips in Somalia. Keep responses concise and friendly. Focus only on tourism-related questions and provide practical advice for travelers visiting Somalia.""",
            'so': """Waxaad tahay caawiye safar oo ku takhasusay dalxiiska Soomaaliya. Waxa aad dadka u sheegtaa meelaha dalxiiska ee muhiimka ah sida xeebaha, taariikhda, dhaqanka, iyo deegaannada dabiiciga ah. Jawaabahaaga ku bixi af Soomaali. Waxa aad la talisaa dadka meelaha ay booqan karaan iyadoo ku saleysan danahooda. Haka jawaabin wax aan la xiriirin su'aalaha dalxiiska."""
        }
        
        system_prompt = system_prompts.get(language, system_prompts['en'])
        
        # Call OpenAI API
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": system_prompt
                },
                {
                    "role": "user",
                    "content": message
                }
            ],
            max_tokens=500,
            temperature=0.7
        )
        
        # Extract the response content
        if response.choices and len(response.choices) > 0:
            assistant_message = response.choices[0].message.content
            return jsonify({
                'response': assistant_message,
                'status': 'success'
            })
        else:
            return jsonify({'error': 'No response from OpenAI'}), 500
            
    except openai.error.AuthenticationError:
        return jsonify({'error': 'OpenAI API key is invalid'}), 401
    except openai.error.RateLimitError:
        return jsonify({'error': 'Rate limit exceeded. Please try again later.'}), 429
    except openai.error.APIError as e:
        return jsonify({'error': f'OpenAI API error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500

@app.route('/chat/stream', methods=['POST'])
def chat_stream():
    """Streaming chat endpoint for real-time responses"""
    try:
        data = request.get_json()
        
        if not data or 'message' not in data:
            return jsonify({'error': 'Message is required'}), 400
        
        message = data['message']
        language = data.get('language', 'en')
        
        # Define system prompts based on language
        system_prompts = {
            'en': """You are a helpful tourism assistant for Somalia. Provide accurate and helpful information about tourist destinations, cultural sites, and travel tips in Somalia. Keep responses concise and friendly. Focus only on tourism-related questions and provide practical advice for travelers visiting Somalia.""",
            'so': """Waxaad tahay caawiye safar oo ku takhasusay dalxiiska Soomaaliya. Waxa aad dadka u sheegtaa meelaha dalxiiska ee muhiimka ah sida xeebaha, taariikhda, dhaqanka, iyo deegaannada dabiiciga ah. Jawaabahaaga ku bixi af Soomaali. Waxa aad la talisaa dadka meelaha ay booqan karaan iyadoo ku saleysan danahooda. Haka jawaabin wax aan la xiriirin su'aalaha dalxiiska."""
        }
        
        system_prompt = system_prompts.get(language, system_prompts['en'])
        
        # Call OpenAI API with streaming
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": system_prompt
                },
                {
                    "role": "user",
                    "content": message
                }
            ],
            max_tokens=500,
            temperature=0.7,
            stream=True
        )
        
        def generate():
            for chunk in response:
                if chunk.choices and len(chunk.choices) > 0:
                    delta = chunk.choices[0].delta
                    if delta.content:
                        yield f"data: {delta.content}\n\n"
            yield "data: [DONE]\n\n"
        
        return app.response_class(
            generate(),
            mimetype='text/plain'
        )
        
    except Exception as e:
        return jsonify({'error': f'Server error: {str(e)}'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug) 