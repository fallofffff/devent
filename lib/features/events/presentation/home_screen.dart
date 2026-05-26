import 'package:devent/core/presentation/settings_screen.dart';
import 'package:devent/core/presentation/notifications_screen.dart';
import 'package:devent/core/notifications/notification_repository.dart';
import 'package:devent/core/notifications/notification_service.dart';
import 'package:devent/features/booking/presentation/my_bookings_screen.dart';
import 'package:devent/features/booking/presentation/qr_validator_screen.dart';
import 'package:devent/features/events/presentation/event_create_sheet.dart';
import 'package:devent/features/events/presentation/event_list_item.dart';
import 'package:devent/features/events/presentation/event_providers.dart';
import 'package:devent/core/utils/friendly_error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devent/features/booking/presentation/providers/booking_providers.dart';
import 'package:devent/features/booking/presentation/booking_confirmation_screen.dart';
import 'package:devent/features/auth/presentation/providers/auth_providers.dart';
import 'package:devent/core/utils/app_date_formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _EventsPlaceholder(),
      const MyBookingsScreen(),
      QrValidatorScreen(isActive: _index == 2),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () async {
                final created = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  builder: (_) => const EventCreateSheet(),
                );

                if (created == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event published')),
                  );
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Validate'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _EventsPlaceholder extends ConsumerWidget {
  const _EventsPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final repo = ref.watch(eventRepositoryProvider);
    final eventsAsync = ref.watch(eventListStreamProvider);
    final query = ref.watch(eventSearchQueryProvider);
    final hasUnreadNotifications = ref.watch(hasUnreadNotificationsProvider);
    final visibleEvents = eventsAsync.whenData((list) {
      if (query.isEmpty) return list;
      final q = query.toLowerCase();
      return list.where((event) => event.title.toLowerCase().contains(q)).toList();
    });

    ref.listen(recentNotificationsProvider, (previous, next) {
      if (previous == null) {
        return;
      }
      final previousList = previous.valueOrNull;
      final previousId = previousList != null && previousList.isNotEmpty ? previousList.first.id : null;
      final nextList = next.valueOrNull;
      if (nextList == null || nextList.isEmpty) {
        return;
      }
      final nextId = nextList.first.id;
      if (nextId != previousId) {
        ref.read(notificationServiceProvider).showInstant(
              id: nextId.hashCode,
              title: nextList.first.title,
              body: nextList.first.body,
            );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (hasUnreadNotifications)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover events',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Browse, open, and manage your event list in one place.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        labelText: 'Search events',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onChanged: (value) => ref.read(eventSearchQueryProvider.notifier).state = value,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            sliver: eventsAsync.when(
              data: (events) {
                final filtered = visibleEvents.value ?? const [];
                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No events found')),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final e = filtered[index];
                      final isCreator = user?.uid == e.organizerId;
                      return EventListItem(
                        event: e,
                        isCreator: isCreator,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => EventDetailScreen(event: e),
                          ));
                        },
                        onRemove: isCreator
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Remove event?'),
                                    content: const Text('This will delete the event and its bookings.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(dialogContext).pop(true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true || !context.mounted) {
                                  return;
                                }

                                try {
                                  await repo.deleteEvent(eventId: e.id);
                                  messenger.showSnackBar(const SnackBar(content: Text('Event removed')));
                                } catch (error) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(friendlyErrorMessage(error, fallback: 'Could not remove the event.'))),
                                  );
                                }
                              }
                            : null,
                      );
                    },
                    childCount: filtered.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(friendlyErrorMessage(error, fallback: 'Could not load events.')),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.event});

  final dynamic event;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _bookingInProgress = false;
  bool _bookedLocally = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final isCreator = user?.uid == widget.event.organizerId;
    final bookedAsync = user == null
        ? const AsyncValue<bool>.data(false)
        : ref.watch(hasUserBookedEventProvider((userId: user.uid, eventId: widget.event.id)));

    return Scaffold(
      appBar: AppBar(title: Text(widget.event.title)),
      backgroundColor: isCreator ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.event.imageUrl.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      widget.event.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.event.organizerName} • ${widget.event.location}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppDateFormatters.dateTime.format(widget.event.date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Text(widget.event.description),
            const SizedBox(height: 20),
            bookedAsync.when(
              loading: () => const SizedBox(
                width: double.infinity,
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Could not check booking status'),
                ),
              ),
              data: (alreadyBookedFromServer) {
                final alreadyBooked = alreadyBookedFromServer || _bookedLocally;
                final canBook = user != null &&
                    widget.event.availableTickets > 0 &&
                    !alreadyBooked &&
                    !_bookingInProgress;

                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canBook
                        ? () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _bookingInProgress = true);
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            try {
                              final result = await ref.read(createBookingProvider.notifier).createBooking(
                                    eventId: widget.event.id,
                                    eventTitle: widget.event.title,
                                    eventDate: widget.event.date,
                                    eventImageUrl: widget.event.imageUrl,
                                  );
                              if (!mounted) return;
                              navigator.pop();
                              final bookingId = result['bookingId'];
                              if (bookingId != null && bookingId.isNotEmpty) {
                                setState(() => _bookedLocally = true);
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => BookingConfirmationScreen(bookingId: bookingId),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Booking failed. Please try again.')),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    friendlyErrorMessage(e, fallback: 'Booking failed. Please try again.'),
                                  ),
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _bookingInProgress = false);
                              }
                            }
                          }
                        : null,
                    icon: Icon(alreadyBooked ? Icons.verified_outlined : Icons.confirmation_number_outlined),
                    label: Text(
                      user == null
                          ? 'Sign in to book'
                          : alreadyBooked
                              ? 'Already Booked'
                              : widget.event.availableTickets > 0
                                  ? 'Book Now'
                                  : 'Sold Out',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}