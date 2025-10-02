// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import this

import 'package:fuelgauge_tracker/main.dart'; // Use the new project name
import 'package:fuelgauge_tracker/providers/theme_manager.dart'; // Use the new project name

void main() {
  // This line is crucial for tests that use SharedPreferences.
  // It provides a "fake" storage for the test environment.
  SharedPreferences.setMockInitialValues({});

  testWidgets('Dashboard loads and displays key widgets',
      (WidgetTester tester) async {
    // 1. Build our app, wrapped in the necessary provider.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeManager(),
        child: const FuelTrackerApp(),
      ),
    );

    // 2. Wait for any loading animations or data futures to complete.
    await tester.pumpAndSettle();

    // 3. Now, verify that the widgets are on the screen.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Avg. Consumption'), findsOneWidget);
    expect(find.text('Add Fuel Log'), findsOneWidget);
  });
}
