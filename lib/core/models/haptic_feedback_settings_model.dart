class HapticFeedbackSettingsModel {
  final bool navigationEnabled;
  final bool buttonEnabled;
  final bool gestureEnabled;
  final HapticFeedbackIntensity intensity;

  const HapticFeedbackSettingsModel({
    this.navigationEnabled = true,
    this.buttonEnabled = true,
    this.gestureEnabled = true,
    this.intensity = HapticFeedbackIntensity.medium,
  });

  HapticFeedbackSettingsModel copyWith({
    bool? navigationEnabled,
    bool? buttonEnabled,
    bool? gestureEnabled,
    HapticFeedbackIntensity? intensity,
  }) {
    return HapticFeedbackSettingsModel(
      navigationEnabled: navigationEnabled ?? this.navigationEnabled,
      buttonEnabled: buttonEnabled ?? this.buttonEnabled,
      gestureEnabled: gestureEnabled ?? this.gestureEnabled,
      intensity: intensity ?? this.intensity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'navigationEnabled': navigationEnabled,
      'buttonEnabled': buttonEnabled,
      'gestureEnabled': gestureEnabled,
      'intensity': intensity.name,
    };
  }

  factory HapticFeedbackSettingsModel.fromMap(Map<String, dynamic> map) {
    return HapticFeedbackSettingsModel(
      navigationEnabled: map['navigationEnabled'] ?? true,
      buttonEnabled: map['buttonEnabled'] ?? true,
      gestureEnabled: map['gestureEnabled'] ?? true,
      intensity: HapticFeedbackIntensity.values.firstWhere(
        (e) => e.name == map['intensity'],
        orElse: () => HapticFeedbackIntensity.medium,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HapticFeedbackSettingsModel &&
        other.navigationEnabled == navigationEnabled &&
        other.buttonEnabled == buttonEnabled &&
        other.gestureEnabled == gestureEnabled &&
        other.intensity == intensity;
  }

  @override
  int get hashCode {
    return navigationEnabled.hashCode ^
        buttonEnabled.hashCode ^
        gestureEnabled.hashCode ^
        intensity.hashCode;
  }
}

enum HapticFeedbackIntensity {
  light('Light', 'Subtle feedback'),
  medium('Medium', 'Standard feedback'),
  heavy('Heavy', 'Strong feedback'),
  ;

  const HapticFeedbackIntensity(this.displayName, this.description);

  final String displayName;
  final String description;
}
