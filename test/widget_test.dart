// IntelliPost Flutter App Widget Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';
import 'package:app/services/services.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Create test services
    final storageService = StorageService();
    await storageService.init();
    final apiService = RealApiService();

    // Build our app and trigger a frame
    await tester.pumpWidget(IntelliPostApp(
      storageService: storageService,
      apiService: apiService,
    ));
    await tester.pumpAndSettle();

    // Verify app loads - check for login screen elements
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
