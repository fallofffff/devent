import 'package:devent/core/utils/friendly_error_messages.dart';

/// Converts Firebase Auth exceptions to user-friendly error messages
String getAuthErrorMessage(Object error) {
  if (error is StateError && error.message.contains('no user')) {
    return 'Failed to create account. Please try again';
  }

  return friendlyErrorMessage(
    error,
    fallback: 'An unexpected error occurred. Please try again.',
  );
}
