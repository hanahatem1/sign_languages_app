import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SignLanguageRecognizer extends StatefulWidget {
  @override
  _SignLanguageRecognizerState createState() => _SignLanguageRecognizerState();
}

class _SignLanguageRecognizerState extends State<SignLanguageRecognizer> {
  File? _image;
  String _prediction = '';
  Interpreter? _interpreter;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('sign_language_model.tflite');
      print("✅ Model loaded");
    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() => _image = imageFile);
      await runModelOnImage(imageFile);
    }
  }

  Future<void> runModelOnImage(File imageFile) async {
    if (_interpreter == null) {
      print("❌ Interpreter not loaded.");
      return;
    }

    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      print("❌ Failed to decode image");
      return;
    }

    const int inputSize = 224;
    image = img.copyResize(image, width: inputSize, height: inputSize);

    Float32List input = Float32List(inputSize * inputSize * 3);
    int pixelIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        // The Pixel class in image package stores RGBA values
        // We need to access them using the proper property getters
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        
        input[pixelIndex++] = r / 255.0;  // Red
        input[pixelIndex++] = g / 255.0;  // Green
        input[pixelIndex++] = b / 255.0;  // Blue
      }
    }

    // Convert input to the required 4D shape
    List<List<List<List<double>>>> inputTensor = [
      List.generate(inputSize, (y) => 
        List.generate(inputSize, (x) => 
          List.generate(3, (c) => input[(y * inputSize + x) * 3 + c])
        )
      )
    ];

    var output = List.filled(29, 0.0).reshape([1, 29]);

    _interpreter!.run(inputTensor, output);

    int maxIndex = 0;
    double maxConfidence = output[0][0];
    for (int i = 1; i < output[0].length; i++) {
      if (output[0][i] > maxConfidence) {
        maxConfidence = output[0][i];
        maxIndex = i;
      }
    }

    setState(() {
      _prediction = String.fromCharCode(65 + maxIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ASL Recognizer")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _image != null
                ? Image.file(_image!, height: 250)
                : Placeholder(fallbackHeight: 250),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: Text("Pick Image from Gallery"),
            ),
            SizedBox(height: 20),
            Text(
              _prediction.isNotEmpty ? "🔤 Predicted: $_prediction" : "⏳ No prediction yet",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}