import 'package:intl/intl.dart';

class AppDateFormatters {
  const AppDateFormatters._();

  static final DateFormat dateTime = DateFormat('EEE, MMM d, yyyy - h:mm a');
  static final DateFormat dateOnly = DateFormat('EEE, MMM d, yyyy');
}