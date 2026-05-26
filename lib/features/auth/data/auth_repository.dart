import 'package:devent/features/auth/domain/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();
}