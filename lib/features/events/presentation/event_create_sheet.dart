import 'package:devent/features/auth/presentation/providers/auth_providers.dart';
import 'package:devent/core/utils/friendly_error_messages.dart';
import 'package:devent/features/events/presentation/event_defaults.dart';
import 'package:devent/features/events/presentation/event_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventCreateSheet extends ConsumerStatefulWidget {
  const EventCreateSheet({super.key});

  @override
  ConsumerState<EventCreateSheet> createState() => _EventCreateSheetState();
}

class _EventCreateSheetState extends ConsumerState<EventCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _organizerController = TextEditingController();
  final _ticketsController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late final String _selectedImageUrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedImageUrl = pickRandomEventImageUrl();
    final user = ref.read(authStateChangesProvider).asData?.value;
    _organizerController.text = user?.name.trim().isNotEmpty == true ? user!.name.trim() : (user?.email.split('@').first ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    _ticketsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedDate == null || _selectedTime == null) {
      setState(() {
        _error = 'Please choose a date and time.';
      });
      return;
    }

    final eventDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (!eventDate.isAfter(DateTime.now())) {
      setState(() {
        _error = 'Event date and time must be in the future.';
      });
      return;
    }

    final totalTickets = int.tryParse(_ticketsController.text.trim()) ?? 0;
    if (totalTickets <= 0) {
      setState(() {
        _error = 'Ticket count must be greater than zero.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(eventRepositoryProvider);
      await repo.createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        date: eventDate,
        location: _locationController.text,
        organizerName: _organizerController.text,
        totalTickets: totalTickets,
        imageUrl: _selectedImageUrl,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyErrorMessage(e, fallback: 'Could not create the event. Please try again.');
      });
      return;
    } finally {
      if (mounted && _saving) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Create Event',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    _selectedImageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Event title'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a title' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a description' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a location' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _organizerController,
                  decoration: const InputDecoration(labelText: 'Organizer name'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter organizer name' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ticketsController,
                  decoration: const InputDecoration(labelText: 'Total tickets'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final tickets = int.tryParse(value?.trim() ?? '');
                    if (tickets == null || tickets <= 0) {
                      return 'Enter a valid ticket count';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          _selectedDate == null
                              ? 'Pick date'
                              : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickTime,
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          _selectedTime == null
                              ? 'Pick time'
                              : _selectedTime!.format(context),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Publish event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}