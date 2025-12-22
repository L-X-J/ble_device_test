import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../providers/ble_provider.dart';
import '../../models/ble_device.dart';
import '../widgets/gradient_card.dart';

/// 设备管理界面
/// 展示设备列表、广播信息和型号管理
class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DeviceManagementScreenState createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final TextEditingController _modelController = TextEditingController();

  @override
  void dispose() {
    _modelController.dispose();
    super.dispose();
  }

  /// 显示设置型号的对话框
  void _showModelDialog(BuildContext context, BLEDevice device) {
    // 如果没有设置型号，默认使用设备名称
    if (device.model == null || device.model!.isEmpty) {
      _modelController.text = device.name ?? device.deviceId;
    } else {
      _modelController.text = device.model!;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置设备型号'),
        content: TextField(
          controller: _modelController,
          decoration: const InputDecoration(
            labelText: '设备型号',
            hintText: '请输入设备型号（唯一标识）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final model = _modelController.text.trim();
              if (model.isNotEmpty) {
                final provider = Provider.of<BLEProvider>(
                  context,
                  listen: false,
                );
                await provider.setDeviceModel(model);
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnackBar('设备型号已设置');
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示设备详情对话框
  void _showDeviceDetailsDialog(BuildContext context, BluetoothDevice device) {
    final provider = Provider.of<BLEProvider>(context, listen: false);

    // 获取广播数据
    final advData = provider.getDeviceAdvertisementData(device.remoteId.str);

    String rssiInfo = 'N/A';
    String advInfo = '暂无广播数据';

    if (advData != null) {
      // 显示信号强度
      if (advData['rssi'] != null) {
        rssiInfo = '${advData['rssi']} dBm';
      }

      // 格式化广播数据
      final buffer = StringBuffer();
      // buffer.write('设备名称: ${advData['deviceName'] ?? '未知'}\n');
      // buffer.write('信号强度: ${advData['rssi'] ?? 'N/A'} dBm\n');
      // buffer.write('可连接: ${advData['connectable'] ?? '未知'}\n');

      // // 服务UUID
      // if (advData['serviceUuids'] != null &&
      //     advData['serviceUuids'].isNotEmpty) {
      //   buffer.write('服务UUID:\n');
      //   for (var uuid in advData['serviceUuids']) {
      //     buffer.write('  - $uuid\n');
      //   }
      // }

      // 制造商数据
      if (advData['manufacturerData'] != null &&
          advData['manufacturerData'].isNotEmpty) {
        buffer.write('制造商数据:\n');
        advData['manufacturerData'].forEach((id, data) {
          buffer.write(
            '  ID: 0x${id.toRadixString(16).padLeft(4, '0')}, 数据: ${data.length} 字节\n',
          );
        });
      }

      // 服务数据
      if (advData['serviceData'] != null && advData['serviceData'].isNotEmpty) {
        buffer.write('服务数据:\n');
        advData['serviceData'].forEach((uuid, data) {
          buffer.write('  UUID: $uuid, 数据: ${data.length} 字节\n');
        });
      }

      // 发射功率
      if (advData['txPowerLevel'] != null) {
        buffer.write('发射功率: ${advData['txPowerLevel']} dBm\n');
      }

      advInfo = buffer.toString().trim();
      if (advInfo.isEmpty) {
        advInfo = '广播数据为空';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设备广播信息'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow('设备ID', device.remoteId.str),
                _buildInfoRow(
                  '设备名称',
                  device.platformName.isEmpty ? '未知' : device.platformName,
                ),
                _buildInfoRow('MAC地址', device.remoteId.str),
                _buildInfoRow('信号强度', rssiInfo),
                const SizedBox(height: 8),
                const Text(
                  '广播数据 (ADV):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    advInfo,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'Courier',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// 显示提示信息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Build Device List
  Widget _buildDeviceList(BLEProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
            ),
            SizedBox(height: 16),
            Text('处理中...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (provider.isScanning && provider.scannedDevices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              '正在搜索附近设备...',
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    if (!provider.isScanning && provider.scannedDevices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              '未找到设备，开始扫描。',
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    // 按信号强度排序，信号强的在前面
    final sortedDevices = List<BluetoothDevice>.from(provider.scannedDevices)
      ..sort((a, b) {
        final rssiA =
            provider.getDeviceAdvertisementData(a.remoteId.str)?['rssi']
                as int? ??
            -100;
        final rssiB =
            provider.getDeviceAdvertisementData(b.remoteId.str)?['rssi']
                as int? ??
            -100;
        return rssiB.compareTo(rssiA); // 降序排列，信号强的在前
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: sortedDevices.length,
      itemBuilder: (context, index) {
        final device = sortedDevices[index];
        return _buildDeviceItem(device, provider, index);
      },
    );
  }

  /// Build Device Item with Animation
  Widget _buildDeviceItem(
    BluetoothDevice device,
    BLEProvider provider,
    int index,
  ) {
    // Get RSSI
    final advData = provider.getDeviceAdvertisementData(device.remoteId.str);
    final rssi = advData?['rssi'] as int?;

    // Calculate animation delay based on index for staggered effect
    final delay = index * 50; // 50ms delay per item

    return AnimatedOpacity(
      opacity: 1.0,
      duration: Duration(milliseconds: 300 + delay),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400 + delay),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 30),
            child: Transform.scale(scale: 0.9 + (value * 0.1), child: child),
          );
        },
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + delay),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color.lerp(
                    Colors.white.withOpacity(0.05),
                    _getRssiColor(rssi ?? -100).withOpacity(0.3),
                    value,
                  )!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getRssiColor(rssi ?? -100).withOpacity(value * 0.2),
                    blurRadius: 10 * value,
                    spreadRadius: 2 * value,
                    offset: Offset(0, 4 * value),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showDeviceDetailsDialog(context, device),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Animated Icon
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 0.3,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getRssiColor(
                                    rssi ?? -100,
                                  ).withOpacity(0.1 * value),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _getRssiColor(
                                      rssi ?? -100,
                                    ).withOpacity(0.3 * value),
                                  ),
                                ),
                                child: Icon(
                                  Icons.bluetooth,
                                  color: _getRssiColor(rssi ?? -100),
                                  size: 20 + (value * 4),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      device.platformName.isEmpty
                                          ? '未知设备'
                                          : device.platformName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (rssi != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRssiColor(
                                          rssi,
                                        ).withAlpha(50),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _getRssiColor(
                                            rssi,
                                          ).withAlpha(50),
                                        ),
                                      ),
                                      child: Text(
                                        '$rssi dBm',
                                        style: TextStyle(
                                          color: _getRssiColor(rssi),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                device.remoteId.str,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              if (provider.currentDevice?.remoteId ==
                                      device.remoteId &&
                                  provider.isConnected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent[400]
                                              ?.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.greenAccent[400]!,
                                          ),
                                        ),
                                        child: Text(
                                          '已连接',
                                          style: TextStyle(
                                            color: Colors.greenAccent[400],
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Animated pulse indicator
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(
                                          milliseconds: 1000,
                                        ),
                                        tween: Tween<double>(
                                          begin: 0.0,
                                          end: 1.0,
                                        ),
                                        builder: (context, value, child) {
                                          return Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.greenAccent[400],
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors
                                                      .greenAccent[400]!
                                                      .withOpacity(
                                                        0.5 * (1 - value),
                                                      ),
                                                  blurRadius: 8 * (1 - value),
                                                  spreadRadius: 2 * (1 - value),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Action Button
                        if (provider.currentDevice?.remoteId !=
                                device.remoteId ||
                            !provider.isConnected)
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (value * 0.2),
                                child: Opacity(
                                  opacity: value,
                                  child: InkWell(
                                    onTap: () async {
                                      // Add tap animation
                                      await provider.connectToDevice(device);
                                      if (!context.mounted) return;

                                      if (provider.isConnected) {
                                        _showSnackBar('连接成功');
                                        Navigator.pushNamed(
                                          context,
                                          '/data_transmission',
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue,
                                            Colors.blueAccent,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.blueAccent,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        '连接',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (value * 0.2),
                                child: Opacity(
                                  opacity: value,
                                  child: InkWell(
                                    onTap: () async {
                                      await provider.disconnectDevice();
                                      _showSnackBar('已断开连接');
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red,
                                            Colors.redAccent,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.redAccent,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        '断开',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 根据信号强度返回颜色
  Color _getRssiColor(int rssi) {
    if (rssi >= -60) {
      return Colors.green; // 信号强
    } else if (rssi >= -75) {
      return Colors.orange; // 信号中等
    } else {
      return Colors.red; // 信号弱
    }
  }

  /// Build Current Device Card
  Widget _buildCurrentDeviceCard(BLEProvider provider) {
    if (provider.currentBLEDevice == null) {
      return const SizedBox.shrink();
    }

    return GradientCard(
      colors: const [Color(0xFFFF7F50), Color(0xFFFF1493)], // Orange to Pink
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '已连接设备',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '活跃',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            provider.currentBLEDevice!.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${provider.currentBLEDevice!.deviceId}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/data_transmission');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF1493),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('数据传输'),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () =>
                      _showModelDialog(context, provider.currentBLEDevice!),
                  tooltip: '编辑型号',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Scan Control Card
  Widget _buildScanControl(BLEProvider provider) {
    return GradientCard(
      colors: const [Color(0xFF3B82F6), Color(0xFF8B5CF6)], // Blue to Purple
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bluetooth_searching,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isScanning ? '扫描中...' : '扫描设备',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        provider.isScanning
                            ? '找到 ${provider.scannedDevices.length} 个设备'
                            : '准备扫描',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Action Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    provider.isScanning ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: provider.isScanning
                      ? () => provider.stopScan()
                      : () => provider.startScan(),
                  tooltip: provider.isScanning ? '停止扫描' : '开始扫描',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128), // Deep Navy
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'BLE 控制台',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFA5B4FC),
              ),
            ),
            Text(
              '低功耗蓝牙调试助手',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // 跳转到快捷指令页面
          IconButton(
            icon: const Icon(Icons.keyboard_command_key, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/commands'),
            tooltip: '快捷指令',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Provider.of<BLEProvider>(context).isConnected
                  ? const Color(0xFF10B981).withAlpha(64)
                  : Colors.grey.withAlpha(64),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Provider.of<BLEProvider>(context).isConnected
                    ? const Color(0xFF10B981)
                    : Colors.grey,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Provider.of<BLEProvider>(context).isConnected
                      ? const Color(0xFF10B981)
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  Provider.of<BLEProvider>(context).isConnected ? '已连接' : '未连接',
                  style: TextStyle(
                    color: Provider.of<BLEProvider>(context).isConnected
                        ? const Color(0xFF10B981)
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<BLEProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Error Message
              if (provider.errorMessage != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => provider.clearError(),
                      ),
                    ],
                  ),
                ),

              // Scan Control Card
              _buildScanControl(provider),

              // Current Device Card (if connected)
              _buildCurrentDeviceCard(provider),

              // Device List Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '可用设备',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (provider.isScanning)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Device List
              Expanded(child: _buildDeviceList(provider)),
            ],
          );
        },
      ),
    );
  }
}
