import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devent/core/firebase/messaging_service.dart';
import 'package:devent/features/events/presentation/event_defaults.dart';
import 'package:devent/features/auth/data/auth_repository.dart';
import 'package:devent/features/auth/domain/app_user.dart';
import 'package:devent/features/auth/presentation/providers/auth_providers.dart';
import 'package:devent/features/booking/data/booking_repository.dart';
import 'package:devent/features/booking/domain/booking_model.dart';
import 'package:devent/features/booking/presentation/providers/booking_providers.dart';
import 'package:devent/features/events/data/event_repository.dart';
import 'package:devent/features/events/domain/event_model.dart';
import 'package:devent/features/events/presentation/event_providers.dart';
import 'package:devent/core/notifications/app_notification_model.dart';
import 'package:devent/core/notifications/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DemoBackendSession {
  DemoBackendSession._() {
    // Do not auto-login a demo user. Start with no signed-in user so
    // the app requires explicit sign-in or registration.
    _seedEvents();
  }

  static final DemoBackendSession instance = DemoBackendSession._();

  final StreamController<AppUser?> _authController = StreamController<AppUser?>.broadcast();
  final List<EventModel> _events = <EventModel>[];
  final List<BookingModel> _bookings = <BookingModel>[];
  final List<AppNotificationModel> _notifications = <AppNotificationModel>[];
  final StreamController<List<EventModel>> _eventController = StreamController<List<EventModel>>.broadcast();
  final StreamController<List<BookingModel>> _bookingController = StreamController<List<BookingModel>>.broadcast();
  final StreamController<List<AppNotificationModel>> _notificationController = StreamController<List<AppNotificationModel>>.broadcast();

  AppUser? currentUser;

  Stream<AppUser?> get authStream => _authController.stream;
  Stream<List<EventModel>> get eventStream => _eventController.stream;
  Stream<List<BookingModel>> get bookingStream => _bookingController.stream;
  Stream<List<AppNotificationModel>> get notificationStream => _notificationController.stream;

  void _seedEvents() {
    final now = DateTime.now();
    _events.addAll([
      EventModel(
        id: 'demo-event-1',
        title: 'Summer Music Night',
        description: 'A live evening show with food, lights, and local artists.',
        date: now.add(const Duration(days: 5)),
        location: 'Central Park Arena',
        organizerName: 'Devent Team',
        organizerId: 'demo-user',
        imageUrl: commonEventImageUrl,
        totalTickets: 120,
        availableTickets: 120,
        createdAt: now,
        snapshot: const Object(),
      ),
      EventModel(
        id: 'demo-event-2',
        title: 'Startup Meetup',
        description: 'Talks and networking for founders, students, and builders.',
        date: now.add(const Duration(days: 12)),
        location: 'City Hall Conference Room',
        organizerName: 'Devent Team',
        organizerId: 'demo-user',
        imageUrl: commonEventImageUrl,
        totalTickets: 80,
        availableTickets: 80,
        createdAt: now,
        snapshot: const Object(),
      ),
    ]);
    _emitEvents();
  }

  void _emitEvents() => _eventController.add(List<EventModel>.unmodifiable(_events));

  void _emitBookings() => _bookingController.add(List<BookingModel>.unmodifiable(_bookings));

  void _emitNotifications() => _notificationController.add(List<AppNotificationModel>.unmodifiable(_notifications));

  void setUser(AppUser? user) {
    currentUser = user;
    _authController.add(user);
  }

  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required String organizerName,
    required int totalTickets,
    required String imageUrl,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }

    final event = EventModel(
      id: 'demo-event-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: description,
      date: date,
      location: location,
      organizerName: organizerName,
      organizerId: user.uid,
      imageUrl: imageUrl,
      totalTickets: totalTickets,
      availableTickets: totalTickets,
      createdAt: DateTime.now(),
      snapshot: const Object(),
    );
    _events.insert(0, event);
    _emitEvents();
    _notifications.insert(
      0,
      AppNotificationModel(
        id: 'demo-notification-${DateTime.now().microsecondsSinceEpoch}',
        title: 'New event posted',
        body: '$title is now available',
        type: 'event',
        eventId: event.id,
        createdAt: DateTime.now(),
      ),
    );
    _emitNotifications();
    return event.id;
  }

  Future<Map<String, String>> createBooking({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    String eventImageUrl = '',
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }

    final eventIndex = _events.indexWhere((event) => event.id == eventId);
    if (eventIndex < 0) {
      throw StateError('Event not found');
    }

    final event = _events[eventIndex];
    if (event.availableTickets <= 0) {
      throw StateError('No tickets available');
    }

    if (_bookings.any((booking) => booking.userId == user.uid && booking.eventId == eventId)) {
      throw StateError('You already booked this event');
    }

    final bookingId = 'demo-booking-${DateTime.now().microsecondsSinceEpoch}';
    final qrData = bookingId + user.uid + eventId;
    final booking = BookingModel(
      id: bookingId,
      userId: user.uid,
      eventId: eventId,
      eventTitle: eventTitle,
      eventImageUrl: event.imageUrl,
      eventDate: eventDate,
      bookedAt: DateTime.now(),
      qrData: qrData,
      isValidated: false,
      validatedBy: null,
      validatedAt: null,
      snapshot: const Object(),
    );

    _events[eventIndex] = EventModel(
      id: event.id,
      title: event.title,
      description: event.description,
      date: event.date,
      location: event.location,
      organizerName: event.organizerName,
      organizerId: event.organizerId,
      imageUrl: event.imageUrl,
      totalTickets: event.totalTickets,
      availableTickets: event.availableTickets - 1,
      createdAt: event.createdAt,
      snapshot: event.snapshot,
    );
    _bookings.add(booking);
    _emitEvents();
    _emitBookings();

    return {'bookingId': bookingId, 'qrData': qrData};
  }

  Future<BookingModel?> fetchBookingById(String id) async {
    try {
      return _bookings.firstWhere((booking) => booking.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasUserBookedEvent({required String userId, required String eventId}) async {
    return _bookings.any((booking) => booking.userId == userId && booking.eventId == eventId);
  }

  Future<void> cancelBooking({required String bookingId, required String userId, required String eventId}) async {
    final bookingIndex = _bookings.indexWhere((booking) => booking.id == bookingId);
    if (bookingIndex < 0) {
      throw StateError('Booking not found');
    }

    final booking = _bookings[bookingIndex];
    if (booking.userId != userId) {
      throw StateError('Not allowed to remove this booking');
    }

    final eventIndex = _events.indexWhere((event) => event.id == eventId);
    if (eventIndex < 0) {
      throw StateError('Event not found');
    }

    _bookings.removeAt(bookingIndex);
    final event = _events[eventIndex];
    _events[eventIndex] = EventModel(
      id: event.id,
      title: event.title,
      description: event.description,
      date: event.date,
      location: event.location,
      organizerName: event.organizerName,
      organizerId: event.organizerId,
      imageUrl: event.imageUrl,
      totalTickets: event.totalTickets,
      availableTickets: event.availableTickets + 1,
      createdAt: event.createdAt,
      snapshot: event.snapshot,
    );
    _emitEvents();
    _emitBookings();
  }

  Future<void> deleteEvent({required String eventId}) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }

    final eventIndex = _events.indexWhere((event) => event.id == eventId);
    if (eventIndex < 0) {
      throw StateError('Event not found');
    }

    final event = _events[eventIndex];
    if (event.organizerId != user.uid) {
      throw StateError('Only the creator can remove this event');
    }

    _bookings.removeWhere((booking) => booking.eventId == eventId);
    _events.removeAt(eventIndex);
    _emitEvents();
    _emitBookings();
  }

  bool validateBookingByQr(String qrData) {
    return validateBookingByQrForEvent(qrData, eventId: '');
  }

  bool validateBookingByQrForEvent(String qrData, {required String eventId}) {
    for (var index = 0; index < _bookings.length; index++) {
      final booking = _bookings[index];
      if (booking.qrData == qrData) {
        final user = currentUser;
        final eventIndex = _events.indexWhere((event) => event.id == booking.eventId);
        if (user == null || eventIndex < 0 || _events[eventIndex].organizerId != user.uid) {
          throw StateError('Only the creator can change validation status');
        }
        if (eventId.isNotEmpty && booking.eventId != eventId) {
          throw StateError('This booking belongs to a different event');
        }

        _bookings[index] = BookingModel(
          id: booking.id,
          userId: booking.userId,
          eventId: booking.eventId,
          eventTitle: booking.eventTitle,
          eventImageUrl: booking.eventImageUrl,
          eventDate: booking.eventDate,
          bookedAt: booking.bookedAt,
          qrData: booking.qrData,
          isValidated: true,
          validatedBy: user.uid,
          validatedAt: DateTime.now(),
          snapshot: booking.snapshot,
        );
        _emitBookings();
        return true;
      }
    }
    return false;
  }

  bool unvalidateBookingByQr(String qrData) {
    for (var index = 0; index < _bookings.length; index++) {
      final booking = _bookings[index];
      if (booking.qrData == qrData) {
        final user = currentUser;
        final eventIndex = _events.indexWhere((event) => event.id == booking.eventId);
        if (user == null || eventIndex < 0 || _events[eventIndex].organizerId != user.uid) {
          throw StateError('Only the creator can change validation status');
        }

        _bookings[index] = BookingModel(
          id: booking.id,
          userId: booking.userId,
          eventId: booking.eventId,
          eventTitle: booking.eventTitle,
          eventImageUrl: booking.eventImageUrl,
          eventDate: booking.eventDate,
          bookedAt: booking.bookedAt,
          qrData: booking.qrData,
          isValidated: false,
          validatedBy: null,
          validatedAt: null,
          snapshot: booking.snapshot,
        );
        _emitBookings();
        return true;
      }
    }
    return false;
  }
}

