import 'dart:convert';

class UserSettingsModel {
  final String userId;
  final DateTime lastUpdated;

  // Theme settings
  final String appTheme;
  final bool dynamicColorsEnabled;

  // Streak settings
  final bool streakEnabled;
  final bool notificationsEnabled;
  final String notificationTime;
  final bool milestoneNotifications;
  final bool urgentReminders;
  final bool dailyReminders;
  final bool soundEnabled;
  final bool vibrationEnabled;

  // App settings
  final bool autoSaveEnabled;
  final bool fingerprintEnabled;
  final bool cloudSyncEnabled;
  final bool versionHistoryEnabled;
  final String selectedAIModel;

  // Templates settings
  final bool templatesEnabled;
  final bool templatesCloudSyncEnabled;
  final int templatesSyncIntervalMinutes;

  // Sync metadata
  final bool isSynced;
  final DateTime? lastSyncedAt;

  UserSettingsModel({
    required this.userId,
    required this.lastUpdated,
    required this.appTheme,
    required this.dynamicColorsEnabled,
    required this.streakEnabled,
    required this.notificationsEnabled,
    required this.notificationTime,
    required this.milestoneNotifications,
    required this.urgentReminders,
    required this.dailyReminders,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.autoSaveEnabled,
    required this.fingerprintEnabled,
    required this.cloudSyncEnabled,
    required this.versionHistoryEnabled,
    required this.selectedAIModel,
    this.templatesEnabled = true,
    this.templatesCloudSyncEnabled = true,
    this.templatesSyncIntervalMinutes = 0,
    this.isSynced = false,
    this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lastUpdated': lastUpdated.toIso8601String(),
      'appTheme': appTheme,
      'dynamicColorsEnabled': dynamicColorsEnabled,
      'streakEnabled': streakEnabled,
      'notificationsEnabled': notificationsEnabled,
      'notificationTime': notificationTime,
      'milestoneNotifications': milestoneNotifications,
      'urgentReminders': urgentReminders,
      'dailyReminders': dailyReminders,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'autoSaveEnabled': autoSaveEnabled,
      'fingerprintEnabled': fingerprintEnabled,
      'cloudSyncEnabled': cloudSyncEnabled,
      'versionHistoryEnabled': versionHistoryEnabled,
      'selectedAIModel': selectedAIModel,
      'templatesEnabled': templatesEnabled,
      'templatesCloudSyncEnabled': templatesCloudSyncEnabled,
      'templatesSyncIntervalMinutes': templatesSyncIntervalMinutes,
      'isSynced': isSynced,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      userId: map['userId'] ?? '',
      lastUpdated: DateTime.parse(
          map['lastUpdated'] ?? DateTime.now().toIso8601String()),
      appTheme: map['appTheme'] ?? 'dark',
      dynamicColorsEnabled: map['dynamicColorsEnabled'] ?? false,
      streakEnabled: map['streakEnabled'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? false,
      notificationTime: map['notificationTime'] ?? '09:00',
      milestoneNotifications: map['milestoneNotifications'] ?? false,
      urgentReminders: map['urgentReminders'] ?? false,
      dailyReminders: map['dailyReminders'] ?? false,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      autoSaveEnabled: map['autoSaveEnabled'] ?? true,
      fingerprintEnabled: map['fingerprintEnabled'] ?? false,
      cloudSyncEnabled: map['cloudSyncEnabled'] ?? true,
      versionHistoryEnabled: map['versionHistoryEnabled'] ?? true,
      selectedAIModel: map['selectedAIModel'] ?? 'gpt-3.5-turbo',
      templatesEnabled: map['templatesEnabled'] ?? true,
      templatesCloudSyncEnabled: map['templatesCloudSyncEnabled'] ?? true,
      templatesSyncIntervalMinutes: map['templatesSyncIntervalMinutes'] ?? 0,
      isSynced: map['isSynced'] ?? false,
      lastSyncedAt: map['lastSyncedAt'] != null
          ? DateTime.parse(map['lastSyncedAt'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserSettingsModel.fromJson(String source) =>
      UserSettingsModel.fromMap(json.decode(source));

  UserSettingsModel copyWith({
    String? userId,
    DateTime? lastUpdated,
    String? appTheme,
    bool? dynamicColorsEnabled,
    bool? streakEnabled,
    bool? notificationsEnabled,
    String? notificationTime,
    bool? milestoneNotifications,
    bool? urgentReminders,
    bool? dailyReminders,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoSaveEnabled,
    bool? fingerprintEnabled,
    bool? pinLockEnabled, // Added to copyWith
    bool? cloudSyncEnabled,
    bool? versionHistoryEnabled,
    String? selectedAIModel,
    bool? templatesEnabled,
    bool? templatesCloudSyncEnabled,
    int? templatesSyncIntervalMinutes,
    bool? isSynced,
    DateTime? lastSyncedAt,
  }) {
    return UserSettingsModel(
      userId: userId ?? this.userId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      appTheme: appTheme ?? this.appTheme,
      dynamicColorsEnabled: dynamicColorsEnabled ?? this.dynamicColorsEnabled,
      streakEnabled: streakEnabled ?? this.streakEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      milestoneNotifications:
          milestoneNotifications ?? this.milestoneNotifications,
      urgentReminders: urgentReminders ?? this.urgentReminders,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      fingerprintEnabled: fingerprintEnabled ?? this.fingerprintEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      versionHistoryEnabled:
          versionHistoryEnabled ?? this.versionHistoryEnabled,
      selectedAIModel: selectedAIModel ?? this.selectedAIModel,
      templatesEnabled: templatesEnabled ?? this.templatesEnabled,
      templatesCloudSyncEnabled:
          templatesCloudSyncEnabled ?? this.templatesCloudSyncEnabled,
      templatesSyncIntervalMinutes:
          templatesSyncIntervalMinutes ?? this.templatesSyncIntervalMinutes,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
