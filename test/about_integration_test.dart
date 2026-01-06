import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ble_device_test/ui/screens/about_screen.dart';
import 'package:ble_device_test/ui/widgets/about_section.dart';
import 'package:ble_device_test/ui/widgets/developer_card.dart';
import 'package:ble_device_test/ui/widgets/library_list.dart';

void main() {
  group('About Page Integration Tests', () {
    testWidgets('AboutScreen renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );

      // Verify the screen builds
      expect(find.byType(AboutScreen), findsOneWidget);
      
      // Verify app bar exists
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);
      
      // Verify refresh button exists
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('AboutSection widget renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AboutSection(
              title: 'Test Section',
              icon: Icons.info,
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('LibraryList widget handles empty list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryList(dependencies: []),
          ),
        ),
      );

      expect(find.text('暂无依赖信息'), findsOneWidget);
    });

    testWidgets('LibraryList widget renders dependencies', (WidgetTester tester) async {
      final testDeps = [
        {
          'name': 'flutter',
          'version': '3.0.0',
          'type': 'prod',
          'isPopular': true,
          'description': 'Flutter SDK',
        },
        {
          'name': 'test_package',
          'version': '1.0.0',
          'type': 'dev',
          'isPopular': false,
          'description': 'Test package',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryList(dependencies: testDeps),
          ),
        ),
      );

      // Should show production dependencies section
      expect(find.text('生产依赖 (1)'), findsOneWidget);
      // Should show development dependencies section
      expect(find.text('开发依赖 (1)'), findsOneWidget);
      // Should show package names
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('test_package'), findsOneWidget);
    });

    testWidgets('DeveloperCard widget renders with data', (WidgetTester tester) async {
      final testData = {
        'username': 'testuser',
        'name': 'Test User',
        'avatarUrl': '', // Empty URL to test fallback
        'bio': 'Test bio',
        'location': 'Test location',
        'createdAt': '2023-01-01T00:00:00Z',
        'followers': 10,
        'following': 5,
        'publicRepos': 2,
        'profileUrl': 'https://github.com/testuser',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeveloperCard(
              githubData: testData,
              onCopyLink: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('@testuser'), findsOneWidget);
      expect(find.text('Test bio'), findsOneWidget);
      expect(find.text('Test location'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // Followers
      expect(find.text('5'), findsOneWidget); // Following
      expect(find.text('2'), findsOneWidget); // Repos
    });

    testWidgets('DeveloperCard handles missing data', (WidgetTester tester) async {
      final testData = {
        'username': 'testuser',
        'name': '',
        'avatarUrl': '',
        'bio': '',
        'location': '',
        'createdAt': '',
        'followers': 0,
        'following': 0,
        'publicRepos': 0,
        'profileUrl': '',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeveloperCard(
              githubData: testData,
              onCopyLink: () {},
            ),
          ),
        ),
      );

      // Should still render with fallback values
      expect(find.text('@testuser'), findsOneWidget);
      // Stats should show 0 (there are 3 stats, so 3 zeros)
      expect(find.text('0'), findsNWidgets(3));
    });
  });
}