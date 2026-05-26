import 'package:devent/features/events/data/event_repository.dart';
import 'package:devent/features/events/domain/event_model.dart';
import 'package:devent/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return FirestoreEventRepository();
});

final eventListStreamProvider = StreamProvider.autoDispose<List<EventModel>>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.streamEvents(pageSize: 50);
});

final eventSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredEventListProvider = Provider.autoDispose<List<EventModel>>((ref) {
  final eventsAsync = ref.watch(eventListStreamProvider);
  final query = ref.watch(eventSearchQueryProvider);
  return eventsAsync.maybeWhen(
    data: (list) {
      if (query.isEmpty) return list;
      final q = query.toLowerCase();
      return list.where((e) => e.title.toLowerCase().contains(q)).toList();
    },
    orElse: () => [],
  );
});

final currentUserCreatedEventsProvider = Provider.autoDispose<List<EventModel>>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  final eventsAsync = ref.watch(eventListStreamProvider);
  final organizerId = user?.uid;

  if (organizerId == null) {
    return const [];
  }

  return eventsAsync.maybeWhen(
    data: (list) => list.where((event) => event.organizerId == organizerId).toList(),
    orElse: () => const [],
  );
});
