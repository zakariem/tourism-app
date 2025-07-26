#!/usr/bin/env python3
"""
Setup script for Tourism App Node.js Backend
This script helps you set up the Node.js backend with MongoDB and JWT authentication.
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

def create_env_file():
    """Create .env file if it doesn't exist"""
    env_file = "node-server/.env"
    if os.path.exists(env_file):
        print("✅ .env file already exists")
        return True
    
    print("\n📝 Creating .env file...")
    env_content = """# Server Configuration
PORT=9000
NODE_ENV=development

# MongoDB Configuration
MONGO_URI=mongodb://localhost:27017/tourism_app

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
"""
    
    try:
        with open(env_file, 'w') as f:
            f.write(env_content)
        print("✅ .env file created successfully")
        print("⚠️  Please make sure MongoDB is running and update the MONGO_URI if needed")
        return True
    except Exception as e:
        print(f"❌ Failed to create .env file: {e}")
        return False

def main():
    print("🚀 Tourism App Node.js Backend Setup")
    print("=" * 40)
    
    # Check if node-server directory exists
    if not os.path.exists("node-server"):
        print("❌ node-server directory not found")
        sys.exit(1)
    
    # Install Node.js dependencies
    if not run_command("cd node-server && npm install", "Installing Node.js dependencies"):
        print("\n💡 Make sure you have Node.js and npm installed")
        sys.exit(1)
    
    # Create .env file
    create_env_file()
    
    print("\n🎉 Setup completed!")
    print("\n📋 Next steps:")
    print("1. Make sure MongoDB is running on your system")
    print("2. Start the backend server: cd node-server && npm start")
    print("3. Test the API: curl http://localhost:9000/")
    print("4. The Flutter app should now be able to connect to the backend")
    print("\n🔗 For more information, see node-server/README.md")

if __name__ == "__main__":
    main() 