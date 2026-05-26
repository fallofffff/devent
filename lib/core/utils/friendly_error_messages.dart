import 'package:firebase_auth/firebase_auth.dart';

String friendlyErrorMessage(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  final text = error.toString().toLowerCase();

  if (text.contains('socketexception') ||
      text.contains('networkrequestfailed') ||
      text.contains('network-request-failed') ||
      text.contains('failed host lookup') ||
      text.contains('connection refused') ||
      text.contains('connection timed out') ||
      text.contains('timeout') ||
      text.contains('no internet') ||
      text.contains('internet connection')) {
    return 'No internet connection. Check your network and try again.';
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No account found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'weak-password':
        return 'Password is too weak';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!.trim();
    }
  }

  if (text.contains('not authenticated')) {
    return 'Please sign in first.';
  }
  if (text.contains('event not found')) {
    return 'The event could not be found.';
  }
  if (text.contains('booking not found')) {
    return 'The booking could not be found.';
  }
  if (text.contains('permission-denied') || text.contains('permission_denied')) {
    return 'Booking could not be saved due to Firestore security rules. Deploy the latest firestore.rules from this project (firebase deploy --only firestore:rules), then try again.';
  }
  if (text.contains('you already booked')) {
    return 'You already booked this event.';
  }
  if (text.contains('no tickets available')) {
    return 'This event is sold out.';
  }
  if (text.contains('only the creator can change validation')) {
    return 'Only the event creator can validate bookings.';
  }
  if (text.contains('belongs to a different event')) {
    return 'This booking belongs to a different event.';
  }

  return fallback;
}