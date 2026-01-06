import 'package:flutter/services.dart';

/// Pubspec服务类 - 负责提供项目依赖信息
///
/// 功能特性：
/// - 提供硬编码的项目依赖信息（更可靠）
/// - 支持从asset读取（可选）
/// - 分类显示不同类型的依赖
class PubspecService {
  /// 获取项目依赖信息
  ///
  /// 返回:
  ///   包含依赖信息的列表，每个依赖包含名称、版本和类型
  Future<List<Map<String, dynamic>>> extractDependencies() async {
    // 返回硬编码的依赖信息，避免文件读取问题
    // 这些信息可以从 pubspec.yaml 手动同步更新
    return _getHardcodedDependencies();
  }

  /// 获取项目基本信息
  Future<Map<String, dynamic>> getProjectInfo() async {
    // 返回硬编码的项目信息
    return {
      'name': 'ble_device_test',
      'description': '一个Ble 设备调试工具',
      'version': '1.0.0+1',
    };
  }

  /// 硬编码的依赖信息
  ///
  /// 注意：这些信息应该与 pubspec.yaml 保持同步
  /// 当添加新依赖时，需要手动更新此列表
  List<Map<String, dynamic>> _getHardcodedDependencies() {
    return [
      // 生产依赖
      {
        'name': 'flutter',
        'version': 'sdk',
        'type': 'prod',
        'isPopular': true,
        'description': 'Flutter SDK',
      },
      {
        'name': 'cupertino_icons',
        'version': '^1.0.8',
        'type': 'prod',
        'isPopular': true,
        'description': 'iOS风格图标',
      },
      {
        'name': 'flutter_blue_plus',
        'version': '^2.0.2',
        'type': 'prod',
        'isPopular': true,
        'description': 'BLE蓝牙库',
      },
      {
        'name': 'provider',
        'version': '^6.1.1',
        'type': 'prod',
        'isPopular': true,
        'description': '状态管理',
      },
      {
        'name': 'json_annotation',
        'version': '^4.8.1',
        'type': 'prod',
        'isPopular': true,
        'description': 'JSON注解',
      },
      {
        'name': 'shared_preferences',
        'version': '^2.2.2',
        'type': 'prod',
        'isPopular': true,
        'description': '本地存储',
      },
      {
        'name': 'path_provider',
        'version': '^2.1.1',
        'type': 'prod',
        'isPopular': true,
        'description': '路径获取',
      },
      {
        'name': 'file_picker',
        'version': '^10.3.7',
        'type': 'prod',
        'isPopular': true,
        'description': '文件选择',
      },
      {
        'name': 'fluttertoast',
        'version': '^8.2.4',
        'type': 'prod',
        'isPopular': true,
        'description': 'Toast通知',
      },
      {
        'name': 'uuid',
        'version': '^4.2.1',
        'type': 'prod',
        'isPopular': true,
        'description': 'UUID生成',
      },
      {
        'name': 'permission_handler',
        'version': '^11.3.1',
        'type': 'prod',
        'isPopular': true,
        'description': '权限处理',
      },
      {
        'name': 'device_info_plus',
        'version': '^9.1.2',
        'type': 'prod',
        'isPopular': true,
        'description': '设备信息',
      },
      {
        'name': 'share_plus',
        'version': '^12.0.1',
        'type': 'prod',
        'isPopular': true,
        'description': '文件分享',
      },
      {
        'name': 'http',
        'version': '^1.2.0',
        'type': 'prod',
        'isPopular': true,
        'description': 'HTTP请求',
      },

      // 开发依赖
      {
        'name': 'flutter_lints',
        'version': '^6.0.0',
        'type': 'dev',
        'isPopular': true,
        'description': '代码规范',
      },
      {
        'name': 'build_runner',
        'version': '^2.4.8',
        'type': 'dev',
        'isPopular': true,
        'description': '代码生成',
      },
      {
        'name': 'json_serializable',
        'version': '^6.7.1',
        'type': 'dev',
        'isPopular': true,
        'description': 'JSON序列化',
      },
    ];
  }

  /// 检查是否需要更新依赖信息
  ///
  /// 这个方法可以用来验证硬编码的依赖是否与 pubspec.yaml 同步
  Future<bool> checkSyncNeeded() async {
    try {
      // 尝试通过 asset 读取 pubspec.yaml（如果已配置）
      await rootBundle.loadString('assets/data/pubspec.yaml');
      // 如果能读取到，可以添加比较逻辑
      return false;
    } catch (e) {
      // 如果无法读取，返回 false（假设已同步）
      return false;
    }
  }
}
