import 'package:json_annotation/json_annotation.dart';

part 'ble_device.g.dart';

/// BLE设备模型
/// 包含设备的基本信息和广播数据
@JsonSerializable()
class BLEDevice {
  /// 设备MAC地址或唯一标识
  final String deviceId;

  /// 设备名称
  final String? name;

  /// 设备型号（自定义标识，用于快捷指令管理）
  String? model;

  /// RSSI信号强度
  final int rssi;

  /// 广播数据
  final Map<String, dynamic> advertisementData;

  /// 服务UUID列表
  final List<String> serviceUuids;

  /// 连接状态
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isConnected;

  /// 最后连接时间
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime? lastConnected;

  /// 构造函数
  BLEDevice({
    required this.deviceId,
    this.name,
    this.model,
    required this.rssi,
    required this.advertisementData,
    required this.serviceUuids,
    this.isConnected = false,
    this.lastConnected,
  });

  /// 从JSON反序列化
  factory BLEDevice.fromJson(Map<String, dynamic> json) =>
      _$BLEDeviceFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$BLEDeviceToJson(this);

  /// 获取完整的广播信息字符串
  String getAdvertisementInfo() {
    StringBuffer info = StringBuffer();
    info.write('设备ID: $deviceId\n');
    if (name != null) info.write('名称: $name\n');
    info.write('RSSI: $rssi dBm\n');
    info.write('服务UUID: ${serviceUuids.join(", ")}\n');

    // 添加所有广播数据
    advertisementData.forEach((key, value) {
      info.write('$key: $value\n');
    });

    return info.toString();
  }

  /// 获取显示名称（优先使用名称，其次使用ID）
  String get displayName => name ?? deviceId;

  /// 获取型号标识（如果未设置型号，使用设备ID）
  String get displayModel => model ?? deviceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BLEDevice &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;

  @override
  String toString() {
    return 'BLEDevice{deviceId: $deviceId, name: $name, model: $model, rssi: $rssi, isConnected: $isConnected}';
  }
}
