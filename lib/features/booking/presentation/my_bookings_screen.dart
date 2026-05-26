import 'package:devent/features/booking/presentation/providers/booking_providers.dart';
import 'package:devent/features/booking/presentation/booking_confirmation_screen.dart';
import 'package:devent/core/utils/friendly_error_messages.dart';
import 'package:devent/features/events/presentation/event_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devent/features/auth/presentation/providers/auth_providers.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  Future<void> _unbook(
    BuildContext context,
    WidgetRef ref, {
    required String bookingId,
    required String userId,
    required String eventId,
    required String eventTitle,
  }) async {
    final repo = ref.read(bookingRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.cancelBooking(bookingId: bookingId, userId: userId, eventId: eventId);
      messenger.showSnackBar(SnackBar(content: Text('$eventTitle unbooked')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e, fallback: 'Could not unbook the booking.'))));
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateChangesProvider);
    return auth.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));
        final bookingsAsync = ref.watch(userBookingsStreamProvider(user.uid));
        return bookingsAsync.when(
          data: (list) => Scaffold(
            appBar: AppBar(title: const Text('My Bookings')),
            body: list.isEmpty
                ? const Center(child: Text('No bookings yet'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final b = list[i];
                      return Dismissible(
                        key: ValueKey(b.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.close, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Unbook', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        confirmDismiss: (_) async {
                          final user = ref.read(authStateChangesProvider).asData?.value;
                          if (user == null) return false;
                          try {
                            await _unbook(
                              context,
                              ref,
                              bookingId: b.id,
                              userId: user.uid,
                              eventId: b.eventId,
                              eventTitle: b.eventTitle,
                            );
                            return true;
                          } catch (_) {
                            return false;
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Image.network(
                                b.eventImageUrl.isNotEmpty ? b.eventImageUrl : commonEventImageUrl,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                              ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                title: Text(b.eventTitle),
                                subtitle: Text(
                                  b.eventDate.toLocal().toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.qr_code),
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingConfirmationScreen(bookingId: b.id)));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, st) {
            final message = e.toString();
            final text = message.contains('permission-denied') || message.contains('PERMISSION_DENIED')
                ? 'Firestore rules need to allow booking reads for your account.'
                : message;
            return Scaffold(body: Center(child: Text(text)));
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) {
        final message = e.toString();
        final text = message.contains('permission-denied') || message.contains('PERMISSION_DENIED')
            ? 'Firestore rules need to allow booking reads for your account.'
            : message;
        return Scaffold(body: Center(child: Text(text)));
      },
    );
  }
}