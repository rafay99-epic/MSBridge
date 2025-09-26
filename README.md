

# MS Bridge  

**MS Bridge** is a powerful cross-platform mobile application built with Flutter, designed to revolutionize the way students, professionals, and lifelong learners manage lecture notes, personal thoughts, and study materials.  

The platform combines **intelligent note-taking, structured reading, offline & cloud synchronization, and AI-powered assistance** into a single seamless experience. With advanced privacy controls, customizable workflows, and blazing-fast local storage, MS Bridge adapts to the way you study, think, and work — online or offline.  

![MS Bridge Presentation](https://msbridge.rafay99.com/assets/blog/post/readme.webp)  

## Key Features  

### Intelligent Note-Taking & Reading  
- Modern, distraction-free note editor with Markdown and diagram rendering  
- Note organization with tags, templates, and case-insensitive search  
- Integrated checklists and to-do items within notes  
- AI-powered note summaries for quick understanding  

### AI Assistance  
- Conversational assistant with access to your personal notes and knowledge base  
- Configurable AI model selection tailored to your workflow  

### Data Management  
- Real-time cross-device synchronization via Firebase  
- Background workers for efficient, configurable sync  
- Privacy-first local mode with **Hive** database support  
- Data import/export for full portability  
- Secure link-based note sharing  

### Personalization & Productivity  
- Profile management and customizable themes (18+ styles)  
- Support for multiple Google Fonts with live previews  
- Productivity streak tracking with smart reminders  
- Security options: biometric/fingerprint and PIN lock  
- One-tap reset to default configurations  

### Application & Admin Tools  
- In-app update system (direct from rafay99.com)  
- Integrated CMS admin panel (via WebView)  
- Built-in contact form for direct feedback  
- Debugging tools (in progress)  

## Future Roadmap  

- Speech-to-text note capture  
- Audio/voice notes management  
- Image-based note integration  
- AI chatbot with image query support  
- Advanced diagnostic tool (Logfinder)  

## Technologies  

- **Flutter (3.25.1+)**: UI and application logic  
- **Firebase**  
  - Authentication  
  - Firestore (real-time data storage)  
  - Cloud Functions (background tasks)  
- **Hive**: Local, fast, offline-first NoSQL storage  
- **Google AI Studio API (or alternatives)** for AI-powered summaries and chat  
- **http package** for API integration  



## Getting Started  

### Prerequisites  
- Flutter SDK 3.25.1+  
- Android Studio or VS Code with Flutter extensions  
- Firebase project (authentication + database configured)  
- AI service API key (Google AI Studio or compatible)  
- Keystore for release builds  

### Installation  

1. **Clone repository**  
   ```bash
   git clone https://github.com/rafay99-epic/MSBridge
   cd MSBridge
   ```  

2. **Install dependencies**  
   ```bash
   flutter pub get
   ```  

3. **Firebase setup**:  
   - Add configuration files to platform-specific directories:  
     - `google-services.json` → `android/app/`  
     - `GoogleService-Info.plist` → `ios/Runner/`  
   - Enable authentication and Firestore in Firebase Console  

4. **Configure API keys** (use `.env` or environment variables):  
   ```dart
   const firebaseConfig = {
     apiKey: 'YOUR_FIREBASE_API_KEY',
     projectId: 'YOUR_PROJECT_ID',
     appId: 'YOUR_APP_ID',
   };

   const aiApiKey = 'YOUR_AI_API_KEY';
   ```  

5. **Run application**  
   ```bash
   flutter run
   ```  


## Building for Release  

1. Generate keystore:  
   ```bash
   keytool -genkey -v -keystore msbridge_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias msbridge
   ```  

2. Update `key.properties` and `build.gradle` with keystore details.  


## Downloads  

Official APK releases are available at:  
[https://msbridge.rafay99.com/versions](https://msbridge.rafay99.com/versions)  

Older builds can still be found under GitHub Releases.  


## Contributing  

Contributions are welcome. To participate:  
1. Fork the repository  
2. Create a feature branch (`feature/new-module`)  
3. Submit a Pull Request with a clear description  

## License  

This project is licensed under the [Apache License 2.0](LICENSE).  

## Author & Contact  

Developed and maintained by **Abdul Rafay**  
- Website: [rafay99.com](https://rafay99.com)  
- Contact: [99marafay@gmail.com](mailto:99marafay@gmail.com)  
- Blog: [rafay99.com/blog/idea_to_app](https://rafay99.com/blog/idea_to_app)  

## Acknowledgements  

- **Flutter** – Cross platform framework  
- **Firebase** – Backend services  
- **Hive** – Offline-first data layer  
- **Google AI Studio** – AI-powered note summarization  
- Open source community and contributors  
