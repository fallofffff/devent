import 'package:devent/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseInitializer {
  const FirebaseInitializer._();

  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}