import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:devent/features/booking/presentation/providers/booking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devent/features/auth/presentation/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:devent/features/events/domain/event_model.dart';
import 'package:devent/features/events/presentation/event_providers.dart';
import 'package:devent/core/utils/app_date_formatters.dart';
import 'package:devent/core/utils/friendly_error_messages.dart';
import 'package:permission_handler/permission_handler.dart';

class QrValidatorScreen extends ConsumerStatefulWidget {
  const QrValidatorScreen({super.key, required this.isActive});

  final bool isActive;

  @override
  ConsumerState<QrValidatorScreen> createState() => _QrValidatorScreenState();
}

class _QrValidatorScreenState extends ConsumerState<QrValidatorScreen> {
  String? _message;
  bool _isValidated = false;
  bool _isScanningLocked = false;
  String? _selectedEventId;
  String? _lastScannedValue;
  PermissionStatus? _cameraPermissionStatus;
  bool _checkingCameraPermission = false;

  @override
  void didUpdateWidget(covariant QrValidatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _resetValidationState();
    }
    if (!oldWidget.isActive && widget.isActive) {
      _ensureCameraPermission();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _ensureCameraPermission();
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!widget.isActive || _isScanningLocked) return;
    final selectedEventId = _selectedEventId;
    if (selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose one of your events first.')),
      );
      return;
    }
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? '';
    if (raw.isEmpty || raw == _lastScannedValue) return;

    _lastScannedValue = raw;
    _isScanningLocked = true;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _isScanningLocked = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before validating bookings.')),
      );
      return;
    }

    final events = ref.read(eventListStreamProvider).asData?.value ?? const <EventModel>[];
    final eventTitle = _findEventById(
      events.where((e) => e.organizerId == firebaseUser.uid).toList(),
      selectedEventId,
    )?.title;

    final repo = ref.read(bookingRepositoryProvider);
    try {
      final ok = await repo.validateBookingByQrForEvent(qrData: raw, eventId: selectedEventId);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _isValidated = true;
          _message = eventTitle != null ? 'Validated for $eventTitle' : 'Booking validated';
        });
      } else {
        setState(() {
          _isScanningLocked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching booking for this event.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanningLocked = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyErrorMessage(e, fallback: 'Validation failed. Please try again.')),
        ),
      );
    }
  }

  void _resetValidationState() {
    _lastScannedValue = null;
    setState(() {
      _isValidated = false;
      _isScanningLocked = false;
      _message = null;
    });
  }

  Future<void> _selectEventAndRequestPermission(String eventId) async {
    setState(() {
      _selectedEventId = eventId;
      _isValidated = false;
      _isScanningLocked = false;
      _message = null;
      _lastScannedValue = null;
    });
    await _ensureCameraPermission(forceRequest: true);
  }

  void _clearSelectedEvent() {
    setState(() {
      _selectedEventId = null;
      _isValidated = false;
      _isScanningLocked = false;
      _message = null;
      _lastScannedValue = null;
    });
  }

  void _scanAgain() {
    _resetValidationState();
  }

  Future<void> _ensureCameraPermission({bool forceRequest = false}) async {
    if (_checkingCameraPermission) return;

    setState(() {
      _checkingCameraPermission = true;
    });

    try {
      var status = await Permission.camera.status;
      if (forceRequest && !status.isGranted) {
        status = await Permission.camera.request();
      }
      if (!mounted) return;
      setState(() {
        _cameraPermissionStatus = status;
        _checkingCameraPermission = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraPermissionStatus = PermissionStatus.denied;
        _checkingCameraPermission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateChangesProvider);
    final eventsAsync = ref.watch(eventListStreamProvider);
    final cameraPermissionStatus = _cameraPermissionStatus;

    return Scaffold(
      appBar: AppBar(title: const Text('QR Validator')),
      body: eventsAsync.when(
        data: (events) {
          final user = auth.asData?.value;
          final creatorEvents = user == null
              ? const <EventModel>[]
              : events.where((event) => event.organizerId == user.uid).toList();
          final selectedEvent = _selectedEventId == null
              ? null
              : _findEventById(creatorEvents, _selectedEventId!);

          if (_isValidated) {
            return _ValidationSuccessView(
              message: _message ?? 'Booking validated',
              onScanAgain: _scanAgain,
            );
          }
          if (selectedEvent == null) {
            return _EventSelectionView(
              events: creatorEvents,
              onValidateEvent: _selectEventAndRequestPermission,
            );
          }
          if (_checkingCameraPermission || cameraPermissionStatus == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (cameraPermissionStatus != PermissionStatus.granted) {
            return _CameraPermissionPrompt(
              status: cameraPermissionStatus,
              onEnable: () => _ensureCameraPermission(forceRequest: true),
              onOpenSettings: () async {
                final opened = await openAppSettings();
                if (mounted) {
                  await _ensureCameraPermission(forceRequest: true);
                }
                return opened;
              },
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SelectedEventBanner(
                  event: selectedEvent,
                  onChangeEvent: _clearSelectedEvent,
                ),
              ),
              Expanded(
                child: _QrScannerView(
                  key: ValueKey('scanner-${selectedEvent.id}'),
                  isActive: widget.isActive,
                  onDetect: _onDetect,
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(friendlyErrorMessage(error, fallback: 'Could not load events for validation.')),
          ),
        ),
      ),
    );
  }

  EventModel? _findEventById(List<EventModel> events, String eventId) {
    for (final event in events) {
      if (event.id == eventId) {
        return event;
      }
    }
    return null;
  }
}

/// Owns [MobileScannerController] and starts the camera only after layout is
/// ready (avoids Android NPE in CameraX surface setup).
class _QrScannerView extends StatefulWidget {
  const _QrScannerView({
    super.key,
    required this.isActive,
    required this.onDetect,
  });

  final bool isActive;
  final void Function(BarcodeCapture capture) onDetect;

  @override
  State<_QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<_QrScannerView> with WidgetsBindingObserver {
  MobileScannerController? _controller;
  bool _cameraStarted = false;
  bool _startingCamera = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    if (widget.isActive) {
      _scheduleCameraStart();
    }
  }

  @override
  void didUpdateWidget(covariant _QrScannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _stopCamera();
    } else if (!oldWidget.isActive && widget.isActive) {
      _scheduleCameraStart();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (widget.isActive) {
          _scheduleCameraStart();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopCamera();
        break;
    }
  }

  void _scheduleCameraStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
  }

  Future<void> _startCamera() async {
    final controller = _controller;
    if (controller == null || !widget.isActive || _startingCamera) return;

    _startingCamera = true;
    try {
      if (controller.value.isRunning) {
        await controller.stop();
      }
      // Let the platform view attach before CameraX requests a surface.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted || !widget.isActive) return;
      await controller.start();
      if (!mounted) return;
      setState(() {
        _cameraStarted = true;
        _cameraError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraStarted = false;
        _cameraError = e.toString();
      });
    } finally {
      _startingCamera = false;
    }
  }

  Future<void> _stopCamera() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (controller.value.isRunning) {
        await controller.stop();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _cameraStarted = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const Center(
        child: Text('Switch to the Validate tab to scan.'),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'Camera could not start. Try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() => _cameraError = null);
                  _scheduleCameraStart();
                },
                child: const Text('Retry camera'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              fit: BoxFit.cover,
              onDetect: widget.onDetect,
              errorBuilder: (context, error) {
                return Center(
                  child: Text(
                    friendlyErrorMessage(error, fallback: 'Camera error while scanning.'),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            if (!_cameraStarted)
              const ColoredBox(
                color: Colors.black87,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }
}

class _EventSelectionView extends StatelessWidget {
  const _EventSelectionView({required this.events, required this.onValidateEvent});

  final List<EventModel> events;
  final Future<void> Function(String eventId) onValidateEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_outlined, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'No events available to validate',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You can only validate bookings for events you created. Create an event first, then come back here.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Choose an event to validate',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Only events created by you are shown here.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...events.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onValidateEvent(event.id),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 108,
                      height: 132,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                        image: DecorationImage(
                          image: NetworkImage(event.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppDateFormatters.dateTime.format(event.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: () => onValidateEvent(event.id),
                              child: const Text('Validate this event'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedEventBanner extends StatelessWidget {
  const _SelectedEventBanner({required this.event, required this.onChangeEvent});

  final EventModel event;
  final VoidCallback onChangeEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: DecorationImage(
                  image: NetworkImage(event.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to scan bookings for this event',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onChangeEvent,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _ValidationSuccessView extends StatelessWidget {
  const _ValidationSuccessView({required this.message, required this.onScanAgain});

  final String message;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedScale(
          scale: 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 250),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade700,
                    Colors.grey.shade900,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 72),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The booking has been marked as validated successfully.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: onScanAgain,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey.shade900,
                    ),
                    child: const Text('Scan another booking'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraPermissionPrompt extends StatelessWidget {
  const _CameraPermissionPrompt({required this.status, required this.onEnable, required this.onOpenSettings});

  final PermissionStatus? status;
  final VoidCallback onEnable;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permanentlyDenied = status?.isPermanentlyDenied == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Camera access needed',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Allow camera permission to scan QR codes for booking validation.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onEnable,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Enable camera'),
              ),
              if (permanentlyDenied) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await onOpenSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Open app settings'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}