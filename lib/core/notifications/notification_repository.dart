import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devent/core/firebase/firestore_collections.dart';
import 'package:devent/core/notifications/app_notification_model.dart';
import 'package:devent/features/events/presentation/event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class NotificationRepository {
  Stream<List<AppNotificationModel>> streamRecentNotifications({int limit = 20});
  Future<void> createEventNotification({required String eventId, required String title, required String body});
}

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<AppNotificationModel>> streamRecentNotifications({int limit = 20}) {
    return _firestore
        .collection(FirestoreCollections.notifications)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotificationModel.fromSnapshot).toList());
  }

  @override
  Future<void> createEventNotification({required String eventId, required String title, required String body}) async {
    await _firestore.collection(FirestoreCollections.notifications).add({
      'type': 'event',
      'eventId': eventId,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository();
});

final recentNotificationsProvider = StreamProvider.autoDispose<List<AppNotificationModel>>((ref) {
  final eventsAsync = ref.watch(eventListStreamProvider);
  return eventsAsync.when(
    data: (events) {
      final notifications = events
          .take(20)
          .map(
            (event) => AppNotificationModel(
              id: 'event-${event.id}',
              title: 'New event posted',
              body: '${event.title} is now available',
              type: 'event',
              eventId: event.id,
              createdAt: event.createdAt,
            ),
          )
          .toList();
      return Stream<List<AppNotificationModel>>.value(notifications);
    },
    loading: () => Stream<List<AppNotificationModel>>.value(const <AppNotificationModel>[]),
    error: (error, stackTrace) => Stream<List<AppNotificationModel>>.value(const <AppNotificationModel>[]),
  );
});

final lastSeenNotificationIdProvider = StateProvider<String?>((ref) => null);

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final notifications = ref.watch(recentNotificationsProvider).valueOrNull;
  if (notifications == null || notifications.isEmpty) {
    return false;
  }

  final lastSeenId = ref.watch(lastSeenNotificationIdProvider);
  if (lastSeenId == null) {
    return true;
  }

  return notifications.first.id != lastSeenId;
});