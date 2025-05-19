import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_languages_app/providers/sign_recognation_provider.dart';
import 'package:sign_languages_app/widgets/image_perview.dart';

import '../widgets/result_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SignRecognitionProvider>().initializeModel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Sign Language Recognizer',style: TextStyle(color: Colors.white,fontSize: 25,fontWeight: FontWeight.bold),),
        centerTitle: false,
        
      ),
      body: Consumer<SignRecognitionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.modelLoaded) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading model...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Uploading your photo in this box below',
                    style: TextStyle(fontSize: 20,color: Colors.blueGrey ,fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ImagePreview(
                    image: provider.image,
                    isLoading: provider.isLoading,
                  ),
                  const SizedBox(height: 20),
                  ResultDisplay(
                    recognizedSign: provider.recognizedSign,
                    confidence: provider.confidence,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                     /* ElevatedButton.icon(
                        onPressed: provider.getImageFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),*/
                      ElevatedButton.icon(
                        onPressed: provider.getImageFromGallery,
                        icon: const Icon(Icons.photo_library,color: Colors.blueGrey,),
                        label: const Text('Upload Your Sign',style: TextStyle(color: Colors.blueGrey),),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (provider.image != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: provider.resetRecognition,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}