import 'package:record/record.dart';

class VoiceNoteSettingsModel {
  final VoiceNoteAudioEncoder encoder;
  final int sampleRate;
  final int bitRate;
  final int numChannels;
  final bool autoSaveEnabled;

  const VoiceNoteSettingsModel({
    this.encoder = VoiceNoteAudioEncoder.aacLc,
    this.sampleRate = 44100,
    this.bitRate = 128000,
    this.numChannels = 1,
    this.autoSaveEnabled = true,
  });

  VoiceNoteSettingsModel copyWith({
    VoiceNoteAudioEncoder? encoder,
    int? sampleRate,
    int? bitRate,
    int? numChannels,
    bool? autoSaveEnabled,
  }) {
    return VoiceNoteSettingsModel(
      encoder: encoder ?? this.encoder,
      sampleRate: sampleRate ?? this.sampleRate,
      bitRate: bitRate ?? this.bitRate,
      numChannels: numChannels ?? this.numChannels,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'encoder': encoder.name,
      'sampleRate': sampleRate,
      'bitRate': bitRate,
      'numChannels': numChannels,
      'autoSaveEnabled': autoSaveEnabled,
    };
  }

  factory VoiceNoteSettingsModel.fromMap(Map<String, dynamic> map) {
    return VoiceNoteSettingsModel(
      encoder: VoiceNoteAudioEncoder.values.firstWhere(
        (e) => e.name == map['encoder'],
        orElse: () => VoiceNoteAudioEncoder.aacLc,
      ),
      sampleRate: map['sampleRate']?.toInt() ?? 44100,
      bitRate: map['bitRate']?.toInt() ?? 128000,
      numChannels: map['numChannels']?.toInt() ?? 1,
      autoSaveEnabled: map['autoSaveEnabled'] ?? true,
    );
  }

  @override
  String toString() {
    return 'VoiceNoteSettingsModel(encoder: $encoder, sampleRate: $sampleRate, bitRate: $bitRate, numChannels: $numChannels, autoSaveEnabled: $autoSaveEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceNoteSettingsModel &&
        other.encoder == encoder &&
        other.sampleRate == sampleRate &&
        other.bitRate == bitRate &&
        other.numChannels == numChannels &&
        other.autoSaveEnabled == autoSaveEnabled;
  }

  @override
  int get hashCode {
    return encoder.hashCode ^
        sampleRate.hashCode ^
        bitRate.hashCode ^
        numChannels.hashCode ^
        autoSaveEnabled.hashCode;
  }
}

// Audio encoder enum - using the same values as record package
enum VoiceNoteAudioEncoder {
  aacLc('AAC-LC', 'High quality, good compression'),
  aacEld('AAC-ELD', 'Enhanced low delay, good for real-time'),
  aacHe('AAC-HE', 'High efficiency, smaller file size'),
  opus('Opus', 'Open source, excellent quality'),
  flac('FLAC', 'Lossless compression, larger file size'),
  wav('WAV', 'Uncompressed, largest file size'),
  ;

  const VoiceNoteAudioEncoder(this.displayName, this.description);
  final String displayName;
  final String description;

  // Convert to record package AudioEncoder
  AudioEncoder toRecordEncoder() {
    switch (this) {
      case VoiceNoteAudioEncoder.aacLc:
        return AudioEncoder.aacLc;
      case VoiceNoteAudioEncoder.aacEld:
        return AudioEncoder.aacEld;
      case VoiceNoteAudioEncoder.aacHe:
        return AudioEncoder.aacHe;
      case VoiceNoteAudioEncoder.opus:
        return AudioEncoder.opus;
      case VoiceNoteAudioEncoder.flac:
        return AudioEncoder.flac;
      case VoiceNoteAudioEncoder.wav:
        return AudioEncoder.wav;
    }
  }

  // Create from record package AudioEncoder
  static VoiceNoteAudioEncoder fromRecordEncoder(AudioEncoder encoder) {
    switch (encoder) {
      case AudioEncoder.aacLc:
        return VoiceNoteAudioEncoder.aacLc;
      case AudioEncoder.aacEld:
        return VoiceNoteAudioEncoder.aacEld;
      case AudioEncoder.aacHe:
        return VoiceNoteAudioEncoder.aacHe;
      case AudioEncoder.opus:
        return VoiceNoteAudioEncoder.opus;
      case AudioEncoder.flac:
        return VoiceNoteAudioEncoder.flac;
      case AudioEncoder.wav:
        return VoiceNoteAudioEncoder.wav;
      case AudioEncoder.amrNb:
        return VoiceNoteAudioEncoder.aacLc; // Fallback for unsupported encoder
      case AudioEncoder.amrWb:
        return VoiceNoteAudioEncoder.aacLc; // Fallback for unsupported encoder
      case AudioEncoder.pcm16bits:
        return VoiceNoteAudioEncoder.wav; // PCM16 is closest to WAV
    }
  }
}

// Audio quality presets
enum AudioQuality {
  low('Low Quality', 22050, 64000, 'Smaller files, basic quality'),
  medium('Medium Quality', 44100, 128000, 'Balanced quality and file size'),
  high('High Quality', 48000, 192000, 'Better quality, larger files'),
  lossless('Lossless', 48000, 0, 'Best quality, largest files'),
  ;

  const AudioQuality(
      this.displayName, this.sampleRate, this.bitRate, this.description);
  final String displayName;
  final int sampleRate;
  final int bitRate; // 0 means lossless
  final String description;
}
