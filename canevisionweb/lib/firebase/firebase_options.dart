import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCuiHK2tZz0TfIWJNdjU2dNU0EwdiTFlKY',
    authDomain: 'canevision-1cb59.firebaseapp.com',
    projectId: 'canevision-1cb59',
    storageBucket: 'canevision-1cb59.firebasestorage.app',
    messagingSenderId: '1020865656116',
    appId: '1:1020865656116:web:21e16645defab331926161',
    measurementId: 'G-8F1QZE7Q53',
  );

  // Use the same values for Android/iOS or add separate app entries if needed
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuiHK2tZz0TfIWJNdjU2dNU0EwdiTFlKY',
    appId: '1:1020865656116:web:21e16645defab331926161',
    messagingSenderId: '1020865656116',
    projectId: 'canevision-1cb59',
    storageBucket: 'canevision-1cb59.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCuiHK2tZz0TfIWJNdjU2dNU0EwdiTFlKY',
    appId: '1:1020865656116:web:21e16645defab331926161',
    messagingSenderId: '1020865656116',
    projectId: 'canevision-1cb59',
    storageBucket: 'canevision-1cb59.firebasestorage.app',
    iosBundleId: 'com.example.canevisionm',
  );
}
