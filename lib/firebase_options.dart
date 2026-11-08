// File configured for Firebase project: langcurve-app (742561079237)
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Returns true if the project has been configured with real Firebase credentials.
  static bool get isConfigured {
    try {
      final opts = currentPlatform;
      return !opts.apiKey.startsWith('YOUR_') &&
          opts.projectId != 'your-firebase-project-id';
    } catch (_) {
      return false;
    }
  }

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
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDSdjRrTbwpRiU6XRVMo69knWVNevjYmf4',
    appId: '1:742561079237:web:0671ce8228ee70c7d275ac',
    messagingSenderId: '742561079237',
    projectId: 'langcurve-app',
    authDomain: 'langcurve-app.firebaseapp.com',
    storageBucket: 'langcurve-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0pEdfrqolOg5kszm754VxwAnF5OUQUas',
    appId: '1:742561079237:android:c5d0948a1b33ab0cd275ac',
    messagingSenderId: '742561079237',
    projectId: 'langcurve-app',
    storageBucket: 'langcurve-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDM15_0RTIearBqsPu1hyL1q8DneEzfOm4',
    appId: '1:742561079237:ios:055d63513991e5ead275ac',
    messagingSenderId: '742561079237',
    projectId: 'langcurve-app',
    storageBucket: 'langcurve-app.firebasestorage.app',
    iosClientId:
        '742561079237-7m9e5a4scbvi9o7lpj7uuggorp12urag.apps.googleusercontent.com',
    iosBundleId: 'com.example.langcurve',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDM15_0RTIearBqsPu1hyL1q8DneEzfOm4',
    appId: '1:742561079237:ios:055d63513991e5ead275ac',
    messagingSenderId: '742561079237',
    projectId: 'langcurve-app',
    storageBucket: 'langcurve-app.firebasestorage.app',
    iosClientId:
        '742561079237-7m9e5a4scbvi9o7lpj7uuggorp12urag.apps.googleusercontent.com',
    iosBundleId: 'com.example.langcurve',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDSdjRrTbwpRiU6XRVMo69knWVNevjYmf4',
    appId: '1:742561079237:web:0671ce8228ee70c7d275ac',
    messagingSenderId: '742561079237',
    projectId: 'langcurve-app',
    authDomain: 'langcurve-app.firebaseapp.com',
    storageBucket: 'langcurve-app.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDSdjRrTbwpRiU6XRVMo69knWVNevjYmf4',
    appId: '1:742561079237:web:0671ce8228ee70c7d275ac',
    messagingSenderId: '742561079237',
    projectId: 'langcurve-app',
    authDomain: 'langcurve-app.firebaseapp.com',
    storageBucket: 'langcurve-app.firebasestorage.app',
  );
}
