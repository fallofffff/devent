import 'package:devent/features/auth/presentation/login_screen.dart';
import 'package:devent/features/auth/presentation/providers/auth_providers.dart';
import 'package:devent/features/events/presentation/home_screen.dart';
import 'package:devent/core/utils/friendly_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) => user == null
          ? const LoginScreen()
          : HomeScreen(key: ValueKey('home-${user.uid}')),
      loading: () => const _LoadingView(),
      error: (error, stackTrace) => _ErrorView(error: friendlyErrorMessage(error, fallback: 'Could not load the app.')),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(error)),
    );
  }
}