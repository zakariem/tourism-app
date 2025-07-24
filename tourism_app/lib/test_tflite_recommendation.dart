import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(const MaterialApp(
      home: Scaffold(body: Center(child: TFLiteTestWidget()))));
}

class TFLiteTestWidget extends StatefulWidget {
  const TFLiteTestWidget({Key? key}) : super(key: key);

  @override
  State<TFLiteTestWidget> createState() => _TFLiteTestWidgetState();
}

class _TFLiteTestWidgetState extends State<TFLiteTestWidget> {
  String result = "Running test...";

  @override
  void initState() {
    super.initState();
    runTFLiteTest();
  }

  Future<void> runTFLiteTest() async {
    try {
      // Load JSON preprocessing parameters
      final jsonStr =
          await rootBundle.loadString('assets/ml/preprocessing_params.json');
      final params = json.decode(jsonStr);
      final scalerMean = List<double>.from(params['scaler_mean']);
      final scalerScale = List<double>.from(params['scaler_scale']);
      final labelClasses = List<String>.from(params['label_classes']);
      // ignore: unused_local_variable
      final featureColumns = List<String>.from(params['feature_columns']);

      // Correct asset path: do not include 'assets/' prefix
      final interpreter =
          await Interpreter.fromAsset('assets/ml/tourism_model.tflite');

      final userFeatures = [5, 2, 1, 0, 120.0, 1];
      final standardized = List<double>.generate(
        userFeatures.length,
        (i) => (userFeatures[i] - scalerMean[i]) / scalerScale[i],
      );

      final input = [standardized];
      final output = List.filled(labelClasses.length, 0.0)
          .reshape([1, labelClasses.length]);

      interpreter.run(input, output);

      // Cast output[0] to List<double>
      final probs = List<double>.from(output[0]);
      final maxIdx = probs.indexOf(probs.reduce((a, b) => a > b ? a : b));
      final predicted = labelClasses[maxIdx];
      print("userFeatures: $userFeatures");
      print("standardized: $standardized");
      print("probs: $probs");
      print("maxIdx: $maxIdx");
      print("predicted: $predicted");
      setState(() {
        result = '''
User features: $userFeatures
Standardized: $standardized
Model output (probs): $probs
Predicted recommendation: $predicted
''';
      });

      interpreter.close();
    } catch (e, st) {
      setState(() {
        result = 'Error: $e\n$st';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Text(result));
  }
}
