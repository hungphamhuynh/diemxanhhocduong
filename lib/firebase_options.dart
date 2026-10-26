// File generated for diem_xanh_hoc_duong.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyAjdLRseblLiwJ26OlYwba3_mhcf3Fs7kE',
    appId: '1:909735573349:web:2876fc184277dbcea5138c',
    messagingSenderId: '909735573349',
    projectId: 'diemxanhhocduong',
    authDomain: 'diemxanhhocduong.firebaseapp.com',
    storageBucket: 'diemxanhhocduong.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDh4IhGJaBhrDbWBgve_63NW2i1AR2wX5Y',
    appId: '1:909735573349:android:2c328a082b05949ba5138c',
    messagingSenderId: '909735573349',
    projectId: 'diemxanhhocduong',
    storageBucket: 'diemxanhhocduong.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-5Rnb_Gze0VXxRs9WwEjOxfTuG5me0UQ',
    appId: '1:909735573349:ios:59d3d4b9b71326b7a5138c',
    messagingSenderId: '909735573349',
    projectId: 'diemxanhhocduong',
    storageBucket: 'diemxanhhocduong.firebasestorage.app',
    iosBundleId: 'vn.edu.thcsnguyenthihuong.diemxan',
  );
}
