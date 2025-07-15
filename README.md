# Tourism System with ML-Powered Recommendations

A comprehensive tourism guide application for Somalia, featuring a Flutter mobile app and a Python-based backend for machine learning-powered personalized recommendations.

## 🏗️ Architecture

- **Backend ML Pipeline** (`/backend`): Python scripts for training, evaluating, and exporting the recommendation model.
- **Flutter Mobile App** (`/tourism_app`): Cross-platform app with integrated TFLite model for on-device recommendations.

## 🚀 Features

### Core App Features

- **Tourist Place Discovery**: Browse, search, and filter tourist locations by category (beach, historical, cultural, religious)
- **Multi-language Support**: English and Somali
- **User Authentication**: Register, login, and manage user profiles
- **Favorites Management**: Save and manage favorite places
- **Offline Support**: Local database for places and favorites

### ML-Powered Features

- **Personalized Recommendations**: AI-driven suggestions based on user behavior
- **Behavior Tracking**: Tracks clicks, view time, and language preference
- **Smart Categorization**: Predicts user preference category
- **Learning Progress**: Visual indicator of progress towards next recommendation
- **Confidence Scoring**: (Planned) Show model confidence for recommendations

## 📊 ML Model Details

- **Training Data**: `tourism_user_behavior.csv` (5,002 user records)
- **Features**: Click counts (beach, historical, cultural, religious), average view time, language
- **Output Classes**: Nature (mapped to beach), Religious, Historical, Cultural
- **Model**: Neural Network (TensorFlow/Keras), exported as TensorFlow Lite (`tourism_model.tflite`)
- **Preprocessing**: Standardization (mean/scale), label encoding, exported as JSON

## 🛠️ Setup Instructions

### Backend ML Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```
2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```
3. **Train the model:**
   ```bash
   python train_model.py
   ```
   - This generates `tourism_model.tflite` and `preprocessing_params.json`/`.pkl`.
4. **Copy model and params to Flutter app:**
   ```bash
   cp tourism_model.tflite ../tourism_app/assets/ml/
   cp preprocessing_params.json ../tourism_app/assets/ml/
   ```

### Flutter App Setup

1. **Navigate to app directory:**
   ```bash
   cd tourism_app
   ```
2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   flutter run
   ```
   - The app will seed the local database with places on first launch.

## 📱 App Usage

1. Register or login to the app
2. Browse and interact with places (click, view details, switch language)
3. The app tracks your behavior (clicks, view time, language)
4. After 10+ interactions, the ML model predicts your preferred category
5. The Home tab displays a "Recommended for You" section with places from your predicted category
6. The recommendation updates as your behavior changes

## 🗄️ Database Schema (Flutter App)

- `users`: User accounts
- `places`: Tourist locations (with category, name, description, image, etc.)
- `favorites`: User favorite places
- `chat_messages`: (For support/chat features)

## 🔧 Technical Stack

- **Backend**: Python 3.8+, TensorFlow 2.x, Pandas, Scikit-learn
- **Frontend**: Flutter 3.x, tflite_flutter, SQLite, Provider

## 📁 Project Structure

```
tourism_sys/
├── backend/
│   ├── train_model.py              # ML training script
│   ├── requirements.txt            # Python dependencies
│   ├── tourism_user_behavior.csv   # Training dataset
│   ├── tourism_model.tflite        # Exported TFLite model
│   ├── preprocessing_params.json   # Preprocessing params for inference
│   └── ...
├── tourism_app/
│   ├── lib/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── utils/
│   │   └── widgets/
│   ├── assets/
│   │   └── ml/                     # ML model and params
│   └── pubspec.yaml
└── README.md
```

## 🎯 ML Workflow

1. **Data Collection**: App tracks user clicks, view time, and language
2. **Behavior Analysis**: Features are standardized and encoded
3. **Model Prediction**: TFLite model predicts preferred category
4. **Recommendation Generation**: App displays places from predicted category
5. **Continuous Learning**: Recommendations update as user behavior changes

## 🔄 Recommendation Cycle

- **Minimum Data**: 10+ total clicks required for first prediction
- **Update Frequency**: Every 10 new clicks (behavior resets after each recommendation)
- **Persistence**: Last recommendation is saved and shown on app restart

## 🚨 Troubleshooting

- **Model not loading**: Ensure `tourism_model.tflite` and `preprocessing_params.json` are in `assets/ml/`
- **No recommendations**: Interact with at least 10 places to trigger ML
- **App crashes**: Check Flutter and Python dependencies, and asset paths
- **Debugging**: Use console logs for ML and DB operations

## 📈 Performance

- **Model Size**: ~8KB (TFLite optimized)
- **Inference Time**: <100ms on device
- **Battery/Memory**: Minimal impact

## 🔮 Future Enhancements

- Real-time learning and confidence indicators
- Cloud sync for user preferences
- More advanced analytics and A/B testing

## 📄 License

This project is for educational and demonstration purposes.

**Note:**

- The ML model requires `tourism_model.tflite` and `preprocessing_params.json` in `tourism_app/assets/ml/` for recommendations to work.
- The app will function without ML, but recommendations will be disabled.
