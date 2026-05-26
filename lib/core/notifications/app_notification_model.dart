import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readDateTime(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return fallback ?? DateTime.now();
}

class AppNotificationModel {
  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.eventId,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String eventId;
  final DateTime createdAt;

  factory AppNotificationModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return AppNotificationModel(
      id: snapshot.id,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      type: (data['type'] ?? 'event') as String,
      eventId: (data['eventId'] ?? '') as String,
      createdAt: _readDateTime(data['createdAt']),
    );
  }
}