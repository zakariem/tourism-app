#!/usr/bin/env python3
"""
Enhanced Somalia Tourism AI Backend
Dynamic AI assistant using real app data with Gemini API
Optimized for fast response times and intelligent context awareness
"""

import asyncio
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache
from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv
import json
import random
import requests
import google.generativeai as genai
import aiohttp
from datetime import datetime, timedelta
import hashlib

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Configure Gemini API (primary and only AI service)
gemini_api_key = os.getenv('GEMINI_API_KEY')
if gemini_api_key:
    genai.configure(api_key=gemini_api_key)
else:
    print("⚠️ Warning: GEMINI_API_KEY not found. AI features will be limited.")

# Enhanced caching system with optimized data loading
_dynamic_cache = {
    'places_data': None,
    'favorites_data': {},
    'user_context': {},
    'response_cache': {},
    'analytics': {
        'popular_places': [],
        'price_ranges': {},
        'category_stats': {}
    },
    'data_versions': {
        'places_version': 0,
        'favorites_version': 0
    },
    'last_updated': 0,
    'cache_ttl': 300,  # 5 minutes TTL
    'data_loading_status': {
        'places_loading': False,
        'favorites_loading': False,
        'last_error': None
    }
}
_cache_lock = threading.Lock()
executor = ThreadPoolExecutor(max_workers=8)  # Increased for better performance

# Dynamic data processing utilities
def generate_cache_key(data):
    """Generate a unique cache key for request data"""
    content = json.dumps(data, sort_keys=True)
    return hashlib.md5(content.encode()).hexdigest()[:16]

def is_cache_valid(timestamp, ttl=300):
    """Check if cache is still valid"""
    return time.time() - timestamp < ttl

# Optimized data loading functions
async def load_places_data_async():
    """Asynchronously load places data from Node.js API with error handling"""
    try:
        with _cache_lock:
            if _dynamic_cache['data_loading_status']['places_loading']:
                places_data = _dynamic_cache.get('places_data')
                return places_data if places_data is not None else []
            _dynamic_cache['data_loading_status']['places_loading'] = True
        
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=10)) as session:
            async with session.get('http://localhost:9000/api/places') as response:
                if response.status == 200:
                    places_data = await response.json()
                    with _cache_lock:
                        _dynamic_cache['places_data'] = places_data
                        _dynamic_cache['data_versions']['places_version'] += 1
                        _dynamic_cache['last_updated'] = time.time()
                        _dynamic_cache['data_loading_status']['last_error'] = None
                    return places_data
                else:
                    raise Exception(f"API returned status {response.status}")
    except Exception as e:
        print(f"⚠️ Error loading places data: {e}")
        with _cache_lock:
            _dynamic_cache['data_loading_status']['last_error'] = str(e)
            # Return cached data if available
            places_data = _dynamic_cache.get('places_data')
            return places_data if places_data is not None else []
    finally:
        with _cache_lock:
            _dynamic_cache['data_loading_status']['places_loading'] = False

async def load_favorites_data_async(user_id, auth_token=None):
    """Asynchronously load user favorites with authentication"""
    if not user_id:
        return []
    
    try:
        with _cache_lock:
            cache_key = f"favorites_{user_id}"
            if _dynamic_cache['data_loading_status']['favorites_loading']:
                return _dynamic_cache['favorites_data'].get(cache_key, [])
            _dynamic_cache['data_loading_status']['favorites_loading'] = True
        
        headers = {'Content-Type': 'application/json'}
        if auth_token:
            headers['Authorization'] = f'Bearer {auth_token}'
        
        async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=8)) as session:
            async with session.get('http://localhost:9000/api/favorites', headers=headers) as response:
                if response.status == 200:
                    data = await response.json()
                    favorites = data.get('favorites', [])
                    with _cache_lock:
                        _dynamic_cache['favorites_data'][cache_key] = favorites
                        _dynamic_cache['data_versions']['favorites_version'] += 1
                    return favorites
                elif response.status == 401:
                    print(f"⚠️ Authentication required for user {user_id}")
                    return []
                else:
                    raise Exception(f"Favorites API returned status {response.status}")
    except Exception as e:
        print(f"⚠️ Error loading favorites for user {user_id}: {e}")
        with _cache_lock:
            cache_key = f"favorites_{user_id}"
            return _dynamic_cache['favorites_data'].get(cache_key, [])
    finally:
        with _cache_lock:
            _dynamic_cache['data_loading_status']['favorites_loading'] = False

