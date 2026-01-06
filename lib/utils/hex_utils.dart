/// HEX工具类
/// 提供HEX字符串和字节数组之间的转换功能
class HexUtils {
  /// 将HEX字符串转换为字节数组
  /// 支持带空格和不带空格的格式
  static List<int> hexToBytes(String hex) {
    // 移除所有空格
    String cleanHex = hex.replaceAll(' ', '');

    // 验证HEX格式
    if (cleanHex.isEmpty || cleanHex.length % 2 != 0) {
      return [];
    }

    // 验证是否只包含有效的HEX字符
    final hexRegex = RegExp(r'^[0-9A-Fa-f]+$');
    if (!hexRegex.hasMatch(cleanHex)) {
      return [];
    }

    List<int> bytes = [];
    for (int i = 0; i < cleanHex.length; i += 2) {
      final hexByte = cleanHex.substring(i, i + 2);
      bytes.add(int.parse(hexByte, radix: 16));
    }

    return bytes;
  }

  /// 将字节数组转换为HEX字符串
  static String bytesToHex(List<int> bytes, {bool withSpace = true}) {
    // 使用 StringBuffer 高效地构建字符串
    final StringBuffer hexBuffer = StringBuffer();
    for (final int byte in bytes) {
      // 将每个字节转换为两位十六进制数
      // toRadixString(16) 将整数转换为十六进制字符串
      // padLeft(2, '0') 确保不足两位的补零，例如 10 会变成 "0a" 而不是 "a"
      hexBuffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return hexBuffer.toString();
  }

  /// 验证HEX字符串格式是否有效
  static bool isValidHex(String hex) {
    // 移除空格进行验证
    String cleanHex = hex.replaceAll(' ', '');

    if (cleanHex.isEmpty) return false;

    final hexRegex = RegExp(r'^[0-9A-Fa-f]+$');
    return hexRegex.hasMatch(cleanHex) && cleanHex.length % 2 == 0;
  }

  /// 格式化HEX字符串（添加空格）
  static String formatHex(String hex) {
    // 移除现有空格
    String cleanHex = hex.replaceAll(' ', '');

    if (!isValidHex(cleanHex)) {
      return hex; // 如果无效，返回原字符串
    }

    StringBuffer formatted = StringBuffer();
    for (int i = 0; i < cleanHex.length; i += 2) {
      if (i > 0) {
        formatted.write(' ');
      }
      formatted.write(cleanHex.substring(i, i + 2));
    }

    return formatted.toString();
  }

  /// 从字节数组创建HEX字符串（用于显示）
  static String createDisplayHex(List<int> bytes) {
    return bytesToHex(bytes, withSpace: true);
  }

  /// 从HEX字符串获取字节长度
  static int getByteLength(String hex) {
    String cleanHex = hex.replaceAll(' ', '');
    if (!isValidHex(cleanHex)) {
      return 0;
    }
    return cleanHex.length ~/ 2;
  }

  /// 将单个字节转换为两位HEX字符串
  static String byteToHex(int byte) {
    return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  /// 将两位HEX字符串转换为字节
  static int hexToByte(String hex) {
    if (hex.length != 2) {
      throw ArgumentError('HEX字符串长度必须为2');
    }
    return int.parse(hex, radix: 16);
  }
}
