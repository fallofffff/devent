import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:devent/core/firebase/firestore_collections.dart';
import 'package:devent/features/booking/domain/booking_model.dart';

abstract class BookingRepository {
  Future<Map<String, String>> createBooking({
    required String userId,
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    String eventImageUrl = '',
  });

  Future<bool> hasUserBookedEvent({required String userId, required String eventId});
  Future<void> cancelBooking({required String bookingId, required String userId, required String eventId});
  Stream<List<BookingModel>> streamUserBookings(String userId);
  Future<BookingModel?> fetchBookingById(String id);
  Future<bool> validateBookingByQr(String qrData);
  Future<bool> validateBookingByQrForEvent({required String qrData, required String eventId});
  Future<bool> unvalidateBookingByQr(String qrData);
}

class FirestoreBookingRepository implements BookingRepository {
  FirestoreBookingRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, String>> createBooking({
    required String userId,
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    String eventImageUrl = '',
  }) async {
    if (await hasUserBookedEvent(userId: userId, eventId: eventId)) {
      throw StateError('You already booked this event');
    }

    final bookingRef = _firestore.collection(FirestoreCollections.bookings).doc();
    final eventRef = _firestore.collection(FirestoreCollections.events).doc(eventId);

    await _firestore.runTransaction((tx) async {
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) throw StateError('Event not found');
      final available = (eventSnap.data()!['availableTickets'] ?? 0) as int;
      if (available <= 0) throw StateError('No tickets available');

      tx.update(eventRef, {'availableTickets': available - 1});

      final bookingData = {
        'userId': userId,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventImageUrl': eventImageUrl,
        'eventDate': Timestamp.fromDate(eventDate),
        'bookedAt': Timestamp.fromDate(DateTime.now().toUtc()),
        'qrData': '', // placeholder; will set after id known
        'isValidated': false,
      };

      tx.set(bookingRef, bookingData);
    });

    final bookingId = bookingRef.id;
    final qrData = bookingId + userId + eventId;
    await bookingRef.update({'qrData': qrData});

    return {'bookingId': bookingId, 'qrData': qrData};
  }

  @override
  Future<bool> hasUserBookedEvent({required String userId, required String eventId}) async {
    final q = await _firestore
        .collection(FirestoreCollections.bookings)
        .where('userId', isEqualTo: userId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  @override
  Future<void> cancelBooking({required String bookingId, required String userId, required String eventId}) async {
    final bookingRef = _firestore.collection(FirestoreCollections.bookings).doc(bookingId);
    final eventRef = _firestore.collection(FirestoreCollections.events).doc(eventId);

    await _firestore.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) {
        throw StateError('Booking not found');
      }

      final bookingData = bookingSnap.data();
      if (bookingData == null || bookingData['userId'] != userId) {
        throw StateError('Not allowed to remove this booking');
      }

      tx.delete(bookingRef);
      tx.update(eventRef, {
        'availableTickets': FieldValue.increment(1),
      });
    });
  }

  @override
  Stream<List<BookingModel>> streamUserBookings(String userId) {
    final q = _firestore.collection(FirestoreCollections.bookings).where('userId', isEqualTo: userId);
    return q.snapshots().map((s) {
      final bookings = s.docs.map((d) => BookingModel.fromSnapshot(d)).toList();
      bookings.sort((left, right) => left.eventDate.compareTo(right.eventDate));
      return bookings;
    });
  }

  @override
  Future<BookingModel?> fetchBookingById(String id) async {
    final doc = await _firestore.collection(FirestoreCollections.bookings).doc(id).get();
    if (!doc.exists) return null;
    return BookingModel.fromSnapshot(doc);
  }

  @override
  Future<bool> validateBookingByQr(String qrData) async {
    return _setBookingValidationStateByQr(qrData, isValidated: true);
  }

  @override
  Future<bool> validateBookingByQrForEvent({required String qrData, required String eventId}) async {
    return _setBookingValidationStateByQr(qrData, isValidated: true, eventId: eventId);
  }

  @override
  Future<bool> unvalidateBookingByQr(String qrData) async {
    return _setBookingValidationStateByQr(qrData, isValidated: false);
  }

  Future<bool> _setBookingValidationStateByQr(
    String qrData, {
    required bool isValidated,
    String? eventId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw StateError('Not authenticated');
    }

    final q = await _firestore.collection(FirestoreCollections.bookings).where('qrData', isEqualTo: qrData).limit(1).get();
    if (q.docs.isEmpty) return false;

    final bookingDoc = q.docs.first;
    final bookingEventId = (bookingDoc.data()['eventId'] ?? '') as String;
    if (bookingEventId.isEmpty) return false;
    if (eventId != null && bookingEventId != eventId) {
      throw StateError('This booking belongs to a different event');
    }

    final eventDoc = await _firestore.collection(FirestoreCollections.events).doc(bookingEventId).get();
    if (!eventDoc.exists) return false;

    final organizerId = (eventDoc.data()?['organizerId'] ?? '') as String;
    if (organizerId != currentUser.uid) {
      throw StateError('Only the creator can change validation status');
    }

    final currentValidationState = (bookingDoc.data()['isValidated'] ?? false) as bool;
    if (currentValidationState == isValidated) {
      return true;
    }

    await bookingDoc.reference.update({
      'isValidated': isValidated,
      'validatedBy': isValidated ? currentUser.uid : null,
      'validatedAt': isValidated ? FieldValue.serverTimestamp() : null,
    });
    return true;
  }
}
