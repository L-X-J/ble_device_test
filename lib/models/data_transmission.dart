import 'package:json_annotation/json_annotation.dart';

part 'data_transmission.g.dart';

/// 数据传输类型
enum TransmissionType {
  send, // 发送
  receive, // 接收
}

/// 端点类型
enum EndpointType {
  notify, // 通知端点（实时监听）
  read, // 读取端点（手动/定时读取）
  write, // 写入端点
}

/// 数据传输记录模型
@JsonSerializable()
class DataTransmission {
  /// 传输ID
  final String id;

  /// 传输类型
  final TransmissionType type;

  /// 端点类型
  final EndpointType endpointType;

  /// 服务UUID
  final String serviceUuid;

  /// 特征UUID
  final String characteristicUuid;

  /// 数据内容（HEX格式）
  final String hexData;

  /// 时间戳
  final DateTime timestamp;

  /// 备注信息
  final String? note;

  /// 构造函数
  DataTransmission({
    required this.id,
    required this.type,
    required this.endpointType,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.hexData,
    required this.timestamp,
    this.note,
  });

  /// 从JSON反序列化
  factory DataTransmission.fromJson(Map<String, dynamic> json) =>
      _$DataTransmissionFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$DataTransmissionToJson(this);

  /// 获取格式化的HEX显示（AA0102 -> AA 01 02）
  String get formattedHex {
    if (hexData.length % 2 != 0) {
      return hexData;
    }

    StringBuffer formatted = StringBuffer();
    for (int i = 0; i < hexData.length; i += 2) {
      if (i > 0) formatted.write(' ');
      formatted.write(hexData.substring(i, i + 2));
    }
    return formatted.toString();
  }

  /// 获取字节数组
  List<int> get bytes {
    if (hexData.length % 2 != 0) {
      return [];
    }

    List<int> result = [];
    for (int i = 0; i < hexData.length; i += 2) {
      final hexByte = hexData.substring(i, i + 2);
      result.add(int.parse(hexByte, radix: 16));
    }
    return result;
  }

  /// 获取显示用的端点类型名称
  String get endpointTypeName {
    switch (endpointType) {
      case EndpointType.notify:
        return 'Notify';
      case EndpointType.read:
        return 'Read';
      case EndpointType.write:
        return 'Write';
    }
  }

  /// 获取显示用的传输类型名称
  String get transmissionTypeName {
    switch (type) {
      case TransmissionType.send:
        return '发送';
      case TransmissionType.receive:
        return '接收';
    }
  }

  /// 获取颜色标识（用于UI显示）
  String get colorCode {
    if (type == TransmissionType.send) {
      return '0xFF4CAF50'; // 绿色
    } else {
      if (endpointType == EndpointType.notify) {
        return '0xFFFF9800'; // 橙色
      } else {
        return '0xFF2196F3'; // 蓝色
      }
    }
  }

  @override
  String toString() {
    return 'DataTransmission{id: $id, type: $type, endpointType: $endpointType, hexData: $hexData, timestamp: $timestamp}';
  }
}

/// 读取端点配置
@JsonSerializable()
class ReadEndpointConfig {
  /// 服务UUID
  final String serviceUuid;

  /// 特征UUID
  final String characteristicUuid;

  /// 是否启用定时读取
  bool enablePeriodicRead;

  /// 定时读取周期（秒）
  int readIntervalSeconds;

  /// 构造函数
  ReadEndpointConfig({
    required this.serviceUuid,
    required this.characteristicUuid,
    this.enablePeriodicRead = false,
    this.readIntervalSeconds = 3,
  });

  /// 从JSON反序列化
  factory ReadEndpointConfig.fromJson(Map<String, dynamic> json) =>
      _$ReadEndpointConfigFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$ReadEndpointConfigToJson(this);

  @override
  String toString() {
    return 'ReadEndpointConfig{serviceUuid: $serviceUuid, characteristicUuid: $characteristicUuid, enablePeriodicRead: $enablePeriodicRead, readIntervalSeconds: $readIntervalSeconds}';
  }
}
