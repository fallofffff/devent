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

class EventModel {
  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.organizerName,
    required this.organizerId,
    required this.imageUrl,
    required this.totalTickets,
    required this.availableTickets,
    required this.createdAt,
    required this.snapshot,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String organizerName;
  final String organizerId;
  final String imageUrl;
  final int totalTickets;
  final int availableTickets;
  final DateTime createdAt;
  final Object snapshot;

  factory EventModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final data = s.data() ?? <String, dynamic>{};
    return EventModel(
      id: s.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      date: _readDateTime(data['date']),
      location: (data['location'] ?? '') as String,
      organizerName: (data['organizerName'] ?? '') as String,
      organizerId: (data['organizerId'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      totalTickets: (data['totalTickets'] ?? 0) as int,
      availableTickets: (data['availableTickets'] ?? 0) as int,
      createdAt: _readDateTime(data['createdAt']),
      snapshot: s,
    );
  }
}