def get_cached_data_with_fallback(data_type, fallback_data=None):
    """Get cached data with fallback options"""
    with _cache_lock:
        if data_type == 'places':
            cached = _dynamic_cache.get('places_data')
            if cached and is_cache_valid(_dynamic_cache['last_updated']):
                return cached
        elif data_type == 'favorites':
            return _dynamic_cache.get('favorites_data', {})
    
    return fallback_data or []

def extract_place_insights(places_data):
    """Extract insights from real places data with enhanced analytics"""
    if not places_data:
        return {
            'total_places': 0,
            'categories': {},
            'locations': {},
            'price_ranges': {'min': 0, 'max': 0, 'avg': 0},
            'popular_keywords': [],
            'data_quality': 'no_data'
        }
    
    insights = {
        'total_places': len(places_data),
        'categories': {},
        'locations': {},
        'price_ranges': {'min': float('inf'), 'max': 0, 'avg': 0},
        'popular_keywords': [],
        'data_quality': 'good'
    }
    
    total_price = 0
    price_count = 0
    
    try:
        for place in places_data:
            # Category analysis
            category = place.get('category', 'unknown')
            insights['categories'][category] = insights['categories'].get(category, 0) + 1
            
            # Location analysis
            location = place.get('location', 'unknown')
            insights['locations'][location] = insights['locations'].get(location, 0) + 1
            
            # Price analysis
            price = place.get('pricePerPerson', place.get('price_per_person', 0))
            if isinstance(price, (int, float)) and price > 0:
                insights['price_ranges']['min'] = min(insights['price_ranges']['min'], price)
                insights['price_ranges']['max'] = max(insights['price_ranges']['max'], price)
                total_price += price
                price_count += 1
        
        if price_count > 0:
            insights['price_ranges']['avg'] = total_price / price_count
        else:
            insights['price_ranges'] = {'min': 0, 'max': 0, 'avg': 0}
        
        # Fix infinite min value
        if insights['price_ranges']['min'] == float('inf'):
            insights['price_ranges']['min'] = 0
            
    except Exception as e:
        print(f"⚠️ Error extracting insights: {e}")
        insights['data_quality'] = 'error'
    
    return insights

