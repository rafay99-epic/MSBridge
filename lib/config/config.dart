class FirebaseConfig {
  static const String apiKey = '';
  static const String appId = '';
  static const String messagingSenderId = '';
  static const String projectId = '';
  static const String storageBucket = '';
  static const String iosBundleId = '';
}

class APIConfig {
  static const String notesApiEndpoint = 'https://www.rafay99.com/api/ms_notes';
  static const String aboutAuthorApiEndpoint = '/api/author';
  static const String baseURL = 'https://www.rafay99.com';
}

class NoteSummaryAPI {
  static const String apiKey = "";
}

class ChatAPI {
  static const String apiKey = "";
}

class URL {
  static const String prravicyPolicy = 'https://msbridge.rafay99.com/privacy';
  static const String termsOfService = 'https://msbridge.rafay99.com/terms';
}

class APKFile {
  static const String apkFile =
      'https://msbridge.rafay99.com/downloads/ms-bridge-stable.apk';
  static const String betaApkFile =
      'https://msbridge.rafay99.com/downloads/ms-bridge-beta.apk';
}

class UploadThingConfig {
  // Put your UploadThing API key here (or load from env/secrets at runtime)
  static const String apiKey = '';
}

class BugfenderConfig {
  static const String apiKey = "";
}

class UpdateConfig {
  // Change this URL to switch between dev and production
  static const String apiUrl = 'https://msbridge.rafay99.com/api';

  // API key for authentication
  static const String msBridgeApiKey = '';

  static const Duration checkInterval = Duration(hours: 6);
  static const Duration healthCheckTimeout = Duration(seconds: 10);
  static const Duration updateCheckTimeout = Duration(seconds: 15);

  static const String mode = "development";
}
