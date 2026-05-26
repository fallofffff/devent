import 'package:devent/features/booking/data/booking_repository.dart';
import 'package:devent/features/booking/domain/booking_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devent/core/firebase/messaging_service.dart';
import 'package:devent/core/notifications/notification_service.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return FirestoreBookingRepository();
});

final createBookingProvider = AsyncNotifierProvider<CreateBookingController, void>(CreateBookingController.new);

class CreateBookingController extends AsyncNotifier<void> {
  BookingRepository get _repo => ref.read(bookingRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<Map<String, String>> createBooking({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    String eventImageUrl = '',
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw StateError('Not authenticated');
    final userId = currentUser.uid;
    state = const AsyncLoading();
    try {
      final result = await _repo.createBooking(
        userId: userId,
        eventId: eventId,
        eventTitle: eventTitle,
        eventDate: eventDate,
        eventImageUrl: eventImageUrl,
      );
      // persist device token (best-effort)
      try {
        await ref.read(messagingServiceProvider).getAndSaveDeviceToken(userId: userId);
      } catch (_) {}

      // schedule a local reminder one day before the event
      try {
        final bookingId = result['bookingId'] ?? '';
        final reminderDate = eventDate.subtract(const Duration(days: 1));
        await ref.read(notificationServiceProvider).scheduleReminder(
          id: bookingId.hashCode,
          title: 'Upcoming event',
          body: eventTitle,
          scheduledDate: reminderDate,
        );
      } catch (_) {}

      state = const AsyncData(null);
      ref.invalidate(hasUserBookedEventProvider((userId: userId, eventId: eventId)));
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

typedef HasUserBookedEventParams = ({String userId, String eventId});

final hasUserBookedEventProvider = FutureProvider.autoDispose
    .family<bool, HasUserBookedEventParams>((ref, params) {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.hasUserBookedEvent(userId: params.userId, eventId: params.eventId);
});

final userBookingsStreamProvider = StreamProvider.autoDispose.family<List<BookingModel>, String>((ref, userId) {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.streamUserBookings(userId);
});
