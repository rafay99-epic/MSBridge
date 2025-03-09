# MS Bridge

![MS Bridge Presentation](/Mockup//MS%20Bridge/1.png)

MS Bridge is a cross-platform mobile application built with Flutter, designed to provide seamless note-reading capabilities in both online and offline modes. It leverages Firebase for authentication, data synchronization, and an admin panel, while Hive provides robust local storage for offline access. This ensures you can access and manage your notes anytime, anywhere.

## Features

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

## Technologies Used

- **Flutter (Version 3.22.2):** The primary framework for building the user interface and application logic.
- **Firebase:**
  - Authentication: For user account management and secure access.
  - Realtime Database / Firestore (Specify which one you are using): For data storage and synchronization.
  - Web Hosting or App hosting: For hosting CMS.
- **Hive:** A lightweight NoSQL database for local data storage.
- **API Calls:** Flutter's `http` package (or similar) for fetching notes from the backend API.

## Getting Started

These instructions will guide you on how to set up and run MS Bridge on your local machine.

### Prerequisites

- Flutter SDK (Version 3.22.2 or higher)
  - [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code with Flutter extension
- Firebase Project:
  - You need a Firebase project to store your data and handle authentication.

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

5. **Run the application:**

   ```bash
   flutter run
   ```

## Download APK

Now, you can download and experience both versions of the application. Choose the version that suits your needs:

- **[Download Version 1](/apk/v1/app-release.apk)** – The initial release with core features and Firebase integration.
- **[Download Version 2](/apk/v2/app-release.apk)** – The latest update with improved performance, new features, and enhanced offline support.

## Branching Versions

This repository utilizes a branching strategy to explore different backend service options. Here's a breakdown of each branch:

- **`main`:** This branch represents the current stable version of MS Bridge and utilizes **Firebase** as its backend service. It offers the core functionality of the application, including offline/online note-taking, authentication, and more.

- **`V1`:** This branch explores **Appwrite** as an alternative backend service. The codebase is largely the same as `main`, but it's configured to interact with Appwrite instead of Firebase.

- **`Firebase-V1`:** This branch contains the old and deprecated Version of the App, the backend is not currently working as intended.

  **Important Note:** The `V1` branch is currently in development. The primary goal is to successfully migrate the application's backend from Firebase to Appwrite.

  **Current Status and Future Plans:** During the initial development of the `V1` branch, challenges were encountered when writing user data to the Appwrite backend. Due to time constraints and the need for a functioning application, the `main` branch was reverted to Firebase. I intend to revisit and resolve these Appwrite-related issues in the future to provide the option of using Appwrite as a backend service.

**Why Multiple Branches?**

The use of separate branches allows for experimentation with different backend solutions without disrupting the stability of the main application. This enables me to:

- Evaluate the performance and scalability of different backend services.
- Explore the features and capabilities offered by each platform.
- Provide users with a choice of backend service in the future (if the Appwrite migration is successful).

## Contribution

Contributions are welcome! If you'd like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them with clear, descriptive messages.
4. Submit a pull request.

## License

This project is licensed under the Apache License - see the [LICENSE](LICENSE) file for details.

## Blog Post

To know how build this project from start to end, visit my blog post on my website: [rafay99.com](rafay99.com/blog/)

## Contact

To learn more about me and my work, please visit my website at [rafay99.com](https://rafay99.com).

If you have any questions, suggestions, or feedback regarding MS Bridge, I encourage you to reach out. You can contact me through the contact form on my website: [rafay99.com/contact-me/](https://rafay99.com/contact-me/) or by sending an email to [99marafay@gmail.com](mailto:99marafay@gmail.com).

## Acknowledgements

I would like to express my sincere gratitude to the creators and maintainers of the following technologies and libraries that made the development of MS Bridge possible:

- **Flutter:** [Flutter](https://flutter.dev/) - _For providing a beautiful and efficient framework for building cross-platform applications. Thank you for empowering developers to create amazing user experiences!_

- **Firebase:** [Firebase](https://firebase.google.com/) - _For offering a comprehensive suite of tools and services for building, managing, and growing mobile and web applications. Firebase made backend development significantly easier!_

- **Hive:** [Hive](https://pub.dev/packages/hive) - _For providing a fast, lightweight, and easy-to-use NoSQL database for local data storage. Hive was instrumental in enabling the offline functionality of MS Bridge._

- **http:** [http](https://pub.dev/packages/http) - _For enabling seamless communication with APIs and facilitating the retrieval of data for the application._

- **Appwrite:** [Appwrite](https://appwrite.io/) - _For offering an open-source backend-as-a-service solution that was explored as an alternative to Firebase. While not currently in use in the `main` branch, Appwrite provided valuable insights and experience during the development process._

**Special Thanks:**

I also want to extend a special thank you to the Flutter community, Stack Overflow contributors, and everyone else who provided support and guidance throughout the development of this project. Your contributions were invaluable!
