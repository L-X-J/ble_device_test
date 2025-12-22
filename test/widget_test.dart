// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:ble_device_test/main.dart';

void main() {
  testWidgets('BLE Device Manager smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BLEDeviceManagerApp());

    // Verify that the app builds successfully.
    expect(find.text('BLE设备管理器'), findsOneWidget);

    // Verify that device management screen is shown
    expect(find.text('设备管理'), findsOneWidget);
  });
}
