import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBTm5Rsr8OoZXd2VL66FmMQ3UtsrV2WTHE",
            authDomain: "turf-40t9vq.firebaseapp.com",
            projectId: "turf-40t9vq",
            storageBucket: "turf-40t9vq.firebasestorage.app",
            messagingSenderId: "771131079919",
            appId: "1:771131079919:web:9929a8b16e0ee4955e6f1a"));
  } else {
    await Firebase.initializeApp();
  }
}
