import 'package:flutter_test/flutter_test.dart';
import 'package:ble_device_test/services/github_service.dart';

void main() {
  group('GitHubService', () {
    late GitHubService service;

    setUp(() {
      service = GitHubService();
    });

    test('should check API status', () async {
      // This test will actually call GitHub API
      // In a real test environment, you might want to mock this
      final status = await service.checkApiStatus();
      expect(status, isTrue);
    });

    test('should handle invalid username gracefully', () async {
      // Test with a username that likely doesn't exist
      // This will test error handling
      expect(
        () => service.getUserInfo('nonexistent_user_123456789'),
        throwsA(isA<Exception>()),
      );
    });

    test('should return null for invalid user', () async {
      // Test the error handling for 404
      try {
        await service.getUserInfo('nonexistent_user_123456789');
        // If we get here, the test should fail
        expect(true, false, reason: 'Should have thrown an exception');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('未找到用户'));
      }
    });
  });
}