import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Picker App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ImagePickerPage(),
    );
  }
}

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});
  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  File? _imageFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Image'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile != null
                ? Image.file(_imageFile!, height: 250)
                : const Text("No image selected"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text("Pick from Gallery"),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Capture from Camera"),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}
