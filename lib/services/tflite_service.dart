import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteService {
  Interpreter? _interpreter;
  final List<String> _labels = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'K',
  ];
  static const int imageSize = 224;

  Future<void> loadModel() async {
    try {
      // Load model from assets
      final modelFile = await _getModel();
      _interpreter = await Interpreter.fromFile(modelFile);
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      throw Exception('Failed to load TFLite model');
    }
  }

  Future<File> _getModel() async {
    // Copy the model file from assets to a location where TFLite can access it
    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDir.path}/sign_language_model.tflite';
    final modelFile = File(modelPath);

    if (!await modelFile.exists()) {
      final byteData = await rootBundle.load(
        'assets/sign_language_model.tflite',
      );
      await modelFile.writeAsBytes(byteData.buffer.asUint8List());
    }

    return modelFile;
  }

  Future<Map<String, dynamic>> recognizeImage(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('Interpreter is not initialized');
    }

    // Preprocess the image
    final imageInput = await _preProcessImage(imageFile);

    // Output buffer
    final outputBuffer = List<List<double>>.filled(
      1,
      List<double>.filled(_labels.length, 0.0),
    );

    // Run inference
    _interpreter!.run(imageInput, outputBuffer);

    // Process the results
    int maxIndex = 0;
    double maxProb = outputBuffer[0][0];

    for (int i = 1; i < outputBuffer[0].length; i++) {
      if (outputBuffer[0][i] > maxProb) {
        maxProb = outputBuffer[0][i];
        maxIndex = i;
      }
    }

    return {
      'label': _labels[maxIndex],
      'confidence': maxProb * 100.0, // Convert to percentage
    };
  }

  Future<List<List<List<List<double>>>>> _preProcessImage(
    File imageFile,
  ) async {
    // Read and decode image
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to the required input dimension
    final resizedImage = img.copyResize(
      originalImage,
      width: imageSize,
      height: imageSize,
    );

    // Create input tensor
    final input = List.generate(
      1,
      (_) => List.generate(
        imageSize,
        (_) => List.generate(imageSize, (_) => List.generate(3, (_) => 0.0)),
      ),
    );

    // Normalize pixel values and fill input tensor
    for (int y = 0; y < imageSize; y++) {
      for (int x = 0; x < imageSize; x++) {
        final pixel = resizedImage.getPixel(x, y); // This is a Color object
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    return input;
  }
}
