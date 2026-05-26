import 'package:devent/core/theme/app_theme.dart';
import 'package:devent/core/theme/theme_providers.dart';
import 'package:devent/features/auth/presentation/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeventApp extends ConsumerWidget {
  const DeventApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Devent',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: firebaseReady ? const AuthGate() : const _FirebaseSetupRequired(),
    );
  }
}

class _FirebaseSetupRequired extends StatelessWidget {
  const _FirebaseSetupRequired();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Firebase setup required'),
      ),
    );
  }
}