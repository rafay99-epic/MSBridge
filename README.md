# MS Bridge

MS Bridge is a cross-platform mobile application built with Flutter, designed for seamless lecture note reading and note-taking. It supports both online and offline modes, allowing users to effortlessly switch between them manually or automatically based on network availability.

The app integrates Firebase for authentication, real-time data synchronization, and an admin panel, ensuring secure and efficient note management. For offline access, it utilizes Hive as a robust local storage solution, enabling users to read and manage their notes anytime, anywhere.

With MS Bridge, you get a reliable, user-friendly platform for organizing and accessing your study materials without interruptions.

![MS Bridge Presentation](/Mockup//MS%20Bridge/1.png)

## Badges

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white) ![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white) ![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/rafay99-epic/MSBridge?labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit%20Reviews)

## Features

- **AI-Powered Note Summarization** – Generate concise and engaging summaries of your notes using advanced AI models.
- **Dynamic Note Rendering** – Fetches and displays your notes from an API endpoint, ensuring you always have the latest version.
- **Online/Offline Mode** – Seamlessly switches between online and offline modes, allowing you to access your notes even without an internet connection.
- **Local Database with Hive** – Utilizes Hive, a fast and lightweight NoSQL database, for efficient offline data storage and retrieval.
- **Secure Authentication and Spam Detection** – Implements Firebase Authentication for secure user access and incorporates spam detection mechanisms to maintain data integrity.
- **Fast Search and Tag System** – Includes a powerful search functionality and a tag system for quick and easy note organization and retrieval.
- **Admin Panel Integration** – Allows seamless integration with CMS through the web view, so you can manage content via CMS from anywhere.
- **Note-Taking** – Enables users to create, edit, and delete notes, providing a comprehensive note-taking experience with Hive as the local database.
- **Multiple Theme Support** – Users can switch between various themes, including light mode, dark mode, sunset, midnight, forest green, and more, allowing for a personalized experience.
- **Fast Search** – With Hive database support, searching is optimized for speed and efficiency, enabling case-insensitive searches across titles and content.
- **Enhanced Offline Mode** – Automatically switches between online and offline modes, preventing changes when there is no internet connection.
- **Reset to Default** – Provides an option to reset settings and themes back to the default style whenever needed.
- **Interactive AI Summary Bottom Sheet** – A sleek bottom sheet interface with a dynamic typing effect for viewing summaries, with intuitive copy and close options.
- **User-Selectable AI Model for Summarization** – Users can now choose their preferred AI model for generating summaries via a dedicated settings page.
- **Auto-Save Feature** – Automatically saves notes to enhance efficiency.
- **New Settings Interface & App Info Page** – Improved settings navigation with an added App Info page displaying application details.

## Technologies Used

- **Flutter (Version 3.22.2):** The primary framework for building the user interface and application logic.
- **Firebase:**
  - Authentication: For user account management and secure access.
  - Realtime Database / Firestore: For data storage and synchronization.
  - Web Hosting or App hosting: For hosting CMS.
- **Hive:** A lightweight NoSQL database for local data storage.
- **API Calls:** Flutter's `http` package (or similar) for fetching notes from the backend API.
- **AI Integration:** OpenAI API (or similar) for AI-powered note summarization.

## Getting Started

These instructions will guide you on how to set up and run MS Bridge on your local machine.

### Prerequisites

- Flutter SDK (Version 3.22.2 or higher)
  - [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code with Flutter extension
- Firebase Project:
  - You need a Firebase project to store your data and handle authentication.
- API Key for AI Summarization (OpenAI or other AI service)

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/rafay99-epic/MSBridge
   cd MSBridge
   ```

2. **Install Flutter dependencies:**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**

   - **Create a Firebase Project:** Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.
   - **Add Firebase to Your Flutter App:** Follow the instructions on the Firebase console to add your Flutter app to the project (for both Android and iOS if you intend to support both). This will involve:
     - Registering your app with Firebase.
     - Downloading the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) configuration files.
     - Placing these files in the appropriate directories within your Flutter project (as specified by Firebase).
   - **Enable Authentication:** In the Firebase console, enable the authentication methods you want to use (e.g., Email/Password, Google Sign-In).
   - **Set up Firestore:** Create a Firestore Database instance and configure the security rules as needed.

4. **API Keys and Firebase Configuration:**

   - **Important:** This project requires Firebase configuration and API keys to function correctly. You need to:
     - Replace the placeholder values in `lib/config.dart` (or similar configuration file) with your actual Firebase API keys and project settings. These values will include (but may not be limited to):
       - `apiKey`
       - `authDomain`
       - `projectId`
       - `storageBucket`
       - `messagingSenderId`
       - `appId`
       - `measurementId`
     - You may also need to configure your API keys and project settings in your AndroidManifest.xml and Info.plist files if prompted by firebase setup.
     - **Security Note:** Never commit your API keys directly to your public repository. Use environment variables or secure configuration management techniques.

5. "**Set up AI Summarization API Key:**

   - **Important:** This project requires an API key for AI Summarization. You can set the API key in the `lib/config.dart` file.
   - **Important:** You can get the API key from [Google Studio AI](https://aistudio.google.com/)

6. **Run the application:**

   ```bash
   flutter run
   ```

## APK Files

### Latest Release

You can download the latest version of the application from the official website:
[**Download Latest Release**](https://www.rafay99.com/downloads/apk/MSBridge/release)

### Previous Releases

For older versions of the APK files, visit the [**GitHub repository**](https://github.com/rafay99-epic/MSBridge/tree/main/apk).

## Contribution

Contributions are welcome! If you'd like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them with clear, descriptive messages.
4. Submit a pull request.

## License

This project is licensed under the Apache License - see the [LICENSE](LICENSE) file for details.

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
