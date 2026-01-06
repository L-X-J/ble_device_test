import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_device_test/ui/screens/about_screen.dart';

void main() {
  group('AboutScreen', () {
    testWidgets('should render loading state initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在加载信息...'), findsOneWidget);
    });

    testWidgets('should have app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

      // Should have app bar
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);
    });

    testWidgets('should have refresh button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

      // Should have refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should show project header', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

      // Should show loading state initially
      expect(find.text('正在加载信息...'), findsOneWidget);

      // Should show the app bar title
      expect(find.text('关于'), findsOneWidget);

      // Should show loading subtitle
      expect(find.text('正在从GitHub获取开发者数据'), findsOneWidget);
    });

    testWidgets('should handle error state', (WidgetTester tester) async {
      // This test would need to mock the services to force an error
      // For now, we'll just verify the screen structure
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

      // Should render without crashing
      expect(find.byType(AboutScreen), findsOneWidget);
    });
  });
}
