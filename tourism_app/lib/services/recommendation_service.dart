import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  Interpreter? _interpreter;
  List<double>? _scalerMean;
  List<double>? _scalerScale;
  List<String>? _labelClasses;

  Future<void> loadModel() async {
    if (_interpreter != null) return; // Already loaded
    final jsonStr =
        await rootBundle.loadString('assets/ml/preprocessing_params.json');
    final params = json.decode(jsonStr);
    _scalerMean = List<double>.from(params['scaler_mean']);
    _scalerScale = List<double>.from(params['scaler_scale']);
    _labelClasses = List<String>.from(params['label_classes']);
    // Remove 'assets/' prefix for tflite_flutter
    _interpreter =
        await Interpreter.fromAsset('assets/ml/tourism_model.tflite');
  }

  String mapModelCategoryToDb(String modelCategory) {
    if (modelCategory.toLowerCase() == 'nature') return 'beach';
    return modelCategory.toLowerCase();
  }

  Future<String?> getRecommendedCategory(List<double> features) async {
    await loadModel();
    print('[RecommendationService] Features for recommendation: $features');
    if (_interpreter == null ||
        _scalerMean == null ||
        _scalerScale == null ||
        _labelClasses == null) return null;

    // Standardize
    final standardized = List<double>.generate(
      features.length,
      (i) => (features[i] - _scalerMean![i]) / _scalerScale![i],
    );

    final input = [standardized];
    final output = List.filled(_labelClasses!.length, 0.0)
        .reshape([1, _labelClasses!.length]);
    _interpreter!.run(input, output);

    final probs = List<double>.from(output[0]);
    final maxIdx = probs.indexOf(probs.reduce((a, b) => a > b ? a : b));
    final predicted = _labelClasses![maxIdx];
    print(
        '[RecommendationService] Model output: $probs, predicted: $predicted, mapped: ${mapModelCategoryToDb(predicted)}');
    return mapModelCategoryToDb(predicted);
  }
}
