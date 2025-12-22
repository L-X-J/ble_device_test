import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/ble_command.dart';

/// 指令管理服务
/// 负责快捷指令的存储、查询、导入导出功能
class CommandService {
  static final CommandService _instance = CommandService._internal();
  factory CommandService() => _instance;
  CommandService._internal();

  static const String _storageKey = 'ble_commands';

  /// 获取所有指令
  Future<List<BLECommand>> getAllCommands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => BLECommand.fromJson(json)).toList();
    } catch (e) {
      print('获取指令失败: $e');
      return [];
    }
  }

  /// 根据设备型号获取指令
  Future<List<BLECommand>> getCommandsByModel(String model) async {
    final allCommands = await getAllCommands();
    return allCommands.where((cmd) => cmd.deviceModel == model).toList();
  }

  /// 保存指令
  Future<bool> saveCommand(BLECommand command) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allCommands = await getAllCommands();

      // 检查是否已存在（根据ID）
      final index = allCommands.indexWhere((cmd) => cmd.id == command.id);
      if (index >= 0) {
        allCommands[index] = command;
      } else {
        allCommands.add(command);
      }

      // 保存到本地
      final jsonList = allCommands.map((cmd) => cmd.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_storageKey, jsonString);
      return true;
    } catch (e) {
      print('保存指令失败: $e');
      return false;
    }
  }

  /// 删除指令
  Future<bool> deleteCommand(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allCommands = await getAllCommands();

      final filtered = allCommands.where((cmd) => cmd.id != id).toList();

      final jsonList = filtered.map((cmd) => cmd.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_storageKey, jsonString);
      return true;
    } catch (e) {
      print('删除指令失败: $e');
      return false;
    }
  }

  /// 批量导入指令
  Future<int> importCommands(List<BLECommand> commands) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allCommands = await getAllCommands();

      int imported = 0;
      for (final cmd in commands) {
        // 检查是否已存在（根据ID和内容）
        final exists = allCommands.any(
          (c) =>
              c.id == cmd.id ||
              (c.deviceModel == cmd.deviceModel &&
                  c.name == cmd.name &&
                  c.hexContent == cmd.hexContent),
        );

        if (!exists) {
          allCommands.add(cmd);
          imported++;
        }
      }

      // 保存到本地
      final jsonList = allCommands.map((cmd) => cmd.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_storageKey, jsonString);

      return imported;
    } catch (e) {
      print('导入指令失败: $e');
      return 0;
    }
  }

  /// 导出为JSON文件（包含设备型号、配置信息、指令列表）
  /// 返回Map包含fileName, filePath, directory信息，失败返回null
  Future<Map<String, String>?> exportCommands() async {
    try {
      final allCommands = await getAllCommands();

      if (allCommands.isEmpty) {
        return null;
      }

      // 获取配置信息
      final prefs = await SharedPreferences.getInstance();

      // 获取收发配置（兼容两种键名）
      String? transceiverConfigJson =
          prefs.getString('ble_transceiver_config') ??
          prefs.getString('transceiver_config');
      final transceiverConfigData = transceiverConfigJson != null
          ? json.decode(transceiverConfigJson)
          : {};

      // 获取读取端点配置
      final readConfigsJson = prefs.getString('ble_read_configs');
      final readConfigsData = readConfigsJson != null
          ? json.decode(readConfigsJson)
          : [];

      // 获取设备型号映射
      final deviceModelsJson = prefs.getString('ble_device_models');
      final deviceModelsData = deviceModelsJson != null
          ? json.decode(deviceModelsJson)
          : {};

      // 获取所有唯一的设备型号（从指令中）
      final models = allCommands.map((cmd) => cmd.deviceModel).toSet().toList();

      // 创建导出数据结构
      final exportData = {
        'exportTime': DateTime.now().toIso8601String(),
        'version': '2.0', // 版本号，用于导入时识别格式
        'deviceModels': models,
        'transceiverConfig': transceiverConfigData,
        'readConfigs': readConfigsData,
        'deviceModelMappings': deviceModelsData,
        'commands': allCommands.map((cmd) => cmd.toJson()).toList(),
      };

      // 创建JSON数据
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // 获取文档目录
      final directory = (await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      ))?.firstOrNull;
      if (directory == null) {
        return null;
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ble_export_$timestamp.json';
      final filePath = '${directory.path}/$fileName';

      // 写入文件
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // 返回结构化信息
      return {
        'fileName': fileName,
        'filePath': filePath,
        'directory': directory.path,
      };
    } catch (e) {
      print('导出指令失败: $e');
      return null;
    }
  }

  /// 从JSON文件导入
  Future<int> importFromFile() async {
    try {
      // 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return 0;
      }

      final file = result.files.single;
      final filePath = file.path;

      if (filePath == null) {
        return 0;
      }

      // 读取文件内容
      final fileContent = await File(filePath).readAsString();
      final dynamic jsonData = json.decode(fileContent);

      List<BLECommand> commands = [];

      // 检查是新格式还是旧格式
      if (jsonData is Map<String, dynamic>) {
        // 新格式：包含设备型号、配置信息、指令列表
        if (jsonData.containsKey('commands')) {
          final commandList = jsonData['commands'] as List<dynamic>;
          commands = commandList
              .map((json) => BLECommand.fromJson(json))
              .toList();

          // 处理配置信息（兼容新旧格式）
          final prefs = await SharedPreferences.getInstance();

          // 处理收发配置（新格式使用 transceiverConfig，旧格式使用 config）
          if (jsonData.containsKey('transceiverConfig')) {
            final configData = jsonData['transceiverConfig'];
            if (configData != null && configData is Map<String, dynamic>) {
              await prefs.setString(
                'ble_transceiver_config',
                json.encode(configData),
              );
            }
          } else if (jsonData.containsKey('config')) {
            // 兼容旧格式
            final configData = jsonData['config'];
            if (configData != null && configData is Map<String, dynamic>) {
              await prefs.setString(
                'ble_transceiver_config',
                json.encode(configData),
              );
            }
          }

          // 处理读取端点配置（新格式）
          if (jsonData.containsKey('readConfigs')) {
            final readConfigsData = jsonData['readConfigs'];
            if (readConfigsData != null && readConfigsData is List<dynamic>) {
              await prefs.setString(
                'ble_read_configs',
                json.encode(readConfigsData),
              );
            }
          }

          // 处理设备型号映射（新格式）
          if (jsonData.containsKey('deviceModelMappings')) {
            final deviceModelsData = jsonData['deviceModelMappings'];
            if (deviceModelsData != null &&
                deviceModelsData is Map<String, dynamic>) {
              await prefs.setString(
                'ble_device_models',
                json.encode(deviceModelsData),
              );
            }
          }
        } else {
          // 可能是只有指令列表的格式
          return 0;
        }
      } else if (jsonData is List<dynamic>) {
        // 旧格式：直接是指令列表
        commands = jsonData.map((json) => BLECommand.fromJson(json)).toList();
      }

      // 导入
      final imported = await importCommands(commands);

      // 构建提示信息
      String message = '成功导入 $imported 条指令';
      if (jsonData is Map<String, dynamic>) {
        final configImported =
            jsonData.containsKey('transceiverConfig') ||
            jsonData.containsKey('config');
        final readConfigsImported = jsonData.containsKey('readConfigs');
        final deviceModelsImported = jsonData.containsKey(
          'deviceModelMappings',
        );

        if (configImported || readConfigsImported || deviceModelsImported) {
          message += '，并更新了相关配置';
        }
      }

      Fluttertoast.showToast(msg: message);
      return imported;
    } catch (e) {
      print('从文件导入失败: $e');
      Fluttertoast.showToast(msg: '导入失败: $e');
      return 0;
    }
  }

  /// 获取所有唯一的设备型号
  Future<List<String>> getAllModels() async {
    final allCommands = await getAllCommands();
    final models = allCommands.map((cmd) => cmd.deviceModel).toSet().toList();
    models.sort();
    return models;
  }

  /// 生成新的指令ID
  String generateNewId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 创建示例指令
  Future<void> createSampleCommands() async {
    final sampleCommands = [
      BLECommand(
        id: generateNewId(),
        deviceModel: 'SampleDevice',
        name: '查询状态',
        hexContent: 'AA0102',
        remark: '查询设备当前状态',
        createdAt: DateTime.now(),
      ),
      BLECommand(
        id: generateNewId(),
        deviceModel: 'SampleDevice',
        name: '开启模式',
        hexContent: 'AA0301',
        remark: '开启设备工作模式',
        createdAt: DateTime.now(),
      ),
      BLECommand(
        id: generateNewId(),
        deviceModel: 'TestDevice',
        name: '重启设备',
        hexContent: 'FFAA55',
        remark: '重启设备',
        createdAt: DateTime.now(),
      ),
    ];

    for (final cmd in sampleCommands) {
      await saveCommand(cmd);
    }
  }
}
