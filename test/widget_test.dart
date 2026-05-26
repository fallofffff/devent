import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:devent/app.dart';

void main() {
  testWidgets('renders the app shell without Firebase', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DeventApp(firebaseReady: false),
      ),
    );
    expect(find.text('Firebase setup required'), findsOneWidget);
  });
}