class DemoNotificationRepository implements NotificationRepository {
  DemoNotificationRepository(this._session);

  final DemoBackendSession _session;

  @override
  Stream<List<AppNotificationModel>> streamRecentNotifications({int limit = 20}) {
    return Stream<List<AppNotificationModel>>.multi((controller) {
      controller.add(List<AppNotificationModel>.unmodifiable(_session._notifications.take(limit)));
      final sub = _session.notificationStream.listen((items) {
        controller.add(items.take(limit).toList());
      });
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> createEventNotification({required String eventId, required String title, required String body}) async {
    _session._notifications.insert(
      0,
      AppNotificationModel(
        id: 'demo-notification-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        body: body,
        type: 'event',
        eventId: eventId,
        createdAt: DateTime.now(),
      ),
    );
    _session._emitNotifications();
  }
}

class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this._session);

  final DemoBackendSession _session;

  @override
  Stream<AppUser?> authStateChanges() {
    return Stream<AppUser?>.multi((controller) {
      controller.add(_session.currentUser);
      final sub = _session.authStream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    _session.setUser(AppUser(uid: 'demo-user', name: email.split('@').first, email: email));
  }

  @override
  Future<void> registerWithEmailAndPassword({required String name, required String email, required String password}) async {
    _session.setUser(AppUser(uid: 'demo-user', name: name, email: email));
  }

  @override
  Future<void> signOut() async {
    _session.setUser(null);
  }
}

class DemoEventRepository implements EventRepository {
  DemoEventRepository(this._session);

  final DemoBackendSession _session;

  @override
  Future<String> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String location,
    required String organizerName,
    required int totalTickets,
    required String imageUrl,
  }) {
    return _session.createEvent(
      title: title,
      description: description,
      date: date,
      location: location,
      organizerName: organizerName,
      totalTickets: totalTickets,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<void> deleteEvent({required String eventId}) {
    return _session.deleteEvent(eventId: eventId);
  }

  @override
  Future<EventModel?> fetchEventById(String id) async {
    try {
      return _session._events.firstWhere((event) => event.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<EventModel>> streamEvents({int pageSize = 20, DocumentSnapshot? startAfter}) {
    return Stream<List<EventModel>>.multi((controller) {
      controller.add(List<EventModel>.unmodifiable(_session._events.take(pageSize)));
      final sub = _session.eventStream.listen((events) {
        controller.add(events.take(pageSize).toList());
      });
      controller.onCancel = sub.cancel;
    });
  }
}

class DemoBookingRepository implements BookingRepository {
  DemoBookingRepository(this._session);

  final DemoBackendSession _session;

  @override
  Future<Map<String, String>> createBooking({
    required String userId,
    required String eventId,
    required String eventTitle,
    String eventImageUrl = '',
    required DateTime eventDate,
  }) {
    return _session.createBooking(
      eventId: eventId,
      eventTitle: eventTitle,
      eventDate: eventDate,
        eventImageUrl: eventImageUrl,
    );
  }

  @override
  Future<bool> hasUserBookedEvent({required String userId, required String eventId}) {
    return _session.hasUserBookedEvent(userId: userId, eventId: eventId);
  }

  @override
  Future<void> cancelBooking({required String bookingId, required String userId, required String eventId}) {
    return _session.cancelBooking(bookingId: bookingId, userId: userId, eventId: eventId);
  }

  @override
  Future<BookingModel?> fetchBookingById(String id) => _session.fetchBookingById(id);

  @override
  Stream<List<BookingModel>> streamUserBookings(String userId) {
    return Stream<List<BookingModel>>.multi((controller) {
      controller.add(_session._bookings.where((booking) => booking.userId == userId).toList());
      final sub = _session.bookingStream.listen((bookings) {
        controller.add(bookings.where((booking) => booking.userId == userId).toList());
      });
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<bool> validateBookingByQr(String qrData) async {
    return _session.validateBookingByQr(qrData);
  }

  @override
  Future<bool> validateBookingByQrForEvent({required String qrData, required String eventId}) async {
    return _session.validateBookingByQrForEvent(qrData, eventId: eventId);
  }

  @override
  Future<bool> unvalidateBookingByQr(String qrData) async {
    return _session.unvalidateBookingByQr(qrData);
  }
}

class DemoMessagingService extends MessagingService {
  DemoMessagingService() : super.demo();
}

List<Override> demoProviderOverrides() {
  final session = DemoBackendSession.instance;

  return [
    authRepositoryProvider.overrideWithValue(DemoAuthRepository(session)),
    eventRepositoryProvider.overrideWithValue(DemoEventRepository(session)),
    bookingRepositoryProvider.overrideWithValue(DemoBookingRepository(session)),
    notificationRepositoryProvider.overrideWithValue(DemoNotificationRepository(session)),
    messagingServiceProvider.overrideWithValue(DemoMessagingService()),
  ];
}
