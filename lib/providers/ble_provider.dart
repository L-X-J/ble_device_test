import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ble_service.dart';
import '../services/data_manager_service.dart';
import '../services/command_service.dart';
import '../models/data_transmission.dart';
import '../models/transceiver_config.dart';
import '../models/ble_command.dart';
import '../models/ble_device.dart';

/// BLE Provider
/// 管理BLE设备连接、数据传输和配置
class BLEProvider with ChangeNotifier {
  final BLEService _bleService = BLEService();
  final DataManagerService _dataManager = DataManagerService();
  final CommandService _commandService = CommandService();

  // 状态变量
  bool _isLoading = false;
  bool _isScanning = false;
  String? _errorMessage;
  final String _debugLog = '';
  BluetoothDevice? _currentDevice;
  List<BluetoothService> _services = [];
  BLEDevice? _currentBLEDevice;
  final List<DataTransmission> _transmissions = [];
  List<BLECommand> _commands = [];
  List<ReadEndpointConfig> _readConfigs = [];
  TransceiverConfig _transceiverConfig = TransceiverConfig();
  List<BluetoothDevice> _scannedDevices = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;
  String get debugLog => _debugLog;
  bool get isConnected => _currentDevice != null;
  BluetoothDevice? get currentDevice => _currentDevice;
  List<BluetoothService> get services => _services;
  BLEDevice? get currentBLEDevice => _currentBLEDevice;
  List<DataTransmission> get transmissions => _transmissions;
  List<BLECommand> get commands => _commands;
  TransceiverConfig get transceiverConfig => _transceiverConfig;
  bool get hasConfig => _transceiverConfig.isValid;
  List<BluetoothDevice> get scannedDevices => _scannedDevices;

  BLEProvider() {
    _init();
  }

  Future<void> _init() async {
    // 加载收发配置
    final configData = await _dataManager.getTransceiverConfig();
    if (configData != null) {
      _transceiverConfig = TransceiverConfig.fromJson(configData);
    }

    // 加载快捷指令
    await loadCommands();

    // 监听数据流
    _bleService.dataStream.listen((transmission) {
      _transmissions.add(transmission);
      // 限制记录数量
      if (_transmissions.length > 1000) {
        _transmissions.removeAt(0);
      }
      // 保存到数据库
      _dataManager.saveTransmission(transmission);
      notifyListeners();
    });

    // 监听连接状态变化，处理设备断开连接
    _bleService.connectionStateStream.listen((isConnected) {
      if (!isConnected && _currentDevice != null) {
        // 设备断开连接
        _handleDeviceDisconnected();
      }
    });

    notifyListeners();
  }