class EnhancedTourismAI:
    def __init__(self):
        # Gemini API configuration (only AI service)
        self.gemini_model = "gemini-1.5-flash"
        self.max_tokens = 1000
        self.temperature = 0.7
        
        # Enhanced pattern recognition for tourism queries
        self.intent_patterns = {
            'greeting': ['hello', 'hi', 'salaam', 'hey', 'good morning', 'good afternoon', 'assalamu alaikum'],
            'price_inquiry': ['cost', 'price', 'expensive', 'cheap', 'budget', 'money', 'fee', 'how much', 'afford', 'free', 'zero'],
            'list_all_places': ['list all', 'show all', 'all places', 'every place', 'complete list', 'full list', 'everything available'],
            'free_places': ['free', 'no cost', 'zero cost', 'without charge', 'complimentary', 'free places'],
            'recommendation': ['recommend', 'suggest', 'best', 'where', 'visit', 'place', 'should i go', 'what to see'],
            'favorites': ['favorite', 'favourite', 'like', 'love', 'prefer', 'my places', 'saved'],
            'comparison': ['compare', 'difference', 'better', 'versus', 'vs', 'which one'],
            'booking': ['book', 'reserve', 'availability', 'schedule', 'appointment'],
            'location': ['where is', 'location', 'address', 'how to get', 'directions'],
            'category': ['beach', 'historical', 'cultural', 'religious', 'park', 'museum'],
            'general': ['help', 'what can you do', 'features', 'about']
        }
        
        # Response optimization settings
        self.response_cache_ttl = 300  # 5 minutes
        self.max_context_places = 15  # Limit context size for faster responses
        
    def detect_user_intent(self, message):
        """Enhanced intent detection using pattern matching with priority"""
        message_lower = message.lower()
        detected_intents = []
        
        # Check for specific intents first (higher priority)
        priority_intents = ['list_all_places', 'free_places', 'price_inquiry']
        
        for intent in priority_intents:
            patterns = self.intent_patterns.get(intent, [])
            if any(pattern in message_lower for pattern in patterns):
                detected_intents.append(intent)
        
        # If no priority intent found, check others
        if not detected_intents:
            for intent, patterns in self.intent_patterns.items():
                if intent not in priority_intents and any(pattern in message_lower for pattern in patterns):
                    detected_intents.append(intent)
        
        # Return primary intent or 'general' if none detected
        return detected_intents[0] if detected_intents else 'general'
    
    def create_dynamic_context(self, places_data, favorites_data, user_context, insights):
        """Create optimized context from real app data"""
        context = {
            'app_data': {
                'total_places': len(places_data) if places_data else 0,
                'categories_available': list(insights.get('categories', {}).keys()) if insights else [],
                'price_range': insights.get('price_ranges', {}) if insights else {},
                'popular_locations': list(insights.get('locations', {}).keys())[:5] if insights else []
            },
            'user_profile': {
                'has_favorites': len(favorites_data) > 0 if favorites_data else False,
                'favorite_count': len(favorites_data) if favorites_data else 0,
                'user_name': user_context.get('name', 'Friend'),
                'preferred_language': user_context.get('language', 'en')
            },
            'featured_places': self._select_featured_places(places_data, favorites_data),
            'quick_stats': self._generate_quick_stats(places_data, insights)
        }
        return context
    
    def _select_featured_places(self, places_data, favorites_data):
        """Select most relevant places for context"""
        if not places_data:
            return []
        
        featured = []
        
        # Add user favorites first (up to 3)
        if favorites_data:
            featured.extend(favorites_data[:3])
        
        # Add diverse places by category
        remaining_slots = self.max_context_places - len(featured)
        if remaining_slots > 0:
            # Group by category and select representative places
            by_category = {}
            for place in places_data:
                category = place.get('category', 'other')
                if category not in by_category:
                    by_category[category] = []
                by_category[category].append(place)
            
            # Select 1-2 places from each category
            for category, places in by_category.items():
                if remaining_slots <= 0:
                    break
                # Sort by price to get variety
                places_sorted = sorted(places, key=lambda x: x.get('price_per_person', 0))
                featured.extend(places_sorted[:min(2, remaining_slots)])
                remaining_slots -= min(2, len(places_sorted))
        
        return featured[:self.max_context_places]
    
    def format_price_display(self, price):
        """Format price with 'Free' for zero values"""
        if price is None or price == 0:
            return 'Free'
        return f'${price}'
    
    def _generate_quick_stats(self, places_data, insights):
        """Generate quick statistics for context with enhanced price handling"""
        if not places_data or not insights:
            return {}
        
        # Find free places (price = 0)
        free_places = [p for p in places_data if p.get('price_per_person', 0) == 0]
        paid_places = [p for p in places_data if p.get('price_per_person', 0) > 0]
        
        return {
            'cheapest_place': min(places_data, key=lambda x: x.get('price_per_person', float('inf')), default=None),
            'most_expensive': max(places_data, key=lambda x: x.get('price_per_person', 0), default=None),
            'free_places_count': len(free_places),
            'free_places': free_places[:5],  # Top 5 free places
            'paid_places_count': len(paid_places),
            'categories_count': len(insights.get('categories', {})),
            'avg_price': round(insights.get('price_ranges', {}).get('avg', 0), 2),
            'total_places': len(places_data)
        }
        
    def create_smart_prompt(self, message, language, context, intent):
        """Create optimized prompt for Gemini API using real app data"""
        
        # Base system prompt
        system_prompt = f"""
You are an intelligent Somalia Tourism AI assistant with access to real-time app data. 
You provide personalized, accurate, and helpful responses about tourism in Somalia.

CURRENT APP DATA:
- Total places available: {context['app_data']['total_places']}
- Categories: {', '.join(context['app_data']['categories_available'])}
- Price range: ${context['app_data']['price_range'].get('min', 5)}-${context['app_data']['price_range'].get('max', 50)}
- Popular locations: {', '.join(context['app_data']['popular_locations'])}

USER PROFILE:
- Name: {context['user_profile']['user_name']}
- Has favorites: {context['user_profile']['has_favorites']}
- Favorite places count: {context['user_profile']['favorite_count']}
- Language: {language}

FEATURED PLACES (Real app data):"""
        
        # Add featured places with real data and enhanced price formatting
        for i, place in enumerate(context['featured_places'][:5], 1):
            name_key = 'name_eng' if language == 'en' else 'name_som'
            desc_key = 'desc_eng' if language == 'en' else 'desc_som'
            price = place.get('price_per_person', 0)
            price_display = 'Free' if price == 0 else f'${price}'
            
            system_prompt += f"""
{i}. {place.get(name_key, place.get('name_eng', 'Unknown'))}
   - Location: {place.get('location', 'Unknown')}
   - Category: {place.get('category', 'Unknown')}
   - Price: {price_display} per person
   - Description: {place.get(desc_key, place.get('desc_eng', 'No description'))[:100]}..."""
        
        # Add quick stats with enhanced price information
        stats = context['quick_stats']
        if stats:
            cheapest_price = stats.get('cheapest_place', {}).get('price_per_person', 0)
            most_expensive_price = stats.get('most_expensive', {}).get('price_per_person', 0)
            cheapest_display = 'Free' if cheapest_price == 0 else f'${cheapest_price}'
            most_expensive_display = 'Free' if most_expensive_price == 0 else f'${most_expensive_price}'
            
            system_prompt += f"""

QUICK STATISTICS:
- Total places: {stats.get('total_places', 0)}
- Free places: {stats.get('free_places_count', 0)}
- Paid places: {stats.get('paid_places_count', 0)}
- Cheapest option: {stats.get('cheapest_place', {}).get('name_eng', 'N/A')} ({cheapest_display})
- Most expensive: {stats.get('most_expensive', {}).get('name_eng', 'N/A')} ({most_expensive_display})
- Average price: ${stats.get('avg_price', 'N/A')}
- Available categories: {stats.get('categories_count', 0)}"""
        
        # Intent-specific instructions
        intent_instructions = {
            'price_inquiry': "Focus on cost analysis, budget recommendations, and price comparisons. Show 'Free' for zero-cost places.",
            'list_all_places': "Provide a comprehensive list of ALL available places with names, categories, locations, and prices. Show 'Free' for zero-cost places.",
            'free_places': "Focus specifically on places that cost $0 (free places). List all free options available.",
            'recommendation': "Provide personalized recommendations based on user's favorites and available places.",
            'favorites': "Reference user's favorite places and suggest similar options.",
            'comparison': "Compare specific places using real data including prices, locations, and features.",
            'location': "Provide specific location information and directions for places.",
            'category': "Focus on places in the requested category with detailed information.",
            'general': "Provide helpful information about app features and available data."
        }
        
        system_prompt += f"""

INSTRUCTIONS:
- Use ONLY the real app data provided above
- Be specific with prices, locations, and details
- ALWAYS show 'Free' instead of '$0' for zero-cost places
- {intent_instructions.get(intent, 'Provide helpful and accurate information.')}
- Respond in {language} ({'English' if language == 'en' else 'Somali'})
- Keep responses concise but informative (max 300 words for list requests, 200 words for others)
- Always reference real places and data when possible
- If asked about places not in the data, mention what IS available
- For list requests, organize by category or price for better readability

User's question: {message}"""
        
        return system_prompt
    
    async def call_gemini_api(self, prompt, timeout=4):
        """Optimized Gemini API call with faster timeout"""
        if not gemini_api_key:
            return None
        
        try:
            # Use the official Gemini SDK for better performance
            model = genai.GenerativeModel(self.gemini_model)
            
            # Configure generation settings for speed and quality
            generation_config = genai.types.GenerationConfig(
                max_output_tokens=self.max_tokens,
                temperature=self.temperature,
                top_p=0.8,
                top_k=40
            )
            
            # Generate response with timeout
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.generate_content,
                    prompt,
                    generation_config=generation_config
                ),
                timeout=timeout
            )
            
            if response and response.text:
                return response.text.strip()
            
        except asyncio.TimeoutError:
            print(f"⏰ Gemini API timeout after {timeout}s")
        except Exception as e:
            print(f"❌ Gemini API error: {e}")
        
        return None
        
        # Quick responses for common queries
        self.quick_responses = {
            'greeting_en': "🌟 Welcome to Somalia Tourism! How can I help you explore beautiful Somalia today?",
            'greeting_so': "🌟 Ku soo dhawoow dalxiiska Soomaaliya! Sidee kuu caawin karaa maanta?",
            'price_en': "💰 Somalia tourism costs: Beaches $3-12, Historical sites $5-25, Accommodation $15-200/night",
            'price_so': "💰 Qiimaha dalxiiska Soomaaliya: Xeebaha $3-12, Meelaha taariikhiga $5-25, Hoyga $15-200/habeen"
        }
    

    
    def get_smart_fallback(self, intent, language, context):
        """Dynamic fallback responses using real app data with enhanced capabilities"""
        app_data = context.get('app_data', {})
        quick_stats = context.get('quick_stats', {})
        featured_places = context.get('featured_places', [])
        total_places = app_data.get('total_places', 0)
        user_favorites = context.get('user_profile', {}).get('favorite_count', 0)
        
        if intent == 'greeting':
            if language == 'so':
                return f"🌟 Ku soo dhawoow dalxiiska Soomaaliya! Waxaan haynaa {total_places} meel oo qurux badan. Sidee kuu caawin karaa?"
            else:
                return f"🌟 Welcome to Somalia Tourism! We have {total_places} amazing places to explore. How can I help you today?"
        
        elif intent == 'list_all_places':
            if not featured_places:
                return "📍 No places data available at the moment. Please try again later."
            
            places_list = []
            for place in featured_places:
                name = place.get('name_eng', 'Unknown')
                category = place.get('category', 'Unknown')
                location = place.get('location', 'Unknown')
                price = place.get('price_per_person', 0)
                price_display = 'Free' if price == 0 else f'${price}'
                places_list.append(f"• {name} ({category}) - {location} - {price_display}")
            
            if language == 'so':
                return f"📍 Dhammaan meelaha dalxiiska ({total_places} guud ahaan):\n\n" + "\n".join(places_list[:15]) + (f"\n\n... iyo {total_places - 15} meel oo kale!" if total_places > 15 else "")
            else:
                return f"📍 All Tourism Places ({total_places} total):\n\n" + "\n".join(places_list[:15]) + (f"\n\n... and {total_places - 15} more places!" if total_places > 15 else "")
        
        elif intent == 'free_places':
            free_places = quick_stats.get('free_places', [])
            free_count = quick_stats.get('free_places_count', 0)
            
            if free_count == 0:
                if language == 'so':
                    return "💰 Ma jiraan meelo bilaash ah hadda. Laakiin waxaan haynaa meelo jaban oo qiimo yar leh!"
                else:
                    return "💰 No completely free places available right now, but we have many affordable options!"
            
            free_list = []
            for place in free_places:
                name = place.get('name_eng', 'Unknown')
                category = place.get('category', 'Unknown')
                location = place.get('location', 'Unknown')
                free_list.append(f"• {name} ({category}) - {location} - Free")
            
            if language == 'so':
                return f"🆓 Meelaha bilaashka ah ({free_count} guud ahaan):\n\n" + "\n".join(free_list)
            else:
                return f"🆓 Free Places ({free_count} total):\n\n" + "\n".join(free_list)
        
        elif intent == 'price_inquiry':
            free_count = quick_stats.get('free_places_count', 0)
            paid_count = quick_stats.get('paid_places_count', 0)
            avg_price = quick_stats.get('avg_price', 0)
            
            if language == 'so':
                return f"💰 Qiimaha dalxiiska:\n• Meelo bilaash: {free_count}\n• Meelo lacag leh: {paid_count}\n• Qiimaha dhexe: ${avg_price}\n• Xeebaha: $3-12\n• Taariikhiga: $5-25"
            else:
                return f"💰 Tourism Pricing:\n• Free places: {free_count}\n• Paid places: {paid_count}\n• Average price: ${avg_price}\n• Beaches: $3-12\n• Historical: $5-25"
        
        elif intent == 'recommendation':
            if not featured_places:
                return "🌟 No recommendations available at the moment."
            
            places_text = []
            for place in featured_places[:3]:
                name = place.get('name_eng', 'Unknown')
                price = place.get('price_per_person', 0)
                price_display = 'Free' if price == 0 else f'${price}'
                places_text.append(f"• {name} - {price_display}")
            
            if language == 'so':
                return f"🌟 Meelaha ugu fiican:\n" + "\n".join(places_text) + f"\n\nWaxaa jira {total_places} meel oo kale!"
            else:
                return f"🌟 Top recommendations:\n" + "\n".join(places_text) + f"\n\n{total_places} total places available!"
        
        elif intent == 'favorites':
            if language == 'so':
                return f"❤️ Waxaad jeceshahay {user_favorites} meel. Ma rabtaa inaad aragto liiskaaga?"
            else:
                return f"❤️ You have {user_favorites} favorite places. Would you like to see your list?"
        
        else:
            if language == 'so':
                return f"🤖 Waxaan kaa caawin karaa {total_places} meel oo Soomaaliya ah. Wax ka weydiiso!"
            else:
                return f"🤖 I can help you explore {total_places} places in Somalia. What would you like to know?"
    
    async def generate_smart_response(self, message, language, places_data=None, favorites_data=None, user_context=None):
        """Main response generation with optimized data loading and caching"""
        try:
            # Use provided data or load fresh data asynchronously
            if places_data is None:
                places_data = await load_places_data_async()
            
            # Load user favorites if user context is provided
            if favorites_data is None and user_context:
                user_id = user_context.get('user_id')
                auth_token = user_context.get('auth_token')
                if user_id:
                    favorites_data = await load_favorites_data_async(user_id, auth_token)
                else:
                    favorites_data = []
            
            # Fallback to empty lists if still None
            places_data = places_data or []
            favorites_data = favorites_data or []
            user_context = user_context or {}
            
            # Extract insights from real data
            insights = extract_place_insights(places_data)
            
            # Detect user intent
            intent = self.detect_user_intent(message)
            
            # Create dynamic context
            context = self.create_dynamic_context(places_data, favorites_data, user_context, insights)
            
            # Generate cache key including data versions for cache invalidation
            data_version = f"{_dynamic_cache['data_versions']['places_version']}_{_dynamic_cache['data_versions']['favorites_version']}"
            cache_key = generate_cache_key(f"{message[:50]}_{language}_{intent}_{data_version}")
            
            # Check cache first
            with _cache_lock:
                if cache_key in _dynamic_cache['response_cache']:
                    cached_response, timestamp = _dynamic_cache['response_cache'][cache_key]
                    if is_cache_valid(timestamp):
                        return cached_response
            
            # Create optimized prompt
            prompt = self.create_smart_prompt(message, language, context, intent)
            
            # Try Gemini API with timeout
            response = await self.call_gemini_api(prompt, timeout=6)
            
            if response and len(response.strip()) > 10:
                # Cache successful response
                with _cache_lock:
                    _dynamic_cache['response_cache'][cache_key] = (response, time.time())
                    # Limit cache size to prevent memory issues
                    if len(_dynamic_cache['response_cache']) > 100:
                        # Remove oldest entries
                        oldest_keys = sorted(_dynamic_cache['response_cache'].keys())[:20]
                        for old_key in oldest_keys:
                            del _dynamic_cache['response_cache'][old_key]
                return response
            
            # Fallback to smart response
            return self.get_smart_fallback(intent, language, context)
            
        except Exception as e:
            print(f"❌ Response generation error: {e}")
            # Log error details for debugging
            with _cache_lock:
                _dynamic_cache['data_loading_status']['last_error'] = f"Response generation: {str(e)}"
            
            # Emergency fallback with context awareness
            if language == 'so':
                return "🤖 Waan ka xumahay, cilad ayaa dhacday. Fadlan mar kale isku day."
            else:
                return "🤖 Sorry, I encountered an error. Please try again."

# Initialize the enhanced AI chatbot
chatbot = EnhancedTourismAI()

# Health check endpoint
@app.route('/health', methods=['GET'])
def health_check():
    """Enhanced health check with data loading status"""
    with _cache_lock:
        places_data = _dynamic_cache.get('places_data')
        favorites_data = _dynamic_cache.get('favorites_data', {})
        
        data_status = {
            'places_loaded': places_data is not None,
            'places_count': len(places_data) if places_data is not None else 0,
            'favorites_cached': len(favorites_data) if isinstance(favorites_data, dict) else 0,
            'cache_valid': is_cache_valid(_dynamic_cache.get('last_updated', 0)),
            'last_error': _dynamic_cache['data_loading_status'].get('last_error'),
            'data_versions': _dynamic_cache['data_versions'],
            'loading_status': {
                'places_loading': _dynamic_cache['data_loading_status']['places_loading'],
                'favorites_loading': _dynamic_cache['data_loading_status']['favorites_loading']
            }
        }
    
    return jsonify({
        'status': 'healthy', 
        'service': 'Somalia Tourism Backend',
        'data_status': data_status,
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

# Smart chat endpoint (new AI-powered functionality)
@app.route('/smart-chat', methods=['POST'])
def smart_chat():
    """AI-powered smart chat endpoint"""
    try:
        data = request.get_json()
        message = data.get('message', '')
        language = data.get('language', 'en')
        user_context = data.get('user_context', {})
        places_data = data.get('places_data', [])
        favorites_data = data.get('favorites_data', [])
        
        if not message:
            return jsonify({'error': 'Message is required'}), 400
        
        # Run async smart response in thread
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            response = loop.run_until_complete(
                chatbot.generate_smart_response(
                    message, language, places_data, favorites_data, user_context
                )
            )
        finally:
            loop.close()
        
        return jsonify({
            'response': response,
            'language': language,
            'source': 'smart_ai',
            'timestamp': time.time()
        })
        
    except Exception as e:
        print(f"Smart chat error: {e}")
        # Fallback to local response
        response = get_local_tourism_response(data.get('message', ''), data.get('language', 'en'))
        return jsonify({
            'response': response,
            'language': data.get('language', 'en'),
            'source': 'fallback'
        })

@app.route('/preload-data', methods=['POST'])
def preload_data():
    """Preload places and favorites data for faster responses"""
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        auth_token = data.get('auth_token')
        
        # Run preloading in background
        async def preload_async():
            places_task = load_places_data_async()
            favorites_task = None
            
            if user_id:
                favorites_task = load_favorites_data_async(user_id, auth_token)
            
            places_result = await places_task
            favorites_result = await favorites_task if favorites_task else []
            
            return {
                'places_loaded': len(places_result),
                'favorites_loaded': len(favorites_result)
            }
        
        # Execute async preloading
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            result = loop.run_until_complete(preload_async())
        finally:
            loop.close()
        
        return jsonify({
            'message': 'Data preloaded successfully',
            'result': result,
            'timestamp': time.time()
        })
        
    except Exception as e:
        print(f"Preload error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/cache-stats', methods=['GET'])
def cache_stats():
    """Get detailed cache statistics"""
    with _cache_lock:
        places_data = _dynamic_cache.get('places_data')
        response_cache = _dynamic_cache.get('response_cache', {})
        favorites_data = _dynamic_cache.get('favorites_data', {})
        
        stats = {
            'cache_size': {
                'response_cache': len(response_cache) if isinstance(response_cache, dict) else 0,
                'places_data': len(places_data) if places_data is not None else 0,
                'favorites_data': len(favorites_data) if isinstance(favorites_data, dict) else 0
            },
            'data_versions': _dynamic_cache['data_versions'],
            'last_updated': _dynamic_cache.get('last_updated', 0),
            'cache_ttl': _dynamic_cache['cache_ttl'],
            'loading_status': _dynamic_cache['data_loading_status'],
            'cache_valid': is_cache_valid(_dynamic_cache.get('last_updated', 0))
        }
    
    return jsonify(stats)

@app.route('/clear-cache', methods=['POST'])
def clear_cache():
    """Clear specific cache types"""
    try:
        data = request.get_json() or {}
        cache_types = data.get('types', ['response_cache'])  # Default to response cache
        
        cleared = []
        with _cache_lock:
            for cache_type in cache_types:
                if cache_type == 'response_cache':
                    _dynamic_cache['response_cache'].clear()
                    cleared.append('response_cache')
                elif cache_type == 'places_data':
                    _dynamic_cache['places_data'] = None
                    _dynamic_cache['data_versions']['places_version'] += 1
                    cleared.append('places_data')
                elif cache_type == 'favorites_data':
                    _dynamic_cache['favorites_data'].clear()
                    _dynamic_cache['data_versions']['favorites_version'] += 1
                    cleared.append('favorites_data')
                elif cache_type == 'all':
                    _dynamic_cache['response_cache'].clear()
                    _dynamic_cache['places_data'] = None
                    _dynamic_cache['favorites_data'].clear()
                    _dynamic_cache['data_versions']['places_version'] += 1
                    _dynamic_cache['data_versions']['favorites_version'] += 1
                    cleared = ['all']
                    break
        
        return jsonify({
            'message': 'Cache cleared successfully',
            'cleared_types': cleared,
            'timestamp': time.time()
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# API key configuration endpoint
@app.route('/set-api-key', methods=['POST'])
def set_api_key():
    """Configure Gemini API key dynamically"""
    try:
        data = request.get_json()
        
        if 'gemini_key' in data:
            global gemini_api_key
            gemini_api_key = data['gemini_key']
            if gemini_api_key:
                genai.configure(api_key=gemini_api_key)
                return jsonify({
                    'status': 'success', 
                    'message': 'Gemini API key updated successfully',
                    'ai_service': 'gemini'
                })
            else:
                return jsonify({
                    'status': 'error', 
                    'message': 'Invalid Gemini API key provided'
                }), 400
        
        return jsonify({
            'status': 'error', 
            'message': 'Gemini API key is required'
        }), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    
    print("🚀 Starting Unified Somalia Tourism Backend...")
    print(f"📍 Server running on port {port}")
    print("🔗 Available endpoints:")
    print("   - POST /smart-chat (AI-powered responses)")
    print("   - POST /chat (Legacy responses)")
    print("   - POST /set-api-key (Configure API keys)")
    print("   - GET /health (Health check)")
    
    app.run(host='0.0.0.0', port=port, debug=debug)