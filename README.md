# devent

A new Flutter project.

## Firestore Rules

This workspace now includes `firestore.rules` for the booking and QR flows.
Deploy it with the Firebase CLI so the app can:
- read the signed-in user's bookings,
- create bookings while decrementing ticket inventory,
- validate a booking from the QR scanner.

If you use the Firebase CLI, `firebase.json` already points to `firestore.rules`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