  Future<void> reloadPersistedConfigs() async {
    try {
      final configData = await _dataManager.getTransceiverConfig();
      if (configData != null) {
        _transceiverConfig = TransceiverConfig.fromJson(configData);
      }

      _readConfigs = await _dataManager.getAllReadEndpointConfigs();

      if (_currentDevice != null && _currentBLEDevice != null) {
        final model = await _dataManager.getDeviceModel(
          _currentDevice!.remoteId.str,
        );
        _currentBLEDevice!.model = model;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = '刷新配置失败: $e';
      notifyListeners();
    }
  }

  /// 处理设备断开连接
  void _handleDeviceDisconnected() {
    _errorMessage = '设备已断开连接';
    _currentDevice = null;
    _currentBLEDevice = null;
    _services = [];
    notifyListeners();
  }

  /// 扫描设备
  Future<void> scanDevices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bleService.startScan();
    } catch (e) {
      _errorMessage = '扫描失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 连接设备
  Future<void> connectDevice(BluetoothDevice device) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bleService.connectToDevice(device);
      _currentDevice = device;

      // 获取服务
      _services = await _bleService.discoverServices();

      // 加载设备型号
      final model = await _dataManager.getDeviceModel(device.remoteId.str);

      // 创建BLE设备模型
      _currentBLEDevice = BLEDevice(
        deviceId: device.remoteId.str,
        name: device.platformName,
        model: model,
        rssi: 0,
        advertisementData: {},
        serviceUuids: _services.map((s) => s.uuid.toString()).toList(),
        isConnected: true,
        lastConnected: DateTime.now(),
      );

      // 加载读取配置
      _readConfigs = await _dataManager.getAllReadEndpointConfigs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 断开连接
  Future<void> disconnectDevice() async {
    try {
      await _bleService.disconnectDevice();
      _currentDevice = null;
      _currentBLEDevice = null;
      _services = [];
      notifyListeners();
    } catch (e) {
      _errorMessage = '断开连接失败: $e';
      notifyListeners();
    }
  }

  /// 发送数据
  Future<void> sendData({
    required String serviceUuid,
    required String characteristicUuid,
    required String hexData,
  }) async {
    try {
      await _bleService.writeData(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        hexData: hexData,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '发送失败: $e';
      notifyListeners();
    }
  }

  /// 读取数据
  Future<String> readData({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    try {
      final data = await _bleService.readData(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
      _errorMessage = null;
      return data;
    } catch (e) {
      _errorMessage = '读取失败: $e';
      notifyListeners();
      return '';
    }
  }

  /// 启用Notify监听
  Future<void> enableNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    try {
      await _bleService.enableNotify(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '启用Notify失败: $e';
      notifyListeners();
    }
  }

  /// 启用定时读取
  Future<void> enablePeriodicRead({
    required String serviceUuid,
    required String characteristicUuid,
    required int intervalSeconds,
  }) async {
    try {
      _bleService.enablePeriodicRead(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        intervalSeconds: intervalSeconds,
      );

      // 更新配置
      final config = ReadEndpointConfig(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        enablePeriodicRead: true,
        readIntervalSeconds: intervalSeconds,
      );
      await _dataManager.saveReadEndpointConfig(config);
      _readConfigs = await _dataManager.getAllReadEndpointConfigs();
    } catch (e) {
      _errorMessage = '启用定时读取失败: $e';
      notifyListeners();
    }
  }

  /// 停用定时读取
  Future<void> disablePeriodicRead({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    try {
      _bleService.disablePeriodicRead(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );

      // 更新配置
      final config = ReadEndpointConfig(
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        enablePeriodicRead: false,
        readIntervalSeconds: 3,
      );
      await _dataManager.saveReadEndpointConfig(config);
      _readConfigs = await _dataManager.getAllReadEndpointConfigs();
    } catch (e) {
      _errorMessage = '停用定时读取失败: $e';
      notifyListeners();
    }
  }

  /// 获取指定服务的特征列表
  List<BluetoothCharacteristic> getCharacteristicsForService(
    BluetoothService service,
  ) {
    return service.characteristics;
  }

  /// 获取读取配置
  ReadEndpointConfig? getReadConfig(
    String serviceUuid,
    String characteristicUuid,
  ) {
    try {
      return _readConfigs.firstWhere(
        (c) =>
            c.serviceUuid == serviceUuid &&
            c.characteristicUuid == characteristicUuid,
      );
    } catch (e) {
      return null;
    }
  }

  /// 设置发送配置
  void setSendConfig(String serviceUuid, String characteristicUuid) {
    _transceiverConfig.sendServiceUuid = serviceUuid;
    _transceiverConfig.sendCharacteristicUuid = characteristicUuid;
    notifyListeners();
  }

  /// 设置接收配置
  void setReceiveConfig(String serviceUuid, String characteristicUuid) {
    _transceiverConfig.receiveServiceUuid = serviceUuid;
    _transceiverConfig.receiveCharacteristicUuid = characteristicUuid;
    notifyListeners();
  }

  /// 设置通知配置
  void setNotifyConfig(String serviceUuid, String characteristicUuid) {
    _transceiverConfig.notifyServiceUuid = serviceUuid;
    _transceiverConfig.notifyCharacteristicUuid = characteristicUuid;
    notifyListeners();
  }

  /// 设置收发配置
  void setTransceiverConfig(TransceiverConfig config) {
    _transceiverConfig = config;
    notifyListeners();
  }

  /// 清除所有配置
  void clearTransceiverConfig() {
    _transceiverConfig = TransceiverConfig();
    notifyListeners();
  }

  /// 保存收发配置
  Future<void> saveTransceiverConfig() async {
    await _dataManager.saveTransceiverConfig(_transceiverConfig.toJson());
    notifyListeners();
  }

  /// 使用配置发送数据
  Future<void> sendWithConfig(String hexData) async {
    if (!_transceiverConfig.hasSendConfig) {
      _errorMessage = '未配置发送特征';
      notifyListeners();
      return;
    }

    try {
      await _bleService.writeData(
        serviceUuid: _transceiverConfig.sendServiceUuid!,
        characteristicUuid: _transceiverConfig.sendCharacteristicUuid!,
        hexData: hexData,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '发送失败: $e';
      notifyListeners();
      rethrow; // 重新抛出异常，让UI层能够捕获并显示提示
    }
  }

  /// 使用配置读取数据
  Future<void> receiveWithConfig() async {
    if (!_transceiverConfig.hasReceiveConfig) {
      _errorMessage = '未配置接收特征';
      notifyListeners();
      return;
    }

    try {
      await _bleService.readData(
        serviceUuid: _transceiverConfig.receiveServiceUuid!,
        characteristicUuid: _transceiverConfig.receiveCharacteristicUuid!,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '接收失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 使用配置启用Notify监听
  Future<void> enableNotifyWithConfig() async {
    if (!_transceiverConfig.hasNotifyConfig) {
      _errorMessage = '未配置通知特征';
      notifyListeners();
      return;
    }

    try {
      await _bleService.enableNotify(
        serviceUuid: _transceiverConfig.notifyServiceUuid!,
        characteristicUuid: _transceiverConfig.notifyCharacteristicUuid!,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '启用通知失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 使用配置停用Notify监听
  Future<void> disableNotifyWithConfig() async {
    if (!_transceiverConfig.hasNotifyConfig) {
      _errorMessage = '未配置通知特征';
      notifyListeners();
      return;
    }

    try {
      await _bleService.disableNotify(
        serviceUuid: _transceiverConfig.notifyServiceUuid!,
        characteristicUuid: _transceiverConfig.notifyCharacteristicUuid!,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '停用通知失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 使用配置启用定时读取
  Future<void> enablePeriodicReadWithConfig(int intervalSeconds) async {
    if (!_transceiverConfig.hasReceiveConfig) {
      _errorMessage = '未配置接收特征';
      notifyListeners();
      return;
    }

    try {
      _bleService.enablePeriodicRead(
        serviceUuid: _transceiverConfig.receiveServiceUuid!,
        characteristicUuid: _transceiverConfig.receiveCharacteristicUuid!,
        intervalSeconds: intervalSeconds,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '启用定时读取失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 使用配置停用定时读取
  Future<void> disablePeriodicReadWithConfig() async {
    if (!_transceiverConfig.hasReceiveConfig) {
      _errorMessage = '未配置接收特征';
      notifyListeners();
      return;
    }

    try {
      _bleService.disablePeriodicRead(
        serviceUuid: _transceiverConfig.receiveServiceUuid!,
        characteristicUuid: _transceiverConfig.receiveCharacteristicUuid!,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '停用定时读取失败: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// 检查配置是否完整用于自动操作
  bool get canAutoOperate {
    return _transceiverConfig.hasSendConfig ||
        _transceiverConfig.hasReceiveConfig ||
        _transceiverConfig.hasNotifyConfig;
  }

  /// 加载快捷指令
  Future<void> loadCommands() async {
    _commands = await _commandService.getAllCommands();
    notifyListeners();
  }

  /// 保存快捷指令
  Future<bool> saveCommand(BLECommand command) async {
    final result = await _commandService.saveCommand(command);
    if (result) {
      await loadCommands();
    }
    return result;
  }

  /// 删除快捷指令
  Future<bool> deleteCommand(String id) async {
    final result = await _commandService.deleteCommand(id);
    if (result) {
      await loadCommands();
    }
    return result;
  }

  /// 获取统计数据
  Future<Map<String, dynamic>> getStatistics() async {
    return await _dataManager.getStatistics();
  }

  /// 清除错误
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 清空传输记录
  void clearTransmissions() {
    _transmissions.clear();
    notifyListeners();
  }

  Timer? _scanUpdateTimer;

  /// 开始扫描
  Future<void> startScan() async {
    _isScanning = true;
    _scannedDevices.clear();
    notifyListeners();

    try {
      // 监听扫描状态变化
      _bleService.scanStateStream.listen((isScanning) {
        _isScanning = isScanning;
        if (!isScanning) {
          // 停止定时更新
          _scanUpdateTimer?.cancel();
          _scanUpdateTimer = null;
        }
        notifyListeners();
      });

      // 启动定时更新，每500ms检查一次新设备
      _scanUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) {
        if (_isScanning) {
          _updateScannedDevices();
        }
      });

      await _bleService.startScan();

      // 扫描完成后最后一次更新
      _scanUpdateTimer?.cancel();
      _scanUpdateTimer = null;
      _updateScannedDevices();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '扫描失败: $e';
      _isScanning = false;
      _scanUpdateTimer?.cancel();
      _scanUpdateTimer = null;
      notifyListeners();
    }
  }

  /// 更新扫描设备列表（实现实时刷新）
  void _updateScannedDevices() {
    final newDevices = _bleService.scannedDevices;

    // 检查是否有新设备
    bool hasNewDevices = false;
    for (var device in newDevices) {
      if (!_scannedDevices.any((d) => d.remoteId == device.remoteId)) {
        hasNewDevices = true;
        break;
      }
    }

    if (hasNewDevices || newDevices.length != _scannedDevices.length) {
      _scannedDevices = List.from(newDevices);
      notifyListeners();
    }
  }

  /// 获取设备的广播数据
  Map<String, dynamic>? getDeviceAdvertisementData(String deviceId) {
    return _bleService.advertisementData[deviceId];
  }

  /// 停止扫描
  Future<void> stopScan() async {
    try {
      await _bleService.stopScan();
      _isScanning = false;
      _scanUpdateTimer?.cancel();
      _scanUpdateTimer = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = '停止扫描失败: $e';
      _scanUpdateTimer?.cancel();
      _scanUpdateTimer = null;
      notifyListeners();
    }
  }

  /// 连接设备（用于设备管理屏幕）
  Future<void> connectToDevice(BluetoothDevice device) async {
    await connectDevice(device);
  }

  /// 设置设备型号
  Future<void> setDeviceModel(String model) async {
    if (_currentDevice != null) {
      await _dataManager.saveDeviceModel(_currentDevice!.remoteId.str, model);
      if (_currentBLEDevice != null) {
        _currentBLEDevice!.model = model;
      }
      notifyListeners();
    }
  }

  /// 导出指令
  /// 返回Map包含fileName, filePath, directory信息，失败返回null
  Future<Map<String, String>?> exportCommands() async {
    return await _commandService.exportCommands();
  }

  /// 获取当前的收发配置信息（用于导出）
  Future<Map<String, dynamic>?> getCurrentConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 兼容两种键名
      String? configJson =
          prefs.getString('ble_transceiver_config') ??
          prefs.getString('transceiver_config');
      if (configJson != null) {
        return json.decode(configJson);
      }
      return null;
    } catch (e) {
      debugPrint('获取配置失败: $e');
      return null;
    }
  }

  /// 从文件导入指令
  Future<int> importCommandsFromFile() async {
    final count = await _commandService.importFromFile();
    await reloadPersistedConfigs();
    await loadCommands();
    return count;
  }

  @override
  void dispose() {
    _scanUpdateTimer?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}
