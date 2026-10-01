// Smoke test for the Aviator Flight Grid screen state machine.
//
// The artwork under assets/ is produced by the asset pipeline and is not part
// of the source tree, so image-load failures are tolerated here on purpose —
// this test is about navigation, not about pixels.

import 'package:aviator_flight_grid/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Loader brands the app, then hands over to the menu', (
    WidgetTester tester,
  ) async {
    final FlutterExceptionHandler? previousHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('Unable to load asset')) {
        return;
      }
      previousHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.pumpWidget(const AviatorFlightGridApp());
    await tester.pump();

    expect(find.text('AVIATOR'), findsOneWidget);
    expect(find.text('LOADING…'), findsOneWidget);
    expect(find.text('START FLIGHT'), findsNothing);

    // The loader hands over after exactly 8s.
    await tester.pump(const Duration(milliseconds: 8100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('START FLIGHT'), findsOneWidget);
    expect(find.text('AVIATOR FLIGHT GRID'), findsOneWidget);
  });
}
