import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/data_transmission.dart';
import '../utils/hex_utils.dart';

/// BLE服务类
/// 负责管理BLE设备的扫描、连接、数据读写和监听功能
class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal() {
    // 设置日志级别
    FlutterBluePlus.setLogLevel(LogLevel.verbose);

    // 监听蓝牙状态变化
    FlutterBluePlus.adapterState.listen((state) {
      debugPrint('蓝牙状态变化: $state');
    });
  }

  // 当前连接的设备
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  // 数据流控制器
  final StreamController<DataTransmission> _dataStreamController =
      StreamController<DataTransmission>.broadcast();
  Stream<DataTransmission> get dataStream => _dataStreamController.stream;

  // 扫描状态控制器
  final StreamController<bool> _scanStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get scanStateStream => _scanStateController.stream;

  // 连接状态控制器
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  // 扫描到的设备列表
  final List<BluetoothDevice> _scannedDevices = [];
  // 存储设备的广播数据
  final Map<String, Map<String, dynamic>> _advertisementData = {};

  List<BluetoothDevice> get scannedDevices => List.from(_scannedDevices);
  Map<String, Map<String, dynamic>> get advertisementData =>
      Map.from(_advertisementData);

  // 定时读取器映射
  final Map<String, Timer> _periodicReaders = {};

  /// 检查和请求BLE权限
  Future<bool> checkPermissions() async {
    try {
      // 检查蓝牙状态
      debugPrint('检查蓝牙状态...');
      final state = await FlutterBluePlus.adapterState.first;
      debugPrint('当前蓝牙状态: $state');

      if (state != BluetoothAdapterState.on) {
        debugPrint('蓝牙未开启: $state');

        // Web 平台不需要开启蓝牙的操作，由浏览器管理
        if (kIsWeb) {
          return false;
        }

        // 尝试在Android上开启蓝牙
        if (Platform.isAndroid && state == BluetoothAdapterState.off) {
          try {
            debugPrint('尝试开启蓝牙...');
            await FlutterBluePlus.turnOn();
            // 等待蓝牙开启
            await Future.delayed(const Duration(seconds: 2));
            final newState = await FlutterBluePlus.adapterState.first;
            debugPrint('蓝牙状态更新: $newState');
            if (newState != BluetoothAdapterState.on) {
              return false;
            }
          } catch (e) {
            debugPrint('无法自动开启蓝牙: $e');
            return false;
          }
        } else {
          return false;
        }
      }

      // Web 平台不需要特定的权限检查
      if (kIsWeb) {
        return true;
      }

      // Android特定权限检查
      if (Platform.isAndroid) {
        debugPrint('Android权限检查...');
        final deviceInfo = DeviceInfoPlugin();
        final androidVersion = await deviceInfo.androidInfo;
        debugPrint('Android版本: ${androidVersion.version.sdkInt}');

        if (androidVersion.version.sdkInt >= 33) {
          // Android 13+ 需要BLUETOOTH_SCAN和BLUETOOTH_CONNECT
          debugPrint('Android 13+，请求BLUETOOTH_SCAN和BLUETOOTH_CONNECT权限...');
          final scanPermission = await Permission.bluetoothScan.request();
          final connectPermission = await Permission.bluetoothConnect.request();
          final locationPermission = await Permission.location
              .request(); // 仍然需要位置权限

          debugPrint(
            'SCAN权限: $scanPermission, CONNECT权限: $connectPermission, LOCATION权限: $locationPermission',
          );

          if (scanPermission != PermissionStatus.granted ||
              connectPermission != PermissionStatus.granted ||
              locationPermission != PermissionStatus.granted) {
            debugPrint('Android 13+ 权限被拒绝');
            return false;
          }
        } else {
          // Android 12及以下
          debugPrint('Android 12及以下，请求位置权限...');
          final locationPermission = await Permission.location.request();

          debugPrint('位置权限: $locationPermission');

          if (locationPermission != PermissionStatus.granted) {
            debugPrint('位置权限被拒绝');
            return false;
          }
        }
      }

      // iOS特定权限检查
      if (Platform.isIOS) {
        debugPrint('iOS权限检查...');
        final bluetoothPermission = await Permission.bluetooth.request();
        final locationPermission = await Permission.locationWhenInUse.request();

        debugPrint('蓝牙权限: $bluetoothPermission, 位置权限: $locationPermission');

        if (bluetoothPermission != PermissionStatus.granted) {
          debugPrint('iOS蓝牙权限被拒绝');
          return false;
        }

        if (locationPermission != PermissionStatus.granted) {
          debugPrint('iOS位置权限被拒绝');
          return false;
        }
      }

      debugPrint('所有权限检查通过');
      return true;
    } catch (e) {
      debugPrint('权限检查失败: $e');
      return false;
    }
  }

  /// 开始扫描BLE设备
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      debugPrint('开始扫描流程...');

      // 检查权限
      debugPrint('检查权限...');
      if (!await checkPermissions()) {
        debugPrint('权限检查失败');
        throw Exception('蓝牙权限未授予或蓝牙未开启');
      }
      debugPrint('权限检查通过');

      // 停止之前的扫描
      await FlutterBluePlus.stopScan();
      debugPrint('停止之前的扫描');

      // 清空之前的扫描结果
      _scannedDevices.clear();
      debugPrint('清空扫描结果');

      // 先设置监听器，再开始扫描
      final scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          debugPrint('收到扫描结果: ${results.length} 个设备');

          bool hasNewDevice = false;
          for (ScanResult result in results) {
            final deviceName = result.device.platformName;
            final deviceId = result.device.remoteId;
            final rssi = result.rssi;

            debugPrint('发现设备: $deviceName ($deviceId), RSSI: $rssi');

            // 避免重复添加
            if (!_scannedDevices.any(
              (d) => d.remoteId == result.device.remoteId,
            )) {
              _scannedDevices.add(result.device);
              hasNewDevice = true;
              debugPrint('添加新设备: $deviceName');
            } else {
              // 更新已存在设备的信号强度等信息
              final existingIndex = _scannedDevices.indexWhere(
                (d) => d.remoteId == result.device.remoteId,
              );
              if (existingIndex != -1) {
                // 更新设备信息（如果需要）
                debugPrint('更新设备信息: $deviceName');
              }
            }

            // 收集广播数据
            try {
              final advData = <String, dynamic>{
                'rssi': rssi,
                'deviceName': deviceName,
                'serviceUuids': result.advertisementData.serviceUuids,
                'manufacturerData': result.advertisementData.manufacturerData,
                'msd': result.advertisementData.msd,
                'serviceData': result.advertisementData.serviceData,
                'txPowerLevel': result.advertisementData.txPowerLevel,
                'connectable': result.advertisementData.connectable,
              };
              _advertisementData[deviceId.str] = advData;
              debugPrint('广播数据已收集: ${advData.length} 项');
            } catch (e) {
              debugPrint('收集广播数据失败: $e');
            }
          }

          // 如果有新设备，立即通知UI更新
          if (hasNewDevice) {
            _scanStateController.add(true);
          }
        },
        onError: (e) {
          debugPrint('扫描监听错误: $e');
        },
      );

      // 取消订阅的包装
      FlutterBluePlus.cancelWhenScanComplete(scanSubscription);

      // 开始扫描，使用低延迟模式
      debugPrint('开始FlutterBluePlus扫描...');

      // Web平台需要配置webOptionalServices以避免SecurityError
      if (kIsWeb) {
        // 注意：请根据实际设备的服务UUID修改以下列表
        // 常见的BLE服务UUID示例：
        // - 0000180a-0000-1000-8000-00805f9b34fb (设备信息服务 - Device Information)
        // - 0000180f-0000-1000-8000-00805f9b34fb (电池服务 - Battery Service)
        // - 00001812-0000-1000-8000-00805f9b34fb (扫描参数服务 - Scan Parameters)
        // - 00001814-0000-1000-8000-00805f9b34fb (重新连接服务 - Reconnection Configuration)
        // - 00001816-0000-1000-8000-00805f9b34fb (链路丢失服务 - Link Loss)
        // - 00001800-0000-1000-8000-00805f9b34fb (通用访问服务 - GAP)
        // - 00001801-0000-1000-8000-00805f9b34fb (通用属性服务 - GATT)

        // 示例：使用常见服务UUID，实际使用时请替换为设备实际的服务UUID
        // 如果设备使用自定义服务，请添加对应的自定义UUID
        final webOptionalServices = [
          Guid('0000180a-0000-1000-8000-00805f9b34fb'), // 设备信息服务
          Guid('0000180f-0000-1000-8000-00805f9b34fb'), // 电池服务
          Guid('00001800-0000-1000-8000-00805f9b34fb'), // 通用访问服务
          Guid('00001801-0000-1000-8000-00805f9b34fb'), // 通用属性服务
          // 在此添加设备实际使用的服务UUID...
          // 例如：Guid('0000fff0-0000-1000-8000-00805f9b34fb'), // 自定义服务
        ];

        debugPrint(
          'Web平台开始扫描，配置的optionalServices: ${webOptionalServices.map((s) => s.toString()).join(", ")}',
        );

        await FlutterBluePlus.startScan(
          timeout: timeout,
          webOptionalServices: webOptionalServices,
        );
      } else {
        await FlutterBluePlus.startScan(
          timeout: timeout,
          androidScanMode: AndroidScanMode.lowLatency,
        );
      }

      _scanStateController.add(true);
      debugPrint('扫描已启动，等待 $timeout');

      // 等待扫描完成
      await Future.delayed(timeout);

      // 停止扫描
      await FlutterBluePlus.stopScan();
      _scanStateController.add(false);

      debugPrint('扫描完成，共发现 ${_scannedDevices.length} 个设备');
    } catch (e) {
      _scanStateController.add(false);
      debugPrint('扫描错误: $e');
      throw Exception('扫描失败: $e');
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanStateController.add(false);
    } catch (e) {
      throw Exception('停止扫描失败: $e');
    }
  }

  /// 连接到设备
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // 停止扫描
      await stopScan();

      // 如果已经连接了其他设备，先断开
      if (_connectedDevice != null && _connectedDevice != device) {
        await disconnectDevice();
      }

      // 取消之前的监听
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      // 连接设备（新版本API）
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 10),
        mtu: null,
      );
      _connectedDevice = device;
      _connectionStateController.add(true);

      // 监听连接状态变化
      _connectionSubscription = device.connectionState.listen((state) {
        debugPrint('连接状态变化: $state');
        if (state == BluetoothConnectionState.disconnected) {
          _connectionStateController.add(false);
          _connectedDevice = null;
          // 清理定时读取器
          _clearAllPeriodicReaders();
          // 清理Notify订阅
          _clearAllNotifySubscriptions();
          // 既然断开了，也可以取消订阅，但为了支持自动重连（如果开启的话），有时保留也可以。
          // 但这里我们没有开启自动重连，所以可以考虑不取消，或者在disconnectDevice中取消。
          // 这里我们不立即取消订阅，因为FlutterBluePlus可能会发出多次状态更新。
          // 但考虑到我们已经将 _connectedDevice 置空，后续操作需要重新连接。
        } else if (state == BluetoothConnectionState.connected) {
          _connectionStateController.add(true);
          _connectedDevice = device; // 确保重新连接时对象一致
        }
      });
    } catch (e) {
      _connectionStateController.add(false);
      throw Exception('连接设备失败: $e');
    }
  }

  /// 断开连接
  Future<void> disconnectDevice() async {
    try {
      // 取消监听
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _connectionStateController.add(false);
        // 清理定时读取器
        _clearAllPeriodicReaders();
        // 清理Notify订阅
        _clearAllNotifySubscriptions();
      }
    } catch (e) {
      throw Exception('断开连接失败: $e');
    }
  }

  /// 发现服务和特征
  Future<List<BluetoothService>> discoverServices() async {
    if (_connectedDevice == null) {
      throw Exception('未连接设备');
    }

    try {
      debugPrint('开始发现服务，设备: ${_connectedDevice!.platformName}');

      // Web平台需要确保在连接时已经配置了optionalServices
      // 如果在扫描时已经通过webOptionalServices配置了服务UUID，
      // 这里应该能够正常发现服务
      if (kIsWeb) {
        debugPrint('Web平台开始发现服务...');
        try {
          final services = await _connectedDevice!.discoverServices();
          debugPrint('Web平台发现服务数量: ${services.length}');
          for (var service in services) {
            debugPrint('服务UUID: ${service.uuid}');
            // 打印服务特征
            for (var characteristic in service.characteristics) {
              debugPrint('  特征UUID: ${characteristic.uuid}');
            }
          }
          return services;
        } catch (discoverError) {
          debugPrint('Web平台发现服务错误: $discoverError');

          // 如果是NotFoundError，提供更详细的帮助信息
          if (discoverError.toString().contains('NotFoundError')) {
            throw Exception(
              '发现服务失败: 设备没有提供任何服务\n'
              '可能原因:\n'
              '1. 设备未正确连接或未完成连接初始化\n'
              '2. 设备实际没有提供标准BLE服务\n'
              '3. 设备使用了自定义服务UUID，需要在扫描时通过webOptionalServices配置\n'
              '4. 设备可能需要特定的连接参数或配对流程\n\n'
              '建议:\n'
              '- 检查设备是否支持BLE功能\n'
              '- 尝试重新连接设备\n'
              '- 查看设备文档确认实际使用的服务UUID\n'
              '- 在startScan的webOptionalServices中添加设备实际的服务UUID',
            );
          }
          rethrow;
        }
      } else {
        // 移动端处理
        final services = await _connectedDevice!.discoverServices();
        debugPrint('移动端发现服务数量: ${services.length}');
        for (var service in services) {
          debugPrint('服务UUID: ${service.uuid}');
        }
        return services;
      }
    } catch (e) {
      debugPrint('发现服务错误: $e');
      if (kIsWeb && e.toString().contains('SecurityError')) {
        throw Exception(
          '发现服务失败: $e\n提示: 请确保在扫描时正确配置了webOptionalServices参数，包含设备实际使用的服务UUID',
        );
      }
      throw Exception('发现服务失败: $e');
    }
  }

  /// 写入数据到特征
  Future<void> writeData({
    required String serviceUuid,
    required String characteristicUuid,
    required String hexData,
  }) async {
    if (_connectedDevice == null) {
      throw Exception('未连接设备');
    }

    try {
      // 转换HEX数据为字节
      final bytes = HexUtils.hexToBytes(hexData);
      if (bytes.isEmpty) {
        throw Exception('无效的HEX数据');
      }

      // 查找服务和特征
      final services = await discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase(),
        orElse: () => throw Exception('未找到指定服务: $serviceUuid'),
      );

      final characteristic = service.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase(),
        orElse: () => throw Exception('未找到指定特征: $characteristicUuid'),
      );

      // 检查特征是否支持写入
      if (!characteristic.properties.write &&
          !characteristic.properties.writeWithoutResponse) {
        throw Exception(
          '特征不支持写入操作 (UUID: ${characteristic.uuid.toString()})。\n'
          '当前特征属性: 可读=${characteristic.properties.read}, '
          '可写=${characteristic.properties.write || characteristic.properties.writeWithoutResponse}, '
          '通知=${characteristic.properties.notify || characteristic.properties.indicate}',
        );
      }

      // 写入数据
      await characteristic.write(
        bytes,
        withoutResponse: characteristic.properties.writeWithoutResponse,
      );

      // 记录发送数据
      final transmission = DataTransmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransmissionType.send,
        endpointType: EndpointType.write,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        hexData: HexUtils.formatHex(hexData),
        timestamp: DateTime.now(),
      );

      _dataStreamController.add(transmission);
    } catch (e, stackTrace) {
      debugPrint('写入数据失败: $e');
      debugPrint('栈跟踪: $stackTrace');
      throw Exception('写入数据失败: $e');
    }
  }

  /// 读取数据（手动读取）
  Future<String> readData({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    if (_connectedDevice == null) {
      throw Exception('未连接设备');
    }

    try {
      // 查找服务和特征
      final services = await discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase(),
        orElse: () => throw Exception('未找到指定服务: $serviceUuid'),
      );

      final characteristic = service.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase(),
        orElse: () => throw Exception('未找到指定特征: $characteristicUuid'),
      );

      // 读取数据
      final bytes = await characteristic.read();
      final hexData = HexUtils.bytesToHex(bytes, withSpace: true);

      // 记录接收数据
      final transmission = DataTransmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransmissionType.receive,
        endpointType: EndpointType.read,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        hexData: hexData,
        timestamp: DateTime.now(),
      );

      _dataStreamController.add(transmission);

      return hexData;
    } catch (e) {
      throw Exception('读取数据失败: $e');
    }
  }

  // 存储Notify监听器的订阅，用于停止时清理
  final Map<String, StreamSubscription<List<int>>> _notifySubscriptions = {};

  /// 启用Notify监听
  Future<void> enableNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    if (_connectedDevice == null) {
      throw Exception('未连接设备');
    }

    try {
      // 查找服务和特征
      final services = await discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase(),
        orElse: () => throw Exception('未找到指定服务: $serviceUuid'),
      );

      final characteristic = service.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase(),
        orElse: () => throw Exception('未找到指定特征: $characteristicUuid'),
      );

      // 先停止已存在的监听（如果有）
      final key = '$serviceUuid:$characteristicUuid';
      await _notifySubscriptions[key]?.cancel();
      _notifySubscriptions.remove(key);

      // 启用Notify
      await characteristic.setNotifyValue(true);

      // 监听数据变化并保存订阅
      final subscription = characteristic.onValueReceived.listen((bytes) {
        if (bytes.isNotEmpty) {
          final hexData = HexUtils.bytesToHex(bytes, withSpace: true);

          // 记录接收数据
          final transmission = DataTransmission(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: TransmissionType.receive,
            endpointType: EndpointType.notify,
            serviceUuid: serviceUuid,
            characteristicUuid: characteristicUuid,
            hexData: hexData,
            timestamp: DateTime.now(),
          );

          _dataStreamController.add(transmission);
        }
      });

      _notifySubscriptions[key] = subscription;
    } catch (e) {
      throw Exception('启用Notify失败: $e');
    }
  }

  /// 停用Notify监听
  Future<void> disableNotify({
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    try {
      // 查找服务和特征
      final services = await discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() == serviceUuid.toLowerCase(),
        orElse: () => throw Exception('未找到指定服务: $serviceUuid'),
      );

      final characteristic = service.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase(),
        orElse: () => throw Exception('未找到指定特征: $characteristicUuid'),
      );

      // 停用Notify
      await characteristic.setNotifyValue(false);

      // 取消订阅并清理
      final key = '$serviceUuid:$characteristicUuid';
      await _notifySubscriptions[key]?.cancel();
      _notifySubscriptions.remove(key);
    } catch (e) {
      throw Exception('停用Notify失败: $e');
    }
  }

  /// 启用定时读取
  void enablePeriodicRead({
    required String serviceUuid,
    required String characteristicUuid,
    required int intervalSeconds,
  }) {
    final key = '$serviceUuid:$characteristicUuid';

    // 如果已存在，先清理
    if (_periodicReaders.containsKey(key)) {
      _periodicReaders[key]?.cancel();
    }

    // 创建定时器
    final timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) async {
      try {
        await readData(
          serviceUuid: serviceUuid,
          characteristicUuid: characteristicUuid,
        );
      } catch (e) {
        // 定时读取失败，记录日志但不中断服务
        debugPrint('定时读取失败: $e');
      }
    });

    _periodicReaders[key] = timer;
  }

  /// 停用定时读取
  void disablePeriodicRead({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    final key = '$serviceUuid:$characteristicUuid';
    _periodicReaders[key]?.cancel();
    _periodicReaders.remove(key);
  }

  /// 清理所有定时读取器
  void _clearAllPeriodicReaders() {
    for (var timer in _periodicReaders.values) {
      timer.cancel();
    }
    _periodicReaders.clear();
  }

  /// 获取当前连接的设备
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// 是否已连接
  bool get isConnected => _connectedDevice != null;

  /// 清理资源
  void dispose() {
    _dataStreamController.close();
    _scanStateController.close();
    _connectionStateController.close();
    _connectionSubscription?.cancel();
    _clearAllPeriodicReaders();
    _clearAllNotifySubscriptions();
  }

  /// 清理所有Notify订阅
  void _clearAllNotifySubscriptions() {
    for (var subscription in _notifySubscriptions.values) {
      subscription.cancel();
    }
    _notifySubscriptions.clear();
  }
}
