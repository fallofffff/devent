import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devent/core/firebase/firestore_collections.dart';
import 'package:devent/features/auth/data/auth_repository.dart';
import 'package:devent/features/auth/domain/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(
        (user) => user == null
            ? null
            : AppUser(
                uid: user.uid,
                name: user.displayName ?? '',
                email: user.email ?? '',
              ),
      );

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('FirebaseAuth returned no user after registration.');
    }

    await user.updateDisplayName(name);
    await _firestore.collection(FirestoreCollections.users).doc(user.uid).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();
}