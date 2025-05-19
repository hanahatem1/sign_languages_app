import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final File? image;
  final bool isLoading;

  const ImagePreview({
    Key? key,
    required this.image,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(97, 226, 222, 222),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueGrey,),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (image != null)
              Image.file(
                image!,
                fit: BoxFit.fitHeight,
                width: double.infinity,
                height: double.infinity,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.image,
                    size: 80,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No image selected',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            if (isLoading)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}