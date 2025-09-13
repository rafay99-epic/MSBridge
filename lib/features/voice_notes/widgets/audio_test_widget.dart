import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioTestWidget extends StatefulWidget {
  const AudioTestWidget({super.key});

  @override
  State<AudioTestWidget> createState() => _AudioTestWidgetState();
}

class _AudioTestWidgetState extends State<AudioTestWidget> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedPath;
  String _status = 'Ready to test';

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _testRecording() async {
    try {
      setState(() {
        _status = 'Checking permissions...';
      });

      // Check permissions
      final hasPermission = await _audioRecorder.hasPermission();
      print('Has permission: $hasPermission');

      if (!hasPermission) {
        final permission = await Permission.microphone.request();
        print('Permission result: ${permission.isGranted}');
        if (!permission.isGranted) {
          setState(() {
            _status = 'Permission denied';
          });
          return;
        }
      }

      // Check if already recording
      final isRecording = await _audioRecorder.isRecording();
      print('Is recording: $isRecording');

      if (isRecording) {
        setState(() {
          _status = 'Already recording';
        });
        return;
      }

      // Get directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/test_recording.m4a';
      print('Recording to: $filePath');

      setState(() {
        _status = 'Starting recording...';
      });

      // Start recording with basic config
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _status = 'Recording... Speak now!';
      });

      print('Recording started');
    } catch (e) {
      print('Recording error: $e');
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _status = 'Stopping recording...';
      });

      final path = await _audioRecorder.stop();
      print('Recording stopped. Path: $path');

      setState(() {
        _isRecording = false;
        _recordedPath = path;
        _status = 'Recording saved to: $path';
      });
    } catch (e) {
      print('Stop error: $e');
      setState(() {
        _status = 'Stop error: $e';
        _isRecording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recording Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Status: $_status',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (_recordedPath != null)
              Text(
                'File: $_recordedPath',
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _testRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Instructions:\n'
              '1. Tap "Start Recording"\n'
              '2. Speak into your device microphone\n'
              '3. Tap "Stop Recording"\n'
              '4. Check the console for debug info\n'
              '5. Check if the file was created',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
