// Testing Uploadthing UI 

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/uploadthing_provider.dart';
import 'package:msbridge/widgets/appbar.dart';

class UploadThingTestPage extends StatefulWidget {
  const UploadThingTestPage({super.key});

  @override
  State<UploadThingTestPage> createState() => _UploadThingTestPageState();
}

class _UploadThingTestPageState extends State<UploadThingTestPage> {
  File? _selected;
  String? _uploadedUrl;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    // Optionally copy to temp dir; using picked file directly
    setState(() {
      _selected = File(image.path);
      _uploadedUrl = null;
    });

    final prov = Provider.of<UploadThingProvider>(context, listen: false);
    final url = await prov.uploadImage(_selected!);
    if (!mounted) return;
    setState(() {
      _uploadedUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar:
          const CustomAppBar(title: 'UploadThing Test', showBackButton: true),
      body: Consumer<UploadThingProvider>(
        builder: (context, prov, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: prov.isUploading ? null : _pickAndUpload,
                  child: const Text('Pick & Upload Image'),
                ),
                const SizedBox(height: 16),
                if (_selected != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_selected!, height: 180),
                  ),
                const SizedBox(height: 16),
                if (prov.isUploading)
                  LinearProgressIndicator(value: prov.progress),
                if (prov.error != null) ...[
                  const SizedBox(height: 8),
                  Text(prov.error!, style: TextStyle(color: colorScheme.error)),
                ],
                if (_uploadedUrl != null) ...[
                  const SizedBox(height: 8),
                  SelectableText('URL: $_uploadedUrl'),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
