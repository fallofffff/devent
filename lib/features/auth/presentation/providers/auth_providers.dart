import 'package:devent/core/session/session_cache.dart';
import 'package:devent/features/auth/data/auth_repository.dart';
import 'package:devent/features/auth/data/firebase_auth_repository.dart';
import 'package:devent/features/auth/domain/app_user.dart';
import 'package:devent/core/firebase/messaging_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  MessagingService get _messaging => ref.read(messagingServiceProvider);

  @override
  Future<void> build() async {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    });

    if (!state.hasError) {
      _refreshSessionForNewUser();
      await _enableNotificationsForCurrentUser();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _repository.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      );
    });

    if (!state.hasError) {
      _refreshSessionForNewUser();
      await _enableNotificationsForCurrentUser();
    }
  }

  void _refreshSessionForNewUser() {
    invalidateUserDataCache(ref);
    ref.invalidate(authStateChangesProvider);
  }

  Future<void> _enableNotificationsForCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final permissionGranted = await _messaging.requestNotificationPermission();
    if (!permissionGranted) {
      return;
    }

    await _messaging.getAndSaveDeviceToken(userId: currentUser.uid);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _messaging.clearDeviceTokenForCurrentUser();
      await _repository.signOut();
      invalidateUserDataCache(ref);
      ref.invalidate(authStateChangesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}