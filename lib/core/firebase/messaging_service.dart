import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:devent/core/firebase/firestore_collections.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService();
});

class MessagingService {
  MessagingService({FirebaseMessaging? fm, FirebaseFirestore? fs})
      : _fm = fm ?? FirebaseMessaging.instance,
        _fs = fs ?? FirebaseFirestore.instance;

  MessagingService.demo()
      : _fm = null,
        _fs = null;

  final FirebaseMessaging? _fm;
  final FirebaseFirestore? _fs;

  Future<bool> requestNotificationPermission() async {
    if (_fm == null) {
      return false;
    }

    try {
      final settings = await _fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearDeviceTokenForCurrentUser() async {
    if (_fm == null || _fs == null) {
      return;
    }

    try {
      final token = await _fm.getToken();
      if (token != null) {
        await _fs.collection(FirestoreCollections.deviceTokens).doc(token).delete();
      }
      await _fm.deleteToken();
    } catch (_) {}
  }

  Future<String?> getAndSaveDeviceToken({required String userId}) async {
    if (_fm == null || _fs == null) {
      return null;
    }

    try {
      final token = await _fm.getToken();
      if (token == null) return null;
      final doc = _fs.collection(FirestoreCollections.deviceTokens).doc(token);
      await doc.set({
        'userId': userId,
        'token': token,
        'platform': defaultTargetPlatform.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return token;
    } catch (_) {
      return null;
    }
  }
}


