import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCcwQm3QwyXgUgnL_or06SbZspRYCYa7RA",
            authDomain: "app-declaracion-renta.firebaseapp.com",
            projectId: "app-declaracion-renta",
            storageBucket: "app-declaracion-renta.firebasestorage.app",
            messagingSenderId: "976371529191",
            appId: "1:976371529191:web:04d08d57e773d8c153b942",
            measurementId: "G-RB12SNVLMJ"));
  } else {
    await Firebase.initializeApp();
  }
}
