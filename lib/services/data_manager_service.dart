import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_transmission.dart';

/// 数据管理服务
/// 负责管理数据传输记录和设备配置
class DataManagerService {
  static final DataManagerService _instance = DataManagerService._internal();
  factory DataManagerService() => _instance;
  DataManagerService._internal();

  static const String _transmissionsKey = 'ble_transmissions';
  static const String _readConfigsKey = 'ble_read_configs';
  static const String _deviceModelsKey = 'ble_device_models';
  static const String _transceiverConfigKey = 'ble_transceiver_config';

  /// 保存数据传输记录
  Future<bool> saveTransmission(DataTransmission transmission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allTransmissions = await getAllTransmissions();

      // 限制记录数量，避免占用过多空间（最多保留1000条）
      if (allTransmissions.length >= 1000) {
        allTransmissions.removeAt(0);
      }

      allTransmissions.add(transmission);

      final jsonList = allTransmissions.map((t) => t.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_transmissionsKey, jsonString);
      return true;
    } catch (e) {
      print('保存传输记录失败: $e');
      return false;
    }
  }

  /// 获取所有数据传输记录
  Future<List<DataTransmission>> getAllTransmissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_transmissionsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => DataTransmission.fromJson(json)).toList();
    } catch (e) {
      print('获取传输记录失败: $e');
      return [];
    }
  }

  /// 清空数据传输记录
  Future<bool> clearTransmissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_transmissionsKey);
      return true;
    } catch (e) {
      print('清空传输记录失败: $e');
      return false;
    }
  }

  /// 获取指定设备型号的传输记录
  Future<List<DataTransmission>> getTransmissionsByDevice(
    String deviceModel,
  ) async {
    final allTransmissions = await getAllTransmissions();
    // 这里可以根据实际需求过滤，目前返回所有
    return allTransmissions;
  }

  /// 保存读取端点配置
  Future<bool> saveReadEndpointConfig(ReadEndpointConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allConfigs = await getAllReadEndpointConfigs();

      // 更新或添加配置
      final index = allConfigs.indexWhere(
        (c) =>
            c.serviceUuid == config.serviceUuid &&
            c.characteristicUuid == config.characteristicUuid,
      );

      if (index >= 0) {
        allConfigs[index] = config;
      } else {
        allConfigs.add(config);
      }

      final jsonList = allConfigs.map((c) => c.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_readConfigsKey, jsonString);
      return true;
    } catch (e) {
      print('保存读取配置失败: $e');
      return false;
    }
  }

  /// 获取所有读取端点配置
  Future<List<ReadEndpointConfig>> getAllReadEndpointConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_readConfigsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ReadEndpointConfig.fromJson(json)).toList();
    } catch (e) {
      print('获取读取配置失败: $e');
      return [];
    }
  }

  /// 获取指定端点的读取配置
  Future<ReadEndpointConfig?> getReadEndpointConfig(
    String serviceUuid,
    String characteristicUuid,
  ) async {
    final configs = await getAllReadEndpointConfigs();
    try {
      return configs.firstWhere(
        (c) =>
            c.serviceUuid == serviceUuid &&
            c.characteristicUuid == characteristicUuid,
      );
    } catch (e) {
      return null;
    }
  }

  /// 保存设备型号映射
  Future<bool> saveDeviceModel(String deviceId, String model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allModels = await getAllDeviceModels();

      allModels[deviceId] = model;

      final jsonString = json.encode(allModels);
      await prefs.setString(_deviceModelsKey, jsonString);
      return true;
    } catch (e) {
      print('保存设备型号失败: $e');
      return false;
    }
  }

  /// 获取所有设备型号映射
  Future<Map<String, String>> getAllDeviceModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_deviceModelsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('获取设备型号失败: $e');
      return {};
    }
  }

  /// 根据设备ID获取型号
  Future<String?> getDeviceModel(String deviceId) async {
    final models = await getAllDeviceModels();
    return models[deviceId];
  }

  /// 删除设备型号映射
  Future<bool> deleteDeviceModel(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allModels = await getAllDeviceModels();

      allModels.remove(deviceId);

      final jsonString = json.encode(allModels);
      await prefs.setString(_deviceModelsKey, jsonString);
      return true;
    } catch (e) {
      print('删除设备型号失败: $e');
      return false;
    }
  }

  /// 保存收发特征配置
  Future<bool> saveTransceiverConfig(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(config);
      await prefs.setString(_transceiverConfigKey, jsonString);
      return true;
    } catch (e) {
      print('保存收发配置失败: $e');
      return false;
    }
  }

  /// 获取收发特征配置
  Future<Map<String, dynamic>?> getTransceiverConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_transceiverConfigKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      return json.decode(jsonString);
    } catch (e) {
      print('获取收发配置失败: $e');
      return null;
    }
  }

  /// 获取统计数据
  Future<Map<String, dynamic>> getStatistics() async {
    final transmissions = await getAllTransmissions();
    final configs = await getAllReadEndpointConfigs();
    final models = await getAllDeviceModels();

    int sendCount = transmissions
        .where((t) => t.type == TransmissionType.send)
        .length;
    int receiveCount = transmissions
        .where((t) => t.type == TransmissionType.receive)
        .length;
    int notifyCount = transmissions
        .where((t) => t.endpointType == EndpointType.notify)
        .length;
    int readCount = transmissions
        .where((t) => t.endpointType == EndpointType.read)
        .length;

    return {
      'totalTransmissions': transmissions.length,
      'sendCount': sendCount,
      'receiveCount': receiveCount,
      'notifyCount': notifyCount,
      'readCount': readCount,
      'readConfigs': configs.length,
      'deviceModels': models.length,
    };
  }
}
