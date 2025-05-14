import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

Future<void> confirmAssetExists() async {
  try {
    // await rootBundle.load('assets/Sound_Recognition.tflite');
    await rootBundle.load('assets/yamnet.tflite');
    print("✅ Model file found in assets!");
  } catch (e) {
    print("❌ Model asset missing or unreadable: $e");
  }
}

Future<void> debugModel() async {
  try {
    final options = InterpreterOptions();
    // final interpreter = await Interpreter.fromAsset('Sound_Recognition.tflite');
    final interpreter = await Interpreter.fromAsset('yamnet.tflite');
    var inputShape = interpreter.getInputTensor(0).shape;
    var inputType = interpreter.getInputTensor(0).type;
    var outputShape = interpreter.getOutputTensor(0).shape;
    var outputType = interpreter.getOutputTensor(0).type;

    print('📊 Input Shape: $inputShape');
    // print('📊 Input Type: $inputType');
    print('📊 Output Shape: $outputShape');
    // print('📊 Output Type: $outputType');

    interpreter.close();
  } catch (e) {
    print("❌ Model debug failed: $e");
  }
}
