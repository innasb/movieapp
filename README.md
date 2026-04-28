# Watchy - Watch Together Movie App

Watchy is a cross-platform Flutter application that allows users to discover movies and watch them synchronously with friends in real-time.

## Features

- **Movie Discovery**: Browse and search for your favorite movies.
- **Watch Together**: Create or join watch rooms to view content synchronously with friends.
- **WebRTC Voice/Video Calling**: Chat with your friends in real-time while watching using integrated WebRTC communication.
- **Cross-Platform Support**: Enjoy the app on Android, Windows, and Web.
- **Secure Web Player**: Enhanced web player with ad-blocking and secure sandboxing to prevent malicious scripts and unauthorized navigations.
- **Real-Time Synchronization**: Seamless playback synchronization across all devices via Firebase and custom signaling.

## Technologies Used

- **Framework**: Flutter
- **Backend & Signaling**: Firebase (Realtime Database, Firestore, Authentication)
- **Real-Time Communication**: `flutter_webrtc` for voice and video calling
- **Video Playback**: 
  - `webview_flutter` for Android
  - `webview_windows` for Windows desktop
  - Custom iframe implementation for Web
- **Architecture**: BLoC pattern (`flutter_bloc`), Dependency Injection (`get_it`)
- **Networking**: Dio

## Getting Started

### Prerequisites

- Flutter SDK (^3.10.3)
- Firebase Project setup with Authentication, Firestore, and Realtime Database enabled.

### Setup

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd movie_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration:**
   Create a `.env` file in the root directory and add your Firebase configuration (e.g., Realtime Database URL):
   ```env
   FIREBASE_DATABASE_URL=https://<YOUR_FIREBASE_PROJECT_ID>.firebaseio.com
   ```

4. **Run the App:**
   - For Android:
     ```bash
     flutter run -d android
     ```
   - For Web:
     ```bash
     flutter run -d chrome
     ```
   - For Windows:
     ```bash
     flutter run -d windows
     ```

## Platform-Specific Notes

### Windows
The app uses `webview_windows` for video playback. Ensure you have the Edge WebView2 runtime installed on your Windows machine. Memory constraints for Gradle might require tweaking `android/gradle.properties` (e.g., `-Xmx1024m`) if you are building the Android version on a lower-spec machine.

### Web
The web implementation includes a strict Content Security Policy (CSP) and iframe sandboxing to block unwanted ads and popups during playback, ensuring a safe and uninterrupted viewing experience.
