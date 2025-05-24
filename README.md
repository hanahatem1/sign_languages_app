# Sign Language Recognition App

This Flutter app lets users **upload an image** of a hand sign and predicts the corresponding **sign language character** using a **CNN model** integrated via TFLite.

## How it works:
- Upload an image of a hand showing a sign language letter.
- The app uses a **TensorFlow Lite CNN model** to analyze the image.
- It returns the predicted sign language character 

## Features:
- Simple image upload interface using `image_picker`.
- Runs the CNN model locally with `tflite_flutter`.
- Uses `provider` for state management.
- Handles file storage paths with `path_provider`.
- Splash screen integration via `flutter_native_splash`.
- Image manipulation support with the `image` package.

## Technologies and Packages Used:
- Flutter SDK (>=3.7.2)
- [image_picker](https://pub.dev/packages/image_picker): For selecting/uploading images.
- [tflite_flutter](https://pub.dev/packages/tflite_flutter): To run TensorFlow Lite models.
- [provider](https://pub.dev/packages/provider): State management.
- [path_provider](https://pub.dev/packages/path_provider): Access device file storage.
- [flutter_native_splash](https://pub.dev/packages/flutter_native_splash): Native splash screen support.
- [image](https://pub.dev/packages/image): Image processing utilities.
- [cupertino_icons](https://pub.dev/packages/cupertino_icons): iOS style icons.

## Assets:
- The TensorFlow Lite model file is located at `assets/sign_language_model.tflite`.

## Clone Repository

To get a local copy of this project, run the following command in your terminal:

```bash
git clone https://github.com/hanahatem1/sign_languages_app
