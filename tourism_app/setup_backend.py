#!/usr/bin/env python3
"""
Setup script for Tourism App Chat Backend
This script helps you set up the Python backend with OpenAI API integration.
"""

import os
import subprocess
import sys

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"\n🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed: {e}")
        print(f"Error output: {e.stderr}")
        return False

def check_python_version():
    """Check if Python version is compatible"""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print("❌ Python 3.8 or higher is required")
        return False
    print(f"✅ Python {version.major}.{version.minor}.{version.micro} detected")
    return True

def create_env_file():
    """Create .env file if it doesn't exist"""
    env_file = "backend/.env"
    if os.path.exists(env_file):
        print("✅ .env file already exists")
        return True
    
    print("\n📝 Creating .env file...")
    env_content = """# OpenAI API Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Flask Configuration
FLASK_ENV=development
PORT=5000

# CORS Configuration (optional)
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
"""
    
    try:
        with open(env_file, 'w') as f:
            f.write(env_content)
        print("✅ .env file created successfully")
        print("⚠️  Please edit backend/.env and add your OpenAI API key")
        return True
    except Exception as e:
        print(f"❌ Failed to create .env file: {e}")
        return False

def main():
    print("🚀 Tourism App Chat Backend Setup")
    print("=" * 40)
    
    # Check Python version
    if not check_python_version():
        sys.exit(1)
    
    # Create backend directory if it doesn't exist
    if not os.path.exists("backend"):
        print("📁 Creating backend directory...")
        os.makedirs("backend")
    
    # Install Python dependencies
    if not run_command("pip install -r backend/requirements.txt", "Installing Python dependencies"):
        print("\n💡 If requirements.txt doesn't exist, run: pip install flask flask-cors openai python-dotenv requests")
    
    # Create .env file
    create_env_file()
    
    print("\n🎉 Setup completed!")
    print("\n📋 Next steps:")
    print("1. Get your OpenAI API key from https://platform.openai.com/")
    print("2. Edit backend/.env and replace 'your_openai_api_key_here' with your actual API key")
    print("3. Run the backend: cd backend && python app.py")
    print("4. Test the API: curl http://localhost:5000/health")
    print("\n🔗 For more information, see backend/README.md")

if __name__ == "__main__":
    main() 