# MS Bridge

MS Bridge is a cross-platform mobile application built with Flutter, designed for seamless lecture note reading and note-taking. It supports both online and offline modes, allowing users to effortlessly switch between them manually or automatically based on network availability.

The app integrates Firebase for authentication, real-time data synchronization, and an admin panel, ensuring secure and efficient note management. For offline access, it utilizes Hive as a robust local storage solution, enabling users to read and manage their notes anytime, anywhere.

With MS Bridge, you get a reliable, user-friendly platform for organizing and accessing your study materials without interruptions.

![MS Bridge Presentation](/Mockup//MS%20Bridge/1.png)

## Badges

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) ![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white) ![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/rafay99-epic/MSBridge?labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit%20Reviews)


## 🚀 Features

| Feature                             | Description                                                                                      |
| ----------------------------------- | ------------------------------------------------------------------------------------------------ |
| **🧠 AI-Powered Summarization**     | Generate concise, context-aware summaries of your notes using advanced AI models.                |
| **🔄 Real-Time Note Sync**          | Always stay up-to-date with dynamic note fetching from your API endpoint.                        |
| **📶 Online & Offline Mode**        | Seamlessly switch between online and offline access, ensuring uninterrupted note usage.          |
| **💾 Local Storage with Hive**      | Fast, lightweight NoSQL database to store and retrieve notes efficiently when offline.           |
| **🔐 Secure Authentication**        | Firebase Authentication integration with built-in spam detection for secure and reliable access. |
| **🔍 Fast Search & Tag System**     | Perform fast, case-insensitive searches across notes and organize them using tags.               |
| **🧑‍💻 CMS Admin Panel Support**      | Integrated WebView for managing content directly from your CMS dashboard.                        |
| **📝 Full Note-Taking Support**     | Create, edit, delete, and auto-save notes locally and online with smooth UX.                     |
| **🎨 Multiple Themes**              | Choose from Light, Dark, Sunset, Midnight, Forest Green, and more for a personalized experience. |
| **⚡ Optimized Offline Search**     | Quick local searching powered by Hive for efficient offline queries.                             |
| **🔄 Reset to Default**             | Revert settings and themes to default with a single tap.                                         |
| **📄 AI Summary Bottom Sheet**      | Interactive bottom sheet with dynamic typing animation and copy/close actions.                   |
| **⚙️ Customizable AI Model**        | Select your preferred AI model for summarization from the settings menu.                         |
| **💡 Auto-Save Feature**            | Automatically saves notes as you type to prevent data loss.                                      |
| **📱 Enhanced Settings & App Info** | New settings interface and dedicated app info page for a refined user experience.                |

## Technologies Used

- **Flutter (Version 3.22.2):** The primary framework for building the user interface and application logic.
- **Firebase:**
  - Authentication: For user account management and secure access.
  - Realtime Database / Firestore: For data storage and synchronization.
  - Web Hosting or App hosting: For hosting CMS.
- **Hive:** A lightweight NoSQL database for local data storage.
- **API Calls:** Flutter's `http` package (or similar) for fetching notes from the backend API.
- **AI Integration:** Google AI Studio API for AI-powered note summarization.

## 🚀 Getting Started

Follow the steps below to set up and run **MS Bridge** on your local development environment.

### 📋 Prerequisites

Ensure the following tools and services are available on your system:

