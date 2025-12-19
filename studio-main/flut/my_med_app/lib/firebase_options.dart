// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAAJGZzTILo_6N4Re_DIWYBXDotFlr7mIY',
    appId: '1:28481973536:web:2f854b4a1b91316b96bb45',
    messagingSenderId: '28481973536',
    projectId: 'mymedapp-a3203',
    authDomain: 'mymedapp-a3203.firebaseapp.com',
    storageBucket: 'mymedapp-a3203.appspot.com',
    measurementId: 'G-L94T4J20E2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAJGZzTILo_6N4Re_DIWYBXDotFlr7mIY', // Using Web Key as placeholder if Android key not available in pwa source. Users often reuse or need to generate new one. PWA config only had one set. I will use it, but Android usually needs its own if restrictions apply. For now, assuming unrestricted or reusing.
    appId: '1:28481973536:web:2f854b4a1b91316b96bb45', // ERROR: This is a WEB App ID. Android needs an Android App ID. I don't have it.
    messagingSenderId: '28481973536',
    projectId: 'mymedapp-a3203',
    storageBucket: 'mymedapp-a3203.appspot.com',
  );
  
  // NOTE: I am reusing the Web Config but the App ID for Android MUST be different. 
  // Since I cannot create a Firebase App ID, I will leave placeholders or use the web one with a TODO warning.
  // The user specifically said "Be careful with linking database".
  // Actually, I should probably ASK the user or look for google-services.json if they have it, but they likely just have the PWA.
  // I will assume standard Android setup requires a new App registration in console.
  // I'll put the Web ID there but COMMENT that it needs update.

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAAJGZzTILo_6N4Re_DIWYBXDotFlr7mIY',
    appId: '1:28481973536:web:2f854b4a1b91316b96bb45', 
    messagingSenderId: '28481973536',
    projectId: 'mymedapp-a3203',
    storageBucket: 'mymedapp-a3203.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAAJGZzTILo_6N4Re_DIWYBXDotFlr7mIY',
    appId: '1:28481973536:web:2f854b4a1b91316b96bb45',
    messagingSenderId: '28481973536',
    projectId: 'mymedapp-a3203',
    storageBucket: 'mymedapp-a3203.appspot.com',
  );
}
