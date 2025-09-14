import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:msbridge/core/services/voice_note/voice_note_service.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/widgets/custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/voice_note_settings_provider.dart';
import 'dart:io';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(VoiceNoteModel)? onRecordingComplete;
  final Function(String)? onError;
  final Function()? onRecordingCancelled;
  final bool showTitleInput;
  final String? initialTitle;

  const VoiceRecorderWidget({
    super.key,
    this.onRecordingComplete,
    this.onError,
    this.onRecordingCancelled,
    this.showTitleInput = true,
    this.initialTitle,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final VoiceNoteService _voiceNoteService = VoiceNoteService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isSaving = false;
  bool _isRecording = false;
  String? _recordedFilePath;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Check microphone permission
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        final permission = await Permission.microphone.request();
        if (!permission.isGranted) {
          if (mounted) {
            CustomSnackBar.show(
              context,
              'Microphone permission is required to record voice notes',
              SnackBarType.error,
            );
          }
          return;
        }
      }

      // Check if audio recorder is available
      final isRecording = await _audioRecorder.isRecording();
      if (isRecording) {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Already recording. Please stop current recording first.',
            SnackBarType.warning,
          );
        }
        return;
      }

      final directory = await getTemporaryDirectory();

      final settingsProvider =
          Provider.of<VoiceNoteSettingsProvider>(context, listen: false);
      final settings = settingsProvider.settings;

      final fileExtension = settings.encoder.getFileExtension();
      final filePath =
          '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _audioRecorder.start(
        RecordConfig(
          encoder: settings.encoder.toRecordEncoder(),
          sampleRate: settings.sampleRate,
          bitRate: settings.bitRate,
          numChannels: settings.numChannels,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _startTimer();

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Recording started! Speak into the microphone.',
          SnackBarType.info,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to start recording: $e',
          SnackBarType.error,
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });

      if (path != null) {
        final isValidFile = await _testRecordedFile(path);

        // Check auto-save setting
        final settingsProvider =
            Provider.of<VoiceNoteSettingsProvider>(context, listen: false);
        final settings = settingsProvider.settings;

        if (settings.autoSaveEnabled && isValidFile) {
          // Auto-save is enabled and file is valid, save immediately
          await _saveVoiceNote(showSuccessToast: false);

          if (mounted) {
            CustomSnackBar.show(
              context,
              'Recording completed and saved automatically!',
              SnackBarType.success,
            );
          }
        } else if (mounted) {
          CustomSnackBar.show(
            context,
            'Recording completed.',
            SnackBarType.info,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to stop recording: $e',
          SnackBarType.error,
        );
      }
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration =
              Duration(seconds: _recordingDuration.inSeconds + 1);
        });
        _startTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<bool> _testRecordedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();

        if (fileSize == 0) {
          if (mounted) {
            CustomSnackBar.show(
              context,
              'Warning: Recorded file is empty. This might be an emulator issue.',
              SnackBarType.warning,
            );
          }
          return false;
        } else {
          if (mounted) {
            CustomSnackBar.show(
              context,
              'File appears to have content: $fileSize bytes',
              SnackBarType.info,
            );
          }
          return true;
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Error: Recording file was not created.',
            SnackBarType.error,
          );
        }
        return false;
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error checking file: $e', StackTrace.current.toString());
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error checking recorded file: $e',
          SnackBarType.error,
        );
      }
      return false;
    }
  }

  Future<void> _saveVoiceNoteWithValidation() async {
    if (_recordedFilePath == null) return;

    final isValidFile = await _testRecordedFile(_recordedFilePath!);
    if (!isValidFile) {
      return; // Don't save if file validation fails
    }

    await _saveVoiceNote();
  }

  Future<void> _saveVoiceNote({bool showSuccessToast = true}) async {
    if (_recordedFilePath == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        FlutterBugfender.sendCrash(
            'User not authenticated', StackTrace.current.toString());
        throw Exception('User not authenticated');
      }

      final title = _titleController.text.trim().isEmpty
          ? 'Voice Note ${DateTime.now().millisecondsSinceEpoch}'
          : _titleController.text.trim();

      // Get the current settings to determine file extension
      final settingsProvider =
          Provider.of<VoiceNoteSettingsProvider>(context, listen: false);
      final settings = settingsProvider.settings;
      final fileExtension = settings.encoder.getFileExtension();

      final voiceNote = await _voiceNoteService.saveVoiceNote(
        audioFilePath: _recordedFilePath!,
        title: title,
        userId: user.uid,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        fileExtension: fileExtension,
      );

      if (widget.onRecordingComplete != null) {
        widget.onRecordingComplete!(voiceNote);
      }

      if (mounted && showSuccessToast) {
        CustomSnackBar.show(
          context,
          'Voice note saved successfully!',
          SnackBarType.success,
        );
      }

      // Reset the form
      _resetForm();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Error saving voice note: $e', StackTrace.current.toString());
      if (widget.onError != null) {
        widget.onError!(e.toString());
      }

      if (mounted) {
        CustomSnackBar.show(
          context,
          'Error saving voice note: $e',
          SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _recordedFilePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title input
          if (widget.showTitleInput) ...[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Voice Note Title',
                hintText: 'Enter a title for your voice note',
                prefixIcon: Icon(
                  Icons.title,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2.0,
                  ),
                ),
              ),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16.0),
          ],

          // Description input
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              hintText: 'Add a description for your voice note',
              prefixIcon: Icon(
                Icons.description,
                color: theme.colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2.0,
                ),
              ),
            ),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24.0),

          // Recording widget
          if (_recordedFilePath == null)
            Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: _isRecording
                    ? theme.colorScheme.errorContainer.withOpacity(0.1)
                    : theme.colorScheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: _isRecording
                      ? theme.colorScheme.error.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Recording indicator
                  if (_isRecording) ...[
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.error.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 48,
                        color: theme.colorScheme.onError,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Recording...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDuration(_recordingDuration),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.error,
                          fontFamily: 'Poppins',
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop, size: 24),
                        label: const Text(
                          'Stop Recording',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Text(
                      'Ready to Record',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Tap the button below to start recording your voice note',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startRecording,
                        icon: const Icon(Icons.mic, size: 24),
                        label: const Text(
                          'Start Recording',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else ...[
            // Recording completed - show save options or auto-save status
            Consumer<VoiceNoteSettingsProvider>(
              builder: (context, settingsProvider, child) {
                final settings = settingsProvider.settings;

                if (settings.autoSaveEnabled) {
                  // Auto-save enabled - show saving status or completion
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isSaving
                              ? Icons.hourglass_empty
                              : Icons.check_circle,
                          size: 48,
                          color: _isSaving
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          _isSaving ? 'Auto-Saving...' : 'Recording Saved!',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (_isSaving) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            'Your voice note is being saved automatically',
                            style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16.0),
                        if (!_isSaving)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _resetForm,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                'Record Another',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                side: BorderSide(
                                    color: theme.colorScheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  // Auto-save disabled - show manual save options
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mic,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Recording Complete!',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Save button
                            ElevatedButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : _saveVoiceNoteWithValidation,
                              icon: _isSaving
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isSaving ? 'Saving...' : 'Save',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),

                            // Re-record button
                            OutlinedButton.icon(
                              onPressed: _isSaving ? null : _resetForm,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                'Re-record',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                side: BorderSide(
                                    color: theme.colorScheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