- **Flutter SDK** (version `3.22.2` or higher)  
  📖 [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** or **VS Code** with Flutter extension
- **Firebase Project** for authentication and data storage
- **API Key** for AI Summarization _(Google Studio API)_
- **Keystore** (for signed APK generation)
  > _Note: The password for the keystore is not provided._

---

### 🔧 Installation Steps

#### 1. Clone the Repository

```bash
git clone https://github.com/rafay99-epic/MSBridge
cd MSBridge
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Configure Firebase

1. **Create a Firebase Project:**  
   Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.

2. **Integrate Firebase with Flutter App:**  
   Follow Firebase’s guide to register your app and download the configuration files:

   - `google-services.json` → Place in `android/app/`
   - `GoogleService-Info.plist` → Place in `ios/Runner/`

3. **Enable Firebase Services:**
   - Enable **Authentication** (e.g., Email/Password, Google Sign-In)
   - Enable **Firestore Database** and configure security rules as needed

---

### 🔐 Firebase & API Key Configuration

Edit the config file (e.g., `lib/config.dart`) and replace placeholder values with your actual Firebase and API credentials:

```dart
const firebaseConfig = {
  apiKey: 'YOUR_API_KEY',
  authDomain: 'YOUR_AUTH_DOMAIN',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
  measurementId: 'YOUR_MEASUREMENT_ID',
};

const aiApiKey = 'YOUR_GOOGLE_AI_STUDIO_API_KEY';
```

> 💡 **Tip:** Never commit API keys to version control. Use `.env` or secure key management.

You may also need to update:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

---

### 🤖 AI Summarization Setup

- Sign up and get your API key from [Google AI Studio](https://aistudio.google.com/)
- Paste the key in `lib/config.dart` under `aiApiKey`

---

### 📦 Keystore for Signed APKs

To build signed APKs:

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore msbridge_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias msbridge
   ```
2. Place the keystore in the project root.
3. Update your `android/key.properties` and `build.gradle` files accordingly.

> ⚠️ _The password for the signing key is not provided and must be managed securely._

### ▶️ Run the Application

Use the following command to start the app:

```bash
flutter run
```

## APK Files

You can easily test the application by downloading the APK files from the official links below:

- 🔹 **Stable Release (v6)** – [Download from rafay99.com](https://rafay99.com/MSBridge-APK)
- 🔸 **Beta Version** – [Try the beta build](https://rafay99.com/MSBridge-beta)

### Previous Releases

Looking for older versions? You can find all previous APK files in the [**GitHub repository**](https://github.com/rafay99-epic/MSBridge/tree/main/apk).

## Contributing

We welcome contributions from the community! If you're interested in contributing, please follow these steps:

1. **Fork the repository** to create your own copy.
2. **Create a new branch** for your feature or bug fix (e.g., `feature/add-new-feature` or `bugfix/fix-issue`).
3. **Make your changes** in the branch. Be sure to write clean, well-documented code and follow the project's coding style.
4. **Commit your changes** with clear, concise commit messages that explain the purpose of the change.
5. **Submit a pull request (PR)** to the main repository. In your PR, provide a brief description of what you’ve changed and why.

We review all pull requests and will provide feedback as necessary. Thank you for helping improve the project!

## License

This project is licensed under the [Apache License 2.0](LICENSE). See the LICENSE file for full details.

## Blog Post

To know how to build this project from start to end, visit my blog post on my website: [rafay99.com](https://www.rafay99.com/blog/idea_to_app/)

## Contact

To learn more about me and my work, please visit my website at [rafay99.com](https://rafay99.com).

If you have any questions, suggestions, or feedback regarding MS Bridge, I encourage you to reach out. You can contact me through the contact form on my website: [rafay99.com/contact-me/](https://rafay99.com/contact-me/) or by sending an email to [99marafay@gmail.com](mailto:99marafay@gmail.com).

## Acknowledgements

I would like to express my sincere gratitude to the creators and maintainers of the following technologies and libraries that made the development of MS Bridge possible:

- **Flutter:** [Flutter](https://flutter.dev/) - _For providing a beautiful and efficient framework for building cross-platform applications._
- **Firebase:** [Firebase](https://firebase.google.com/) - _For offering a comprehensive suite of tools for building and managing applications._
- **Hive:** [Hive](https://pub.dev/packages/hive) - _For providing fast and lightweight local data storage._
- **http:** [http](https://pub.dev/packages/http) - _For enabling seamless communication with APIs._
- **Appwrite:** [Appwrite](https://appwrite.io/) - _For offering an open-source backend-as-a-service solution._
- **Google Studio API:** [Google Studio](https://aistudio.google.com/) - _For enabling AI-powered note summarization._

**Special Thanks:**

A big thank you to the Flutter community, Stack Overflow contributors, and everyone who provided support and guidance throughout the development of this project!

<p align="center">
  Made with ❤️ by <a href="https://rafay99.com">Abdul Rafay</a> • <a href="mailto:99marafay@gmail.com">Contact</a> • <a href="https://github.com/rafay99-epic/MSBridge/stargazers">⭐ Star</a>
</p>
