import 'dart:convert';
import 'package:flutter/services.dart';

class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  // ML-related fields (will be null when tflite_flutter is not available)
  dynamic _interpreter;
  List<double>? _scalerMean;
  List<double>? _scalerScale;
  List<String>? _labelClasses;
  bool _mlAvailable = false;

  Future<void> loadModel() async {
    if (_interpreter != null) return; // Already loaded

    try {
      // Try to load preprocessing parameters
      final jsonStr =
          await rootBundle.loadString('assets/ml/preprocessing_params.json');
      final params = json.decode(jsonStr);
      _scalerMean = List<double>.from(params['scaler_mean']);
      _scalerScale = List<double>.from(params['scaler_scale']);
      _labelClasses = List<String>.from(params['label_classes']);

      // Try to load the ML model (this will fail if tflite_flutter is not available)
      await _loadInterpreter();
      _mlAvailable = true;
      print('[RecommendationService] ML model loaded successfully');
    } catch (e) {
      print('[RecommendationService] ML not available: $e');
      _mlAvailable = false;
    }
  }

  Future<void> _loadInterpreter() async {
    // This will only work if tflite_flutter is available
    try {
      // Dynamic import to avoid compilation errors when package is not available
      final tflite = await _getTfliteFlutter();
      if (tflite != null) {
        _interpreter = await tflite['Interpreter']
            .fromAsset('assets/ml/tourism_model.tflite');
      }
    } catch (e) {
      print('[RecommendationService] Failed to load interpreter: $e');
      _interpreter = null;
    }
  }

  Future<dynamic> _getTfliteFlutter() async {
    try {
      // Try to dynamically import tflite_flutter
      // This will fail gracefully if the package is not available
      return null; // For now, return null to disable ML
    } catch (e) {
      return null;
    }
  }

  String mapModelCategoryToDb(String modelCategory) {
    if (modelCategory.toLowerCase() == 'nature') return 'beach';
    return modelCategory.toLowerCase();
  }

  Future<String?> getRecommendedCategory(List<double> features) async {
    await loadModel();

    // If ML is not available, use a simple fallback recommendation
    if (!_mlAvailable || _interpreter == null) {
      return _getFallbackRecommendation(features);
    }

    try {
      // Standardize
      final standardized = List<double>.generate(
        features.length,
        (i) => (features[i] - _scalerMean![i]) / _scalerScale![i],
      );

      final input = [standardized];
      final output = List.filled(_labelClasses!.length, 0.0);

      // Create a 2D list for output (simulating reshape)
      final output2D = [output];

      _interpreter!.run(input, output2D);

      final probs = List<double>.from(output2D[0]);
      final maxIdx = probs.indexOf(probs.reduce((a, b) => a > b ? a : b));
      final predicted = _labelClasses![maxIdx];
      print(
          '[RecommendationService] Model output: $probs, predicted: $predicted, mapped: ${mapModelCategoryToDb(predicted)}');
      return mapModelCategoryToDb(predicted);
    } catch (e) {
      print('[RecommendationService] ML prediction failed: $e');
      return _getFallbackRecommendation(features);
    }
  }

  String? _getFallbackRecommendation(List<double> features) {
    // Simple fallback logic based on user behavior
    // features: [beach_clicks, historical_clicks, cultural_clicks, religious_clicks, view_time, total_clicks]

    if (features.length >= 4) {
      final beachClicks = features[0];
      final historicalClicks = features[1];
      final culturalClicks = features[2];
      final religiousClicks = features[3];

      // Simple logic: recommend the category with most clicks
      if (beachClicks > historicalClicks &&
          beachClicks > culturalClicks &&
          beachClicks > religiousClicks) {
        return 'beach';
      } else if (historicalClicks > culturalClicks &&
          historicalClicks > religiousClicks) {
        return 'historical';
      } else if (culturalClicks > religiousClicks) {
        return 'cultural';
      } else {
        return 'religious';
      }
    }

    // Default recommendation
    return 'beach';
  }
}
