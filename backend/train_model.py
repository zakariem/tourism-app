import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns
import os
import json

class TourismMLModel:
    def __init__(self):
        self.model = None
        self.label_encoder = LabelEncoder()
        self.scaler = StandardScaler()
        self.feature_columns = ['beach_clicks', 'historical_clicks', 'cultural_clicks', 
                               'religious_clicks', 'avg_view_time', 'language_encoded']
        
    def load_and_preprocess_data(self, csv_path):
        """Load and preprocess the tourism user behavior data"""
        print("📊 Loading dataset...")
        df = pd.read_csv(csv_path)
        print(f"✅ Loaded {len(df)} records")
        
        # Encode language (SO=0, EN=1)
        df['language_encoded'] = (df['language'] == 'EN').astype(int)
        
        # Prepare features and target
        X = df[self.feature_columns].values
        y = df['preference'].values
        
        # Encode target labels
        y_encoded = self.label_encoder.fit_transform(y)
        
        print(f"🎯 Target classes: {self.label_encoder.classes_}")
        print(f"📈 Feature shape: {X.shape}")
        
        return X, y_encoded
    
    def build_model(self, input_shape, num_classes):
        """Build the neural network model"""
        print("🏗️ Building neural network model...")
        
        model = tf.keras.Sequential([
            tf.keras.layers.Dense(64, activation='relu', input_shape=input_shape),
            tf.keras.layers.Dropout(0.3),
            tf.keras.layers.Dense(32, activation='relu'),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(16, activation='relu'),
            tf.keras.layers.Dense(num_classes, activation='softmax')
        ])
        
        model.compile(
            optimizer='adam',
            loss='sparse_categorical_crossentropy',
            metrics=['accuracy']
        )
        
        print("✅ Model built successfully")
        return model
    
    def train_model(self, X, y, test_size=0.2, random_state=42):
        """Train the model with the given data"""
        print("🚀 Starting model training...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=random_state, stratify=y
        )
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        print(f"📚 Training samples: {len(X_train)}")
        print(f"🧪 Test samples: {len(X_test)}")
        
        # Build and train model
        self.model = self.build_model((X_train.shape[1],), len(self.label_encoder.classes_))
        
        # Early stopping to prevent overfitting
        early_stopping = tf.keras.callbacks.EarlyStopping(
            monitor='val_loss', patience=10, restore_best_weights=True
        )
        
        # Train the model
        history = self.model.fit(
            X_train_scaled, y_train,
            epochs=100,
            batch_size=32,
            validation_data=(X_test_scaled, y_test),
            callbacks=[early_stopping],
            verbose=1
        )
        
        # Evaluate model
        test_loss, test_accuracy = self.model.evaluate(X_test_scaled, y_test, verbose=0)
        print(f"🎯 Test Accuracy: {test_accuracy:.4f}")
        
        # Predictions for detailed analysis
        y_pred = self.model.predict(X_test_scaled)
        y_pred_classes = np.argmax(y_pred, axis=1)
        
        # Print classification report
        print("\n📊 Classification Report:")
        print(classification_report(y_test, y_pred_classes, 
                                  target_names=self.label_encoder.classes_))
        
        return history, (X_test_scaled, y_test, y_pred)
    
    def save_model(self, model_path='tourism_model.tflite'):
        """Save the trained model as TensorFlow Lite format"""
        print(f"💾 Saving model to {model_path}...")
        
        # Convert to TensorFlow Lite
        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()
        
        # Save the model
        with open(model_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"✅ Model saved successfully: {model_path}")
        
        # Save preprocessing parameters
        self.save_preprocessing_params()
    
    def save_preprocessing_params(self):
        """Save preprocessing parameters for inference"""
        import pickle
        
        params = {
            'label_encoder': self.label_encoder,
            'scaler': self.scaler,
            'feature_columns': self.feature_columns
        }
        
        with open('preprocessing_params.pkl', 'wb') as f:
            pickle.dump(params, f)
        
        print("✅ Preprocessing parameters saved")
    
    def plot_training_history(self, history):
        """Plot training history"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))
        
        # Plot accuracy
        ax1.plot(history.history['accuracy'], label='Training Accuracy')
        ax1.plot(history.history['val_accuracy'], label='Validation Accuracy')
        ax1.set_title('Model Accuracy')
        ax1.set_xlabel('Epoch')
        ax1.set_ylabel('Accuracy')
        ax1.legend()
        ax1.grid(True)
        
        # Plot loss
        ax2.plot(history.history['loss'], label='Training Loss')
        ax2.plot(history.history['val_loss'], label='Validation Loss')
        ax2.set_title('Model Loss')
        ax2.set_xlabel('Epoch')
        ax2.set_ylabel('Loss')
        ax2.legend()
        ax2.grid(True)
        
        plt.tight_layout()
        plt.savefig('training_history.png', dpi=300, bbox_inches='tight')
        print("📊 Training history plot saved as 'training_history.png'")
    
    def plot_confusion_matrix(self, y_true, y_pred):
        """Plot confusion matrix"""
        cm = confusion_matrix(y_true, y_pred)
        
        plt.figure(figsize=(8, 6))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                   xticklabels=self.label_encoder.classes_,
                   yticklabels=self.label_encoder.classes_)
        plt.title('Confusion Matrix')
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.tight_layout()
        plt.savefig('confusion_matrix.png', dpi=300, bbox_inches='tight')
        print("📊 Confusion matrix saved as 'confusion_matrix.png'")

    def export_preprocessing_to_json(self, json_path='preprocessing_params.json'):
        params = {
            'scaler_mean': self.scaler.mean_.tolist(),
            'scaler_scale': self.scaler.scale_.tolist(),
            'label_classes': self.label_encoder.classes_.tolist(),
            'feature_columns': self.feature_columns
        }
        with open(json_path, 'w') as f:
            json.dump(params, f)
        print(f"✅ Preprocessing parameters exported to {json_path}")

def main():
    """Main training function"""
    print("🎯 Tourism ML Model Training")
    print("=" * 50)
    
    # Initialize model
    ml_model = TourismMLModel()
    
    # Load and preprocess data
    X, y = ml_model.load_and_preprocess_data('tourism_user_behavior.csv')
    
    # Train model
    history, (X_test, y_test, y_pred) = ml_model.train_model(X, y)
    
    # Save model
    ml_model.save_model()
    
    # Plot results
    ml_model.plot_training_history(history)
    ml_model.plot_confusion_matrix(y_test, np.argmax(y_pred, axis=1))
    
    # Export preprocessing parameters
    ml_model.export_preprocessing_to_json()
    
    print("\n🎉 Training completed successfully!")
    print("📁 Generated files:")
    print("  - tourism_model.tflite (TensorFlow Lite model)")
    print("  - preprocessing_params.pkl (Preprocessing parameters)")
    print("  - training_history.png (Training plots)")
    print("  - confusion_matrix.png (Confusion matrix)")

if __name__ == "__main__":
    main() 