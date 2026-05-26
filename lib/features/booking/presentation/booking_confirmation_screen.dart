import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:devent/features/booking/presentation/providers/booking_providers.dart';
import 'package:devent/features/booking/domain/booking_model.dart';
import 'package:devent/features/events/presentation/event_defaults.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(bookingRepositoryProvider);
    return FutureBuilder<BookingModel?>(
      future: repo.fetchBookingById(bookingId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final booking = snap.data;
        if (booking == null) return Scaffold(body: Center(child: Text('Booking not found')));
        final imageUrl = booking.eventImageUrl.isNotEmpty ? booking.eventImageUrl : commonEventImageUrl;
        return Scaffold(
          appBar: AppBar(title: const Text('Booking Confirmation')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(booking.eventTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Event date: ${booking.eventDate.toLocal()}'),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: booking.qrData.isEmpty
                        ? const SizedBox(
                            width: 240,
                            height: 240,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : QrImageView(
                            data: booking.qrData,
                            version: QrVersions.auto,
                            size: 240.0,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Present this QR at the venue for validation.'),
              ],
            ),
          ),
        );
      },
    );
  }
}
