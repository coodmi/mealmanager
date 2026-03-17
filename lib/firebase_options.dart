import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC13et5kRqxfMYURNb2Joy30xbjEvmfCUU',
    appId: '1:186008201235:web:5e3237690feab3c61537e6',
    messagingSenderId: '186008201235',
    projectId: 'mealmanager-6a053',
    authDomain: 'mealmanager-6a053.firebaseapp.com',
    storageBucket: 'mealmanager-6a053.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC13et5kRqxfMYURNb2Joy30xbjEvmfCUU',
    appId: '1:186008201235:android:5e3237690feab3c61537e6',
    messagingSenderId: '186008201235',
    projectId: 'mealmanager-6a053',
    storageBucket: 'mealmanager-6a053.firebasestorage.app',
  );
}
