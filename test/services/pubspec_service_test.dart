import 'package:flutter_test/flutter_test.dart';
import 'package:ble_device_test/services/pubspec_service.dart';

void main() {
  group('PubspecService', () {
    late PubspecService service;

    setUp(() {
      service = PubspecService();
    });

    test('should extract dependencies from hardcoded data', () async {
      final dependencies = await service.extractDependencies();

      // Verify that we got the expected number of dependencies
      expect(dependencies, isNotEmpty);
      expect(
        dependencies.length,
        greaterThan(10),
      ); // Should have at least 10 dependencies

      // Verify that each dependency has the required fields
      for (final dep in dependencies) {
        expect(dep['name'], isNotNull);
        expect(dep['version'], isNotNull);
        expect(dep['type'], isNotNull);
        expect(dep['isPopular'], isNotNull);
        expect(dep['description'], isNotNull);
      }

      // Verify that flutter is included
      final flutterDep = dependencies.firstWhere(
        (dep) => dep['name'] == 'flutter',
        orElse: () => {},
      );
      expect(flutterDep, isNotEmpty);
      expect(flutterDep['isPopular'], true);
    });

    test('should categorize dependencies correctly', () async {
      final dependencies = await service.extractDependencies();

      // Check that we have both production and development dependencies
      final prodDeps = dependencies.where((d) => d['type'] == 'prod').toList();
      final devDeps = dependencies.where((d) => d['type'] == 'dev').toList();

      // We should have at least one of each type
      expect(prodDeps.length, greaterThan(0));
      expect(devDeps.length, greaterThan(0));
    });

    test('should identify popular packages', () async {
      final dependencies = await service.extractDependencies();

      // Check that popular packages are identified
      final flutterDep = dependencies.firstWhere(
        (dep) => dep['name'] == 'flutter',
        orElse: () => {},
      );

      if (flutterDep.isNotEmpty) {
        expect(flutterDep['isPopular'], true);
      }
    });

    test('should get project info', () async {
      final info = await service.getProjectInfo();

      // Should have basic project information
      expect(info['name'], isNotNull);
      expect(info['version'], isNotNull);
      expect(info['description'], isNotNull);

      // Verify the expected values
      expect(info['name'], 'ble_device_test');
      expect(info['version'], '1.0.0+1');
      expect(info['description'], '一个Ble 设备调试工具');
    });
  });
}
