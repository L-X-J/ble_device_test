/// 收发特征配置模型
/// 用于配置BLE设备的发送和接收特征
class TransceiverConfig {
  /// 设备型号（用于关联配置）
  String? deviceModel;

  /// 发送特征配置
  String? sendServiceUuid;
  String? sendCharacteristicUuid;

  /// 接收特征配置
  String? receiveServiceUuid;
  String? receiveCharacteristicUuid;

  /// 通知特征配置（用于监听接收）
  String? notifyServiceUuid;
  String? notifyCharacteristicUuid;

  /// 特征属性缓存
  final Map<String, Map<String, bool>> _characteristicProperties = {};

  TransceiverConfig({
    this.deviceModel,
    this.sendServiceUuid,
    this.sendCharacteristicUuid,
    this.receiveServiceUuid,
    this.receiveCharacteristicUuid,
    this.notifyServiceUuid,
    this.notifyCharacteristicUuid,
  });

  /// 从JSON创建配置
  factory TransceiverConfig.fromJson(Map<String, dynamic> json) {
    final config = TransceiverConfig(
      deviceModel: json['deviceModel'],
      sendServiceUuid: json['sendServiceUuid'],
      sendCharacteristicUuid: json['sendCharacteristicUuid'],
      receiveServiceUuid: json['receiveServiceUuid'],
      receiveCharacteristicUuid: json['receiveCharacteristicUuid'],
      notifyServiceUuid: json['notifyServiceUuid'],
      notifyCharacteristicUuid: json['notifyCharacteristicUuid'],
    );
    if (json['characteristicProperties'] != null) {
      final properties =
          json['characteristicProperties'] as Map<String, dynamic>;
      properties.forEach((key, value) {
        config._characteristicProperties[key] = Map<String, bool>.from(value);
      });
    }
    return config;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceModel': deviceModel,
      'sendServiceUuid': sendServiceUuid,
      'sendCharacteristicUuid': sendCharacteristicUuid,
      'receiveServiceUuid': receiveServiceUuid,
      'receiveCharacteristicUuid': receiveCharacteristicUuid,
      'notifyServiceUuid': notifyServiceUuid,
      'notifyCharacteristicUuid': notifyCharacteristicUuid,
      'characteristicProperties': _characteristicProperties,
    };
  }

  /// 复制配置（用于修改部分字段）
  TransceiverConfig copyWith({
    String? deviceModel,
    String? sendServiceUuid,
    String? sendCharacteristicUuid,
    String? receiveServiceUuid,
    String? receiveCharacteristicUuid,
    String? notifyServiceUuid,
    String? notifyCharacteristicUuid,
  }) {
    return TransceiverConfig(
      deviceModel: deviceModel ?? this.deviceModel,
      sendServiceUuid: sendServiceUuid ?? this.sendServiceUuid,
      sendCharacteristicUuid:
          sendCharacteristicUuid ?? this.sendCharacteristicUuid,
      receiveServiceUuid: receiveServiceUuid ?? this.receiveServiceUuid,
      receiveCharacteristicUuid:
          receiveCharacteristicUuid ?? this.receiveCharacteristicUuid,
      notifyServiceUuid: notifyServiceUuid ?? this.notifyServiceUuid,
      notifyCharacteristicUuid:
          notifyCharacteristicUuid ?? this.notifyCharacteristicUuid,
    );
  }

  /// 设置特征属性
  void setCharacteristicProperties(
    String serviceUuid,
    String characteristicUuid,
    bool canRead,
    bool canWrite,
    bool canNotify,
  ) {
    final key =
        '${serviceUuid.toLowerCase()}:${characteristicUuid.toLowerCase()}';
    _characteristicProperties[key] = {
      'canRead': canRead,
      'canWrite': canWrite,
      'canNotify': canNotify,
    };
  }

  /// 检查特征是否可读
  bool canRead(String serviceUuid, String characteristicUuid) {
    final key =
        '${serviceUuid.toLowerCase()}:${characteristicUuid.toLowerCase()}';
    return _characteristicProperties[key]?['canRead'] ?? false;
  }

  /// 检查特征是否可写
  bool canWrite(String serviceUuid, String characteristicUuid) {
    final key =
        '${serviceUuid.toLowerCase()}:${characteristicUuid.toLowerCase()}';
    return _characteristicProperties[key]?['canWrite'] ?? false;
  }

  /// 检查特征是否支持通知
  bool canNotify(String serviceUuid, String characteristicUuid) {
    final key =
        '${serviceUuid.toLowerCase()}:${characteristicUuid.toLowerCase()}';
    return _characteristicProperties[key]?['canNotify'] ?? false;
  }

  /// 获取特征属性描述
  String getCharacteristicProperties(
    String serviceUuid,
    String characteristicUuid,
  ) {
    final props = [];
    if (canRead(serviceUuid, characteristicUuid)) props.add('可读');
    if (canWrite(serviceUuid, characteristicUuid)) props.add('可写');
    if (canNotify(serviceUuid, characteristicUuid)) props.add('通知');
    return props.join(' | ');
  }

  /// 检查是否配置了发送
  bool get hasSendConfig =>
      sendServiceUuid != null && sendCharacteristicUuid != null;

  /// 检查是否配置了读取接收
  bool get hasReceiveConfig =>
      receiveServiceUuid != null && receiveCharacteristicUuid != null;

  /// 检查是否配置了通知接收
  bool get hasNotifyConfig =>
      notifyServiceUuid != null && notifyCharacteristicUuid != null;

  /// 检查是否完整配置
  bool get isValid => hasSendConfig || hasReceiveConfig || hasNotifyConfig;

  /// 清除所有配置
  void clear() {
    deviceModel = null;
    sendServiceUuid = null;
    sendCharacteristicUuid = null;
    receiveServiceUuid = null;
    receiveCharacteristicUuid = null;
    notifyServiceUuid = null;
    notifyCharacteristicUuid = null;
    _characteristicProperties.clear();
  }

  @override
  String toString() {
    return 'TransceiverConfig(\n'
        '  Model: $deviceModel\n'
        '  Send: $sendServiceUuid / $sendCharacteristicUuid\n'
        '  Receive: $receiveServiceUuid / $receiveCharacteristicUuid\n'
        '  Notify: $notifyServiceUuid / $notifyCharacteristicUuid\n'
        ')';
  }
}
