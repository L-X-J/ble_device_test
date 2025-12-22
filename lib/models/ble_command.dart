import 'package:json_annotation/json_annotation.dart';

part 'ble_command.g.dart';

/// BLE指令模型
/// 用于存储和管理快捷指令
@JsonSerializable()
class BLECommand {
  /// 指令唯一ID
  final String id;

  /// 设备型号（唯一标识）
  final String deviceModel;

  /// 指令名称
  final String name;

  /// HEX指令内容（如 "AA0102"）
  final String hexContent;

  /// 备注（可选）
  final String? remark;

  /// 创建时间
  final DateTime createdAt;

  /// 构造函数
  BLECommand({
    required this.id,
    required this.deviceModel,
    required this.name,
    required this.hexContent,
    this.remark,
    required this.createdAt,
  });

  /// 从JSON反序列化
  factory BLECommand.fromJson(Map<String, dynamic> json) =>
      _$BLECommandFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$BLECommandToJson(this);

  /// 验证HEX格式是否有效
  bool get isValidHex {
    final hexRegex = RegExp(r'^[0-9A-Fa-f]+$');
    return hexRegex.hasMatch(hexContent);
  }

  /// 获取格式化的HEX显示（AA0102 -> AA 01 02）
  String get formattedHex {
    if (hexContent.length % 2 != 0) {
      return hexContent; // 如果长度不是偶数，保持原样
    }

    StringBuffer formatted = StringBuffer();
    for (int i = 0; i < hexContent.length; i += 2) {
      if (i > 0) formatted.write(' ');
      formatted.write(hexContent.substring(i, i + 2));
    }
    return formatted.toString();
  }

  /// 获取字节数组
  List<int> get bytes {
    if (!isValidHex || hexContent.length % 2 != 0) {
      return [];
    }

    List<int> result = [];
    for (int i = 0; i < hexContent.length; i += 2) {
      final hexByte = hexContent.substring(i, i + 2);
      result.add(int.parse(hexByte, radix: 16));
    }
    return result;
  }

  @override
  String toString() {
    return 'BLECommand{id: $id, deviceModel: $deviceModel, name: $name, hexContent: $hexContent}';
  }
}
