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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  // > Your apps > Add app > Web, sau đó copy các giá trị vào đây
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBs0f8TVT2__R6EDYRj_-QOI-6GjIyvcCo',
    appId:
        '1:590813077328:web:YOUR_WEB_APP_ID', // Thay YOUR_WEB_APP_ID bằng ID thật từ Firebase Console
    messagingSenderId: '590813077328',
    projectId: 'nthiennhan-954cf',
    authDomain: 'nthiennhan-954cf.firebaseapp.com',
    storageBucket: 'nthiennhan-954cf.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBs0f8TVT2__R6EDYRj_-QOI-6GjIyvcCo',
    appId: '1:590813077328:android:0ebe2fe56409f30a4fd655',
    messagingSenderId: '590813077328',
    projectId: 'nthiennhan-954cf',
    storageBucket: 'nthiennhan-954cf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBs0f8TVT2__R6EDYRj_-QOI-6GjIyvcCo',
    appId:
        '1:590813077328:ios:YOUR_IOS_APP_ID', // Cần thêm app iOS trong Firebase Console
    messagingSenderId: '590813077328',
    projectId: 'nthiennhan-954cf',
    storageBucket: 'nthiennhan-954cf.firebasestorage.app',
    iosBundleId: 'com.example.expenseManagerAndroid',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBs0f8TVT2__R6EDYRj_-QOI-6GjIyvcCo',
    appId: '1:590813077328:ios:YOUR_MACOS_APP_ID',
    messagingSenderId: '590813077328',
    projectId: 'nthiennhan-954cf',
    storageBucket: 'nthiennhan-954cf.firebasestorage.app',
    iosBundleId: 'com.example.expenseManagerAndroid.RunnerTests',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBs0f8TVT2__R6EDYRj_-QOI-6GjIyvcCo',
    appId: '1:590813077328:web:YOUR_WINDOWS_APP_ID',
    messagingSenderId: '590813077328',
    projectId: 'nthiennhan-954cf',
    authDomain: 'nthiennhan-954cf.firebaseapp.com',
    storageBucket: 'nthiennhan-954cf.firebasestorage.app',
  );
}
