import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:devent/core/firebase/firestore_collections.dart';
import 'package:devent/features/events/domain/event_model.dart';
import 'package:devent/features/events/presentation/event_defaults.dart';

abstract class EventRepository {
  Stream<List<EventModel>> streamEvents({int pageSize = 20, DocumentSnapshot? startAfter});
  Future<EventModel?> fetchEventById(String id);
  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required String organizerName,
    required int totalTickets,
    required String imageUrl,
  });
  Future<void> deleteEvent({required String eventId});
}

class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository({FirebaseFirestore? firestore})
  : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<EventModel>> streamEvents({int pageSize = 20, DocumentSnapshot? startAfter}) {
    Query<Map<String, dynamic>> q = _firestore.collection(FirestoreCollections.events).orderBy('date').limit(pageSize);
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.snapshots().map((snap) => snap.docs.map((d) => EventModel.fromSnapshot(d)).toList());
  }

  @override
  Future<EventModel?> fetchEventById(String id) async {
    final doc = await _firestore.collection(FirestoreCollections.events).doc(id).get();
    if (!doc.exists) return null;
    return EventModel.fromSnapshot(doc as QueryDocumentSnapshot<Map<String, dynamic>>);
  }

  @override
  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required String organizerName,
    required int totalTickets,
    required String imageUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }

    await user.getIdToken(true);

    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    final normalizedLocation = location.trim();
    final normalizedOrganizerName = organizerName.trim();
    final normalizedImageUrl = imageUrl.trim().isEmpty ? pickRandomEventImageUrl() : imageUrl.trim();
    final eventRef = _firestore.collection(FirestoreCollections.events).doc();

    await eventRef.set({
      'title': normalizedTitle,
      'description': normalizedDescription,
      'date': Timestamp.fromDate(date),
      'location': normalizedLocation,
      'organizerName': normalizedOrganizerName,
      'organizerId': user.uid,
      'organizerEmail': user.email ?? '',
      'imageUrl': normalizedImageUrl,
      'totalTickets': totalTickets,
      'availableTickets': totalTickets,
      'createdAt': Timestamp.now(),
    });

    return eventRef.id;
  }

  @override
  Future<void> deleteEvent({required String eventId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }

    final eventRef = _firestore.collection(FirestoreCollections.events).doc(eventId);
    final eventDoc = await eventRef.get();
    if (!eventDoc.exists) {
      throw StateError('Event not found');
    }

    final organizerId = (eventDoc.data()?['organizerId'] ?? '') as String;
    if (organizerId != user.uid) {
      throw StateError('Only the creator can remove this event');
    }

    final relatedBookings = await _firestore
        .collection(FirestoreCollections.bookings)
        .where('eventId', isEqualTo: eventId)
        .get();

    final batch = _firestore.batch();
    for (final booking in relatedBookings.docs) {
      batch.delete(booking.reference);
    }
    batch.delete(eventRef);
    await batch.commit();
  }
}
