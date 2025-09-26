# MS Bridge – Developer Documentation

Welcome to the developer guide for **MS Bridge**.  
This document covers setup, project architecture, coding standards, and 
guidelines for contributing to the project.

If you are looking for end-user information, please refer to the 
[README.md](./README.md).

## 1. Tech Stack

- **Framework**: Flutter 3.25.1+
- **State Management**: Provider
- **Databases**: Hive (offline) + Firebase Firestore (cloud sync)
- **Authentication**: Firebase Auth
- **Background Jobs**: Workmanager + Firebase Cloud Functions
- **AI APIs**: Google Generative AI
- **Other Dependencies**: File Picker, Quill editor, PDF/Markdown rendering, 
  Notifications, Audio recording, Crashlytics


## 2. Project Structure

```
lib/
├── config/        # App configuration & feature flags
├── core/          # Business logic, data layer, shared utilities
│   ├── api/       # API integration
│   ├── database/  # Hive models, adapters
│   ├── models/    # Entity / model classes
│   ├── provider/  # Provider state managers
│   ├── repo/      # Repository implementation
│   ├── services/  # Sync, backup, notifications, updates
│   ├── utils/     # Common utilities
│   └── wrapper/   # Wrappers (lock, auth, etc.)
├── features/      # UI organized by feature (auth, notes, AI chat, settings, etc.)
├── theme/         # Colors & theming
├── widgets/       # Shared UI widgets
└── main.dart      # Entry point

```

### Layered Pattern

- **Provider** → State & UI binding  
- **Repo** → Business logic & persistence  
- **Service** → API & system-level integrations  
- **Database (Hive/Firebase)** → Data storage  


## 3. State Management

We use **Provider** across the app:

- Providers expose reactive state  
- Repositories handle persistence & domain rules  
- Services handle I/O, APIs, or background processes  

**Examples:**
- `theme_provider.dart` → Current theme state  
- `note_summary_ai_provider.dart` → AI-driven summaries  
- `sync_settings_provider.dart` → Sync and privacy configurations  


## 4. Local Development Setup

1. **Clone Repository**
   ```bash
   git clone https://github.com/rafay99-epic/MSBridge
   cd MSBridge
    ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Add Firebase Config**

   * `google-services.json` → `android/app/`
   * `GoogleService-Info.plist` → `ios/Runner/`

4. **Generate Hive Adapters**

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the App**

   ```bash
   flutter run
   ```

## 5. Build & Release

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

👉 For Android, configure keystore in `android/key.properties`.

---

## 6. Testing

Run unit tests:

```bash
flutter test
```

Widget and integration tests are recommended for major features (notes, sync, AI).


## 7. Coding Standards

* Follow Dart Effective Style Guide
* Run `dart format .` before commits
* Use small, composable widgets
* Repositories must **not** depend on UI code
* Never commit secrets/keys (use `.env` with `flutter_dotenv`)


## 8. Contribution Workflow

1. Fork the project
2. Create a feature branch:

   ```bash
   git checkout -b feature/my-feature
   ```
3. Commit changes with clear messages
4. Open a Pull Request

All PRs must:

* Pass CI tests
* Follow coding guidelines
* Add/update documentation if needed

For behavior standards, see [CODE_OF_CONDUCT.md](/CODE_OF_CONDUCT.md).

