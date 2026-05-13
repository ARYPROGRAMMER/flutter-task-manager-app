# Flutter Task Manager App

## Prerequisites
- Flutter SDK (stable channel)
- Firebase CLI installed (
pm install -g firebase-tools)
- FlutterFire CLI installed (dart pub global activate flutterfire_cli)

## Firebase Setup
1. Create a Firebase project in the Firebase Console.
2. Enable Email/Password Authentication.
3. Create a Cloud Firestore database in test mode or update rules to allow authenticated user access.
4. Run flutterfire configure in the project root to generate firebase_options.dart.

## Adding google-services.json
1. Download google-services.json from your Firebase Console for the Android app.
2. Place the google-services.json file inside the android/app/ directory.

## Running the App
`bash
flutter pub get
flutter run
``n
## Release APK
The compiled debug APK can be found at:
/build/app/outputs/flutter-apk/app-debug.apk

