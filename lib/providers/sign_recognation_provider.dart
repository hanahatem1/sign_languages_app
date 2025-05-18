import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/tflite_service.dart';

class SignRecognitionProvider with ChangeNotifier {
  File? _image;
  bool _isLoading = false;
  String _recognizedSign = '';
  double _confidence = 0.0;
  final TFLiteService _tfLiteService = TFLiteService();
  bool _modelLoaded = false;

  File? get image => _image;
  bool get isLoading => _isLoading;
  String get recognizedSign => _recognizedSign;
  double get confidence => _confidence;
  bool get modelLoaded => _modelLoaded;

  Future<void> initializeModel() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _tfLiteService.loadModel();
      _modelLoaded = true;
    } catch (e) {
      debugPrint('Failed to load model: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _image = File(pickedFile.path);
      _recognizedSign = '';
      _confidence = 0.0;
      notifyListeners();
      
      await recognizeSign();
    }
  }

  Future<void> getImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _image = File(pickedFile.path);
      _recognizedSign = '';
      _confidence = 0.0;
      notifyListeners();
      
      await recognizeSign();
    }
  }

  Future<void> recognizeSign() async {
    if (_image == null || !_modelLoaded) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _tfLiteService.recognizeImage(_image!);
      _recognizedSign = result['label'];
      _confidence = result['confidence'];
    } catch (e) {
      debugPrint('Error recognizing sign: $e');
      _recognizedSign = 'Error recognizing sign';
      _confidence = 0.0;
    }

    _isLoading = false;
    notifyListeners();
  }

  void resetRecognition() {
    _image = null;
    _recognizedSign = '';
    _confidence = 0.0;
    notifyListeners();
  }
}