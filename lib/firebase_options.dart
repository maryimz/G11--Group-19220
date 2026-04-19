import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('This platform is not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDD82Z8FKMTZwwsXW0gFpmRdBf_CjAitrI',
    appId: '1:614322994184:android:388f4d85e715ef160725bd',
    messagingSenderId: '614322994184',
    projectId: 'florigen-control',
    databaseURL: 'https://florigen-control-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDD82Z8FKMTZwwsXW0gFpmRdBf_CjAitrI',
    appId: '1:614322994184:android:388f4d85e715ef160725bd',
    messagingSenderId: '614322994184',
    projectId: 'florigen-control',
    databaseURL: 'https://florigen-control-default-rtdb.firebaseio.com',
  );
}