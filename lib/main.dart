import 'package:flutter/material.dart';
import 'package:sign_languages_app/sign_languages_recognizer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignLanguageRecognizer(),
    );
  }
}