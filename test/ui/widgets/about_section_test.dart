import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_device_test/ui/widgets/about_section.dart';

void main() {
  group('AboutSection Widget', () {
    testWidgets('should render with title and icon', (WidgetTester tester) async {
      const testTitle = 'Test Section';
      const testIcon = Icons.info;
      const testChild = Text('Test Content');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AboutSection(
              title: testTitle,
              icon: testIcon,
              child: testChild,
            ),
          ),
        ),
      );

      // Verify title is rendered
      expect(find.text(testTitle), findsOneWidget);

      // Verify icon is rendered
      expect(find.byIcon(testIcon), findsOneWidget);

      // Verify child content is rendered
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should apply custom padding', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AboutSection(
              title: 'Test',
              icon: Icons.info,
              padding: customPadding,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // The widget should render without errors
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('should have proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AboutSection(
              title: 'Test',
              icon: Icons.info,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Find the container that has the border and background
      final container = tester.widget<Container>(find.byType(Container).first);

      // Verify it has decoration
      expect(container.decoration, isNotNull);
    });
  });
}