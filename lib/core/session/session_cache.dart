import 'package:devent/features/booking/presentation/providers/booking_providers.dart';
import 'package:devent/features/events/presentation/event_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clears cached bookings and events so a new login does not reuse the prior account.
void invalidateUserDataCache(Ref ref) {
  ref.invalidate(createBookingProvider);
  ref.invalidate(hasUserBookedEventProvider);
  ref.invalidate(userBookingsStreamProvider);
  ref.invalidate(eventListStreamProvider);
  ref.invalidate(eventSearchQueryProvider);
  ref.invalidate(filteredEventListProvider);
  ref.invalidate(currentUserCreatedEventsProvider);
}
