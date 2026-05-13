import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChKfNN6EgVrA6pzL9fdQEwMqOn454jvUk',
    appId: '1:245256901547:web:f6c14a8ee8049f32d5b8ee',
    messagingSenderId: '245256901547',
    projectId: 'taskflow-71ea9',
    authDomain: 'taskflow-71ea9.firebaseapp.com',
    storageBucket: 'taskflow-71ea9.firebasestorage.app',
    measurementId: 'G-C1Q14TRD28',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCg8bAwnMLa9JbFIF3rlgPHX5M8LB944rY',
    appId: '1:245256901547:android:28d5e88469a1d59bd5b8ee',
    messagingSenderId: '245256901547',
    projectId: 'taskflow-71ea9',
    storageBucket: 'taskflow-71ea9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDoZjnpXodI9MqSxR7-JfORimpGIBdb3xg',
    appId: '1:245256901547:ios:2781fc6d9ed266d7d5b8ee',
    messagingSenderId: '245256901547',
    projectId: 'taskflow-71ea9',
    storageBucket: 'taskflow-71ea9.firebasestorage.app',
    iosBundleId: 'com.example.taskManager',
  );
}
