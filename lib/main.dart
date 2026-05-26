import 'package:devent/app.dart';
import 'package:devent/core/firebase/firebase_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      // Keep startup non-blocking so the first frame can render even if
      // Firebase initialization is slow or fails on the selected platform.
      overrides: const [],
      child: const _BootstrapApp(),
    ),
  );
}

class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: FirebaseInitializer.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return DeventApp(firebaseReady: snapshot.data ?? false);
      },
    );
  }
}
