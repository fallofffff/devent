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

class BookingModel {
  BookingModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.eventImageUrl,
    required this.eventDate,
    required this.bookedAt,
    required this.qrData,
    required this.isValidated,
    required this.validatedBy,
    required this.validatedAt,
    required this.snapshot,
  });

  final String id;
  final String userId;
  final String eventId;
  final String eventTitle;
  final String eventImageUrl;
  final DateTime eventDate;
  final DateTime bookedAt;
  final String qrData;
  final bool isValidated;
  final String? validatedBy;
  final DateTime? validatedAt;
  final Object snapshot;

  factory BookingModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final data = s.data() ?? <String, dynamic>{};
    return BookingModel(
      id: s.id,
      userId: (data['userId'] ?? '') as String,
      eventId: (data['eventId'] ?? '') as String,
      eventTitle: (data['eventTitle'] ?? '') as String,
      eventImageUrl: (data['eventImageUrl'] ?? '') as String,
      eventDate: _readDateTime(data['eventDate']),
      bookedAt: _readDateTime(data['bookedAt']),
      qrData: (data['qrData'] ?? '') as String,
      isValidated: (data['isValidated'] ?? false) as bool,
      validatedBy: data['validatedBy'] as String?,
      validatedAt: data['validatedAt'] == null ? null : _readDateTime(data['validatedAt']),
      snapshot: s,
    );
  }
}
