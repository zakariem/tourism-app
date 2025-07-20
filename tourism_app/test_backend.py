#!/usr/bin/env python3
"""
Test script for Tourism App Chat Backend
This script tests the backend API endpoints.
"""

import requests
import json
import time

BASE_URL = "http://localhost:5000"

def test_health_check():
    """Test the health check endpoint"""
    print("🔍 Testing health check...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Health check passed: {data}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to backend. Make sure it's running on localhost:5000")
        return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_chat_endpoint():
    """Test the chat endpoint"""
    print("\n🔍 Testing chat endpoint...")
    try:
        data = {
            "message": "Tell me about beaches in Somalia",
            "language": "en"
        }
        
        response = requests.post(
            f"{BASE_URL}/chat",
            headers={"Content-Type": "application/json"},
            json=data
        )
        
        if response.statusCode == 200:
            result = response.json()
            print("✅ Chat endpoint working!")
            print(f"Response: {result['response'][:100]}...")
            return True
        else:
            print(f"❌ Chat endpoint failed: {response.status_code}")
            print(f"Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Chat endpoint error: {e}")
        return False

def test_somali_chat():
    """Test the chat endpoint with Somali language"""
    print("\n🔍 Testing Somali chat...")
    try:
        data = {
            "message": "Maxaad iigu talin lahayd haddii aan jeclahay xeebaha quruxda badan ee Soomaaliya?",
            "language": "so"
        }
        
        response = requests.post(
            f"{BASE_URL}/chat",
            headers={"Content-Type": "application/json"},
            json=data
        )
        
        if response.statusCode == 200:
            result = response.json()
            print("✅ Somali chat working!")
            print(f"Response: {result['response'][:100]}...")
            return True
        else:
            print(f"❌ Somali chat failed: {response.status_code}")
            print(f"Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Somali chat error: {e}")
        return False

def main():
    print("🧪 Tourism App Chat Backend Test")
    print("=" * 40)
    
    # Test health check
    if not test_health_check():
        print("\n❌ Backend is not running or not accessible")
        print("💡 Start the backend with: cd backend && python app.py")
        return
    
    # Test English chat
    if not test_chat_endpoint():
        print("\n❌ Chat endpoint test failed")
        return
    
    # Test Somali chat
    if not test_somali_chat():
        print("\n❌ Somali chat test failed")
        return
    
    print("\n🎉 All tests passed! Your backend is working correctly.")
    print("🚀 You can now use the chat feature in your Flutter app.")

if __name__ == "__main__":
    main() 