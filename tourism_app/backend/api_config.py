#!/usr/bin/env python3
"""
API Configuration Helper for Enhanced Smart Tourism Chat

This script helps you configure API keys for external AI services.
Supported APIs:
- Google Gemini
- OpenAI ChatGPT
- Anthropic Claude

Usage:
1. Run this script to set up your API keys
2. Or set environment variables manually
3. Or use the /set-api-key endpoint
"""

import os
import json
from typing import Dict, Optional

class APIKeyManager:
    def __init__(self):
        self.config_file = 'api_keys.json'
        self.env_file = '.env'
    
    def get_api_key_info(self) -> Dict[str, str]:
        """Get information about where to obtain API keys"""
        return {
            'gemini': {
                'name': 'Google Gemini',
                'url': 'https://makersuite.google.com/app/apikey',
                'description': 'Free tier available with generous limits',
                'env_var': 'GEMINI_API_KEY'
            },
            'openai': {
                'name': 'OpenAI ChatGPT',
                'url': 'https://platform.openai.com/api-keys',
                'description': 'Pay-per-use, very reliable',
                'env_var': 'OPENAI_API_KEY'
            },
            'claude': {
                'name': 'Anthropic Claude',
                'url': 'https://console.anthropic.com/',
                'description': 'High quality responses, pay-per-use',
                'env_var': 'CLAUDE_API_KEY'
            }
        }
    
    def display_setup_instructions(self):
        """Display setup instructions for API keys"""
        print("🔑 API Key Setup Instructions")
        print("=" * 50)
        
        api_info = self.get_api_key_info()
        
        for key, info in api_info.items():
            print(f"\n📍 {info['name']}:")
            print(f"   URL: {info['url']}")
            print(f"   Description: {info['description']}")
            print(f"   Environment Variable: {info['env_var']}")
        
        print("\n" + "=" * 50)
        print("\n💡 Setup Options:")
        print("\n1. Environment Variables (Recommended):")
        print("   - Windows: set GEMINI_API_KEY=your_key_here")
        print("   - Linux/Mac: export GEMINI_API_KEY=your_key_here")
        
        print("\n2. .env File:")
        print("   Create a .env file with:")
        print("   GEMINI_API_KEY=your_key_here")
        print("   OPENAI_API_KEY=your_key_here")
        print("   CLAUDE_API_KEY=your_key_here")
        
        print("\n3. Runtime Configuration:")
        print("   Use the /set-api-key endpoint after starting the server")
        
        print("\n⚠️  Important:")
        print("   - Keep your API keys secure and private")
        print("   - Don't commit API keys to version control")
        print("   - You only need ONE API key to get started")
        print("   - The system will fallback to intelligent responses if APIs fail")
    
    def check_current_keys(self) -> Dict[str, bool]:
        """Check which API keys are currently configured"""
        keys_status = {}
        api_info = self.get_api_key_info()
        
        for key, info in api_info.items():
            env_var = info['env_var']
            keys_status[key] = bool(os.getenv(env_var))
        
        return keys_status
    
    def display_current_status(self):
        """Display current API key configuration status"""
        print("\n🔍 Current API Key Status:")
        print("-" * 30)
        
        status = self.check_current_keys()
        api_info = self.get_api_key_info()
        
        for key, configured in status.items():
            name = api_info[key]['name']
            status_icon = "✅" if configured else "❌"
            status_text = "Configured" if configured else "Not configured"
            print(f"   {status_icon} {name}: {status_text}")
        
        configured_count = sum(status.values())
        
        if configured_count == 0:
            print("\n⚠️  No API keys configured. The system will use intelligent fallback responses.")
        elif configured_count == 1:
            print("\n✅ Good! You have one API configured. The system is ready for AI-powered responses.")
        else:
            print(f"\n🚀 Excellent! You have {configured_count} APIs configured for maximum reliability.")
    
    def create_env_template(self):
        """Create a .env template file"""
        template_content = """# Enhanced Smart Tourism Chat - API Configuration
# Copy this file to .env and add your actual API keys
# You only need ONE API key to get started

# Google Gemini (Recommended - Free tier available)
# Get your key from: https://makersuite.google.com/app/apikey
GEMINI_API_KEY=your_gemini_api_key_here

# OpenAI ChatGPT (Pay-per-use)
# Get your key from: https://platform.openai.com/api-keys
# OPENAI_API_KEY=your_openai_api_key_here

# Anthropic Claude (Pay-per-use)
# Get your key from: https://console.anthropic.com/
# CLAUDE_API_KEY=your_claude_api_key_here

# Note: Uncomment and fill in the API keys you want to use
# The system will try APIs in order: Gemini -> OpenAI -> Claude
# If all fail, it will use intelligent fallback responses
"""
        
        with open('.env.template', 'w') as f:
            f.write(template_content)
        
        print("\n📝 Created .env.template file")
        print("   Copy it to .env and add your actual API keys")
    
    def interactive_setup(self):
        """Interactive setup wizard"""
        print("\n🧙‍♂️ Interactive API Key Setup Wizard")
        print("=" * 40)
        
        api_info = self.get_api_key_info()
        
        print("\nWhich API would you like to configure?")
        print("(You only need ONE to get started)\n")
        
        for i, (key, info) in enumerate(api_info.items(), 1):
            print(f"{i}. {info['name']} - {info['description']}")
        
        print(f"{len(api_info) + 1}. Skip setup (use fallback responses)")
        
        try:
            choice = input("\nEnter your choice (1-4): ").strip()
            
            if choice == str(len(api_info) + 1):
                print("\n✅ Setup skipped. The system will use intelligent fallback responses.")
                return
            
            choice_idx = int(choice) - 1
            if 0 <= choice_idx < len(api_info):
                selected_key = list(api_info.keys())[choice_idx]
                selected_info = api_info[selected_key]
                
                print(f"\n🔑 Setting up {selected_info['name']}")
                print(f"Get your API key from: {selected_info['url']}")
                
                api_key = input(f"\nEnter your {selected_info['name']} API key: ").strip()
                
                if api_key:
                    # Set environment variable for current session
                    os.environ[selected_info['env_var']] = api_key
                    
                    # Create/update .env file
                    env_content = f"{selected_info['env_var']}={api_key}\n"
                    
                    with open('.env', 'a') as f:
                        f.write(env_content)
                    
                    print(f"\n✅ {selected_info['name']} API key configured successfully!")
                    print("   The key has been saved to .env file")
                    print("   Restart the server to use the new configuration")
                else:
                    print("\n❌ No API key entered. Setup cancelled.")
            else:
                print("\n❌ Invalid choice. Setup cancelled.")
                
        except (ValueError, KeyboardInterrupt):
            print("\n❌ Setup cancelled.")
    
    def test_api_connection(self, api_key: str, api_type: str) -> bool:
        """Test if an API key is working"""
        # This is a basic test - in production you might want more sophisticated testing
        if not api_key or len(api_key) < 10:
            return False
        
        # Basic format validation
        if api_type == 'gemini' and not api_key.startswith('AI'):
            return False
        elif api_type == 'openai' and not api_key.startswith('sk-'):
            return False
        elif api_type == 'claude' and not api_key.startswith('sk-ant-'):
            return False
        
        return True

def main():
    """Main function for the API configuration helper"""
    manager = APIKeyManager()
    
    print("🤖 Enhanced Smart Tourism Chat - API Configuration")
    print("=" * 55)
    
    # Display current status
    manager.display_current_status()
    
    print("\n" + "=" * 55)
    print("\nWhat would you like to do?")
    print("1. View setup instructions")
    print("2. Interactive setup wizard")
    print("3. Create .env template")
    print("4. Check current status")
    print("5. Exit")
    
    try:
        choice = input("\nEnter your choice (1-5): ").strip()
        
        if choice == '1':
            manager.display_setup_instructions()
        elif choice == '2':
            manager.interactive_setup()
        elif choice == '3':
            manager.create_env_template()
        elif choice == '4':
            manager.display_current_status()
        elif choice == '5':
            print("\n👋 Goodbye!")
        else:
            print("\n❌ Invalid choice.")
            
    except KeyboardInterrupt:
        print("\n\n👋 Goodbye!")

if __name__ == '__main__':
    main()