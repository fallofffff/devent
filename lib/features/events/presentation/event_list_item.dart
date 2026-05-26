import 'package:devent/features/events/domain/event_model.dart';
import 'package:devent/features/events/presentation/event_defaults.dart';
import 'package:devent/core/utils/app_date_formatters.dart';
import 'package:flutter/material.dart';

class EventListItem extends StatelessWidget {
  const EventListItem({super.key, required this.event, required this.onTap, required this.isCreator, this.onRemove});

  final EventModel event;
  final VoidCallback onTap;
  final bool isCreator;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl.isNotEmpty ? event.imageUrl : commonEventImageUrl;
    final soldOut = event.availableTickets <= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isCreator ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(imageUrl, width: 64, height: 64, fit: BoxFit.cover),
            ),
            title: Row(
              children: [
                Expanded(child: Text(event.title)),
              ],
            ),
            subtitle: Text('${AppDateFormatters.dateTime.format(event.date)} • ${event.location}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                soldOut
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Sold out',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${event.availableTickets}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'tickets left',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                if (isCreator && onRemove != null) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: const CircleBorder(),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                      tooltip: 'Remove event',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
