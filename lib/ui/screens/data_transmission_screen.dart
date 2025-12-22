import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../providers/ble_provider.dart';
import '../../models/data_transmission.dart';
import '../../utils/hex_utils.dart';
import '../widgets/gradient_card.dart';

/// 数据收发界面
class DataTransmissionScreen extends StatefulWidget {
  const DataTransmissionScreen({super.key});

  @override
  State<DataTransmissionScreen> createState() => _DataTransmissionScreenState();
}

class _DataTransmissionScreenState extends State<DataTransmissionScreen> {
  final TextEditingController _sendController = TextEditingController();
  final ScrollController _receiveScrollController = ScrollController();
  final ScrollController _sendHistoryScrollController = ScrollController();

  // 收数据模式状态
  // 0: 无, 1: 读一次, 2: 定时读取, 3: Notify
  int _receiveMode = 0;
  final int _readInterval = 2; // Default 2s

  // 运行状态
  bool _isTimerRunning = false;
  bool _isNotifyRunning = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _sendController.dispose();
    _receiveScrollController.dispose();
    _sendHistoryScrollController.dispose();
    super.dispose();
  }

  /// 格式化HEX输入
  void _formatHexInput() {
    String text = _sendController.text.replaceAll(' ', '');
    if (HexUtils.isValidHex(text)) {
      setState(() {
        _sendController.text = HexUtils.formatHex(text);
        _sendController.selection = TextSelection.fromPosition(
          TextPosition(offset: _sendController.text.length),
        );
      });
    }
  }

  /// 发送数据
  Future<void> _sendData() async {
    final provider = Provider.of<BLEProvider>(context, listen: false);

    if (!provider.isConnected) {
      _showSnackBar('请先连接设备');
      return;
    }

    final hexData = _sendController.text.trim();
    if (hexData.isEmpty) {
      _showSnackBar('请输入HEX数据');
      return;
    }

    if (!HexUtils.isValidHex(hexData)) {
      _showSnackBar('HEX格式无效');
      return;
    }

    if (provider.transceiverConfig.hasSendConfig) {
      try {
        await provider.sendWithConfig(hexData);
        _showSnackBar('✅ 数据发送成功');
      } catch (e) {
        // 清理错误信息，移除换行符以便在SnackBar中显示
        String errorMsg = e.toString().replaceAll('\n', ' | ');
        _showSnackBar('❌ 发送失败: $errorMsg');
      }
    } else {
      _showSnackBar('⚠️ 请先配置发送特征');
    }
  }

  /// 执行接收操作（根据当前选择的模式）
  Future<void> _executeReceiveAction() async {
    final provider = Provider.of<BLEProvider>(context, listen: false);

    if (!provider.isConnected) {
      _showSnackBar('请先连接设备');
      return;
    }

    if (_receiveMode == 0) {
      _showSnackBar('请先选择读取模式');
      return;
    }

    // 如果已经在运行，先停止
    if (_isTimerRunning) {
      try {
        await provider.disablePeriodicReadWithConfig();
        if (!mounted) return;
        setState(() {
          _isTimerRunning = false;
        });
      } catch (e) {
        String errorMsg = e.toString().replaceAll('\n', ' | ');
        _showSnackBar('❌ 停止定时读取失败: $errorMsg');
        return;
      }
    }
    if (_isNotifyRunning) {
      try {
        await provider.disableNotifyWithConfig();
        if (!mounted) return;
        setState(() {
          _isNotifyRunning = false;
        });
      } catch (e) {
        String errorMsg = e.toString().replaceAll('\n', ' | ');
        _showSnackBar('❌ 停止Notify失败: $errorMsg');
        return;
      }
    }

    // 根据模式执行操作
    if (_receiveMode == 1) {
      // 读一次
      if (provider.transceiverConfig.hasReceiveConfig) {
        try {
          await provider.receiveWithConfig();
          _showSnackBar('✅ 已读取一次');
        } catch (e) {
          String errorMsg = e.toString().replaceAll('\n', ' | ');
          _showSnackBar('❌ 读取失败: $errorMsg');
        }
      } else {
        _showSnackBar('⚠️ 请先配置接收特征');
      }
    } else if (_receiveMode == 2) {
      // 定时读取
      if (provider.transceiverConfig.hasReceiveConfig) {
        try {
          await provider.enablePeriodicReadWithConfig(_readInterval);
          setState(() {
            _isTimerRunning = true;
          });
          _showSnackBar('✅ 定时读取已启用（${_readInterval}s）');
        } catch (e) {
          String errorMsg = e.toString().replaceAll('\n', ' | ');
          _showSnackBar('❌ 启用定时读取失败: $errorMsg');
        }
      } else {
        _showSnackBar('⚠️ 请先配置接收特征');
      }
    } else if (_receiveMode == 3) {
      // Notify
      if (provider.transceiverConfig.hasNotifyConfig) {
        try {
          await provider.enableNotifyWithConfig();
          setState(() {
            _isNotifyRunning = true;
          });
          _showSnackBar('✅ 已启用Notify监听');
        } catch (e) {
          String errorMsg = e.toString().replaceAll('\n', ' | ');
          _showSnackBar('❌ 启用Notify失败: $errorMsg');
        }
      } else {
        _showSnackBar('⚠️ 请先配置Notify特征');
      }
    }
  }

  /// 停止所有操作
  Future<void> _stopAllActions() async {
    final provider = Provider.of<BLEProvider>(context, listen: false);

    if (_isTimerRunning) {
      try {
        await provider.disablePeriodicReadWithConfig();
        _showSnackBar('✅ 已停止定时读取');
      } catch (e) {
        String errorMsg = e.toString().replaceAll('\n', ' | ');
        _showSnackBar('❌ 停止定时读取失败: $errorMsg');
        return; // 如果停止失败，不更新UI状态
      }
    }

    if (_isNotifyRunning) {
      try {
        await provider.disableNotifyWithConfig();
        _showSnackBar('✅ 已停止Notify监听');
      } catch (e) {
        String errorMsg = e.toString().replaceAll('\n', ' | ');
        _showSnackBar('❌ 停止Notify失败: $errorMsg');
        return; // 如果停止失败，不更新UI状态
      }
    }

    setState(() {
      _receiveMode = 0;
      _isTimerRunning = false;
      _isNotifyRunning = false;
    });

    if (!_isTimerRunning && !_isNotifyRunning) {
      _showSnackBar('✅ 已停止');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  /// 显示UUID配置对话框
  void _showUUIDConfigDialog(BLEProvider provider, {required bool isSend}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UUIDConfigDialog(
        isSend: isSend,
        services: provider.services,
        initialServiceUuid: isSend
            ? provider.transceiverConfig.sendServiceUuid
            : provider.transceiverConfig.receiveServiceUuid,
        initialCharUuid: isSend
            ? provider.transceiverConfig.sendCharacteristicUuid
            : provider.transceiverConfig.receiveCharacteristicUuid,
        onConfirm: (serviceUuid, charUuid, properties) {
          if (isSend) {
            provider.setSendConfig(serviceUuid, charUuid);
            provider.transceiverConfig.setCharacteristicProperties(
              serviceUuid,
              charUuid,
              properties.canRead,
              properties.canWrite,
              properties.canNotify,
            );
            provider.saveTransceiverConfig();
          } else {
            // 设置接收配置
            provider.setReceiveConfig(serviceUuid, charUuid);
            // 如果支持Notify，也设置Notify配置
            if (properties.canNotify) {
              provider.setNotifyConfig(serviceUuid, charUuid);
            }
            // 保存属性到配置中
            provider.transceiverConfig.setCharacteristicProperties(
              serviceUuid,
              charUuid,
              properties.canRead,
              properties.canWrite,
              properties.canNotify,
            );
            provider.saveTransceiverConfig();
          }
          _showSnackBar('${isSend ? "发送" : "接收"}配置已更新');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128), // Deep Navy
      appBar: AppBar(
        title: const Text(
          '数据传输',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA5B4FC),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.playlist_add_check, color: Colors.white70),
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/commands');
                if (result != null && result is Map<String, dynamic>) {
                  // 填充指令到发送框
                  if (mounted) {
                    setState(() {
                      _sendController.text = result['hex'] ?? '';
                    });
                    // 显示提示
                    if (result['name'] != null) {
                      _showSnackBar('已加载指令: ${result['name']}');
                    }
                  }
                }
              },
              tooltip: '快捷指令',
            ),
          ),
        ],
      ),
      body: Consumer<BLEProvider>(
        builder: (context, provider, child) {
          if (!provider.isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 64,
                    color: Colors.white.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Device Disconnected',
                    style: TextStyle(
                      color: Colors.white.withAlpha(170),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                _buildReceiveCard(provider),
                const SizedBox(height: 8),
                _buildSendCard(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建接收卡片
  Widget _buildReceiveCard(BLEProvider provider) {
    // Filter receive logs
    final receiveLogs = provider.transmissions
        .where(
          (t) =>
              t.type == TransmissionType.receive ||
              t.endpointType == EndpointType.notify,
        )
        .toList()
        .reversed
        .toList();

    // Check properties for available modes
    final config = provider.transceiverConfig;
    bool canRead = false;
    bool canNotify = false;

    if (config.receiveServiceUuid != null &&
        config.receiveCharacteristicUuid != null) {
      canRead = config.canRead(
        config.receiveServiceUuid!,
        config.receiveCharacteristicUuid!,
      );
    }
    if (config.notifyServiceUuid != null &&
        config.notifyCharacteristicUuid != null) {
      canNotify = config.canNotify(
        config.notifyServiceUuid!,
        config.notifyCharacteristicUuid!,
      );
    }

    return GradientCard(
      colors: const [Color(0xFF3B82F6), Color(0xFF8B5CF6)], // Blue to Purple
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '接收数据',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '监听通知数据',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () =>
                        _showUUIDConfigDialog(provider, isSend: false),
                    tooltip: '配置接收',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => provider.clearTransmissions(),
                    tooltip: '清空日志',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mode Selection
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildModeTab('读一次', 1, canRead),
                _buildModeTab('定时读取', 2, canRead),
                _buildModeTab('Notify', 3, canNotify),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons (if mode selected)
          if (_receiveMode != 0) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isTimerRunning || _isNotifyRunning
                        ? null
                        : () => _executeReceiveAction(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3B82F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _isTimerRunning || _isNotifyRunning ? '运行中...' : '开始监听',
                    ),
                  ),
                ),
                if (_isTimerRunning || _isNotifyRunning) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _stopAllActions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('停止'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Logs Area
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.9,
              ), // Light background for readability
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: receiveLogs.isEmpty
                ? Center(
                    child: Text(
                      '暂无数据',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    controller: _receiveScrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: receiveLogs.length,
                    itemBuilder: (context, index) {
                      final log = receiveLogs[index];
                      final isNotify = log.endpointType == EndpointType.notify;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6), // Light Gray
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatTime(log.timestamp),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isNotify
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isNotify ? 'NOTIFY' : 'READ',
                                    style: TextStyle(
                                      color: isNotify
                                          ? Colors.blue
                                          : Colors.purple,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              log.formattedHex,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, int value, bool available) {
    final isSelected = _receiveMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: available
            ? () {
                setState(() {
                  _receiveMode = value;
                });
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: available
                  ? (isSelected ? const Color(0xFF3B82F6) : Colors.white)
                  : Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建发送卡片
  Widget _buildSendCard(BLEProvider provider) {
    // Filter send logs
    final sendLogs = provider.transmissions
        .where((t) => t.type == TransmissionType.send)
        .toList()
        .reversed
        .toList();

    return GradientCard(
      colors: const [Color(0xFFFF7F50), Color(0xFFFF1493)], // Orange to Pink
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '发送数据',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '写入数据到特征',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showUUIDConfigDialog(provider, isSend: true),
                tooltip: '配置发送',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Commands
          if (provider.currentBLEDevice != null) ...[
            Text(
              '快捷指令',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _buildQuickCommands(provider),
            const SizedBox(height: 16),
          ],

          // Payload Input
          Text(
            '数据内容',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(180), // Black background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _sendController,
              style: const TextStyle(
                color: Colors.white, // White text
                fontFamily: 'Courier',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: '输入HEX数据 (如: 01 AA)',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: 'Sans',
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                fillColor: Colors.transparent,
              ),
              onChanged: (val) {
                if (val.isNotEmpty && !val.contains(' ')) {
                  if (val.length % 2 == 0 &&
                      RegExp(r'^[0-9A-Fa-f]+$').hasMatch(val)) {
                    _formatHexInput();
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendData,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('发送指令'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ),

          if (sendLogs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '发送历史',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                controller: _sendHistoryScrollController,
                padding: const EdgeInsets.all(8),
                itemCount: sendLogs.length,
                itemBuilder: (context, index) {
                  final log = sendLogs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          _formatTime(log.timestamp),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 10,
                            fontFamily: 'Courier',
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white30,
                          size: 10,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          log.formattedHex,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickCommands(BLEProvider provider) {
    if (provider.currentBLEDevice == null) return const SizedBox.shrink();

    final deviceModel = provider.currentBLEDevice!.displayModel;
    final deviceCommands = provider.commands
        .where((cmd) => cmd.deviceModel == deviceModel)
        .toList();

    // 如果没有找到匹配的指令，显示提示和管理按钮
    if (deviceCommands.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Text(
              '当前设备型号($deviceModel)暂无快捷指令',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/commands');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '管理指令',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 显示匹配的快捷指令
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...deviceCommands.map((cmd) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildQuickCommandChip(cmd.name, cmd.formattedHex),
            );
          }).toList(),
          const SizedBox(width: 8),
          // 添加管理指令按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/commands');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      size: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '管理',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommandChip(String label, String hex) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _sendController.text = hex;
          });
          _sendData();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

// --- UUID Config Dialog ---

class UUIDConfigDialog extends StatefulWidget {
  final bool isSend;
  final List<BluetoothService> services;
  final String? initialServiceUuid;
  final String? initialCharUuid;
  final Function(
    String serviceUuid,
    String charUuid,
    CharacteristicProperties properties,
  )
  onConfirm;

  const UUIDConfigDialog({
    super.key,
    required this.isSend,
    required this.services,
    this.initialServiceUuid,
    this.initialCharUuid,
    required this.onConfirm,
  });

  @override
  State<UUIDConfigDialog> createState() => _UUIDConfigDialogState();
}

class _UUIDConfigDialogState extends State<UUIDConfigDialog> {
  BluetoothService? _selectedService;
  BluetoothCharacteristic? _selectedCharacteristic;

  @override
  void initState() {
    super.initState();
    _initSelection();
  }

  void _initSelection() {
    if (widget.services.isEmpty) return;

    // Try to find initial service
    if (widget.initialServiceUuid != null) {
      try {
        _selectedService = widget.services.firstWhere(
          (s) =>
              s.uuid.toString().toLowerCase() ==
              widget.initialServiceUuid!.toLowerCase(),
        );
      } catch (_) {}
    }

    // Default to first service if not found
    _selectedService ??= widget.services.first;

    // Try to find initial characteristic
    if (_selectedService != null && widget.initialCharUuid != null) {
      try {
        _selectedCharacteristic = _selectedService!.characteristics.firstWhere(
          (c) =>
              c.uuid.toString().toLowerCase() ==
              widget.initialCharUuid!.toLowerCase(),
        );
      } catch (_) {}
    }

    // Default to first char if not found
    if (_selectedCharacteristic == null &&
        _selectedService!.characteristics.isNotEmpty) {
      _selectedCharacteristic = _selectedService!.characteristics.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F2937), // Dark Background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(16),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: Colors.greenAccent),
              const SizedBox(width: 8),
              const Text(
                'UUID 配置',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '服务 UUID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black.withOpacity(0.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BluetoothService>(
                  value: _selectedService,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1F2937),
                  iconEnabledColor: Colors.white70,
                  hint: const Text(
                    '选择服务',
                    style: TextStyle(color: Colors.grey),
                  ),
                  items: widget.services.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.uuid.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedService = val;
                      _selectedCharacteristic = null;
                      if (_selectedService != null &&
                          _selectedService!.characteristics.isNotEmpty) {
                        _selectedCharacteristic =
                            _selectedService!.characteristics.first;
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              '特征 UUID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black.withOpacity(0.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BluetoothCharacteristic>(
                  value: _selectedCharacteristic,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1F2937),
                  iconEnabledColor: Colors.white70,
                  hint: const Text(
                    '选择特征',
                    style: TextStyle(color: Colors.grey),
                  ),
                  items:
                      _selectedService?.characteristics.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.uuid.toString(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (c.properties.read)
                                _buildPropertyTag(
                                  '可读',
                                  _selectedCharacteristic!.properties.read,
                                  Colors.greenAccent,
                                ),
                              if (c.properties.write ||
                                  c.properties.writeWithoutResponse)
                                _buildPropertyTag(
                                  '可写',
                                  c.properties.write ||
                                      c.properties.writeWithoutResponse,
                                  Colors.orangeAccent,
                                ),
                              if (c.properties.notify || c.properties.indicate)
                                _buildPropertyTag(
                                  '通知',
                                  c.properties.notify || c.properties.indicate,
                                  Colors.lightBlueAccent,
                                ),
                            ],
                          ),
                        );
                      }).toList() ??
                      [],
                  onChanged: (val) {
                    setState(() {
                      _selectedCharacteristic = val;
                    });
                  },
                ),
              ),
            ),

            // 显示当前选中特征的详细属性 (Tag Style)
            if (_selectedCharacteristic != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '特征属性:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPropertyTag(
                          '可读',
                          _selectedCharacteristic!.properties.read,
                          Colors.greenAccent,
                        ),
                        _buildPropertyTag(
                          '可写',
                          _selectedCharacteristic!.properties.write ||
                              _selectedCharacteristic!
                                  .properties
                                  .writeWithoutResponse,
                          Colors.orangeAccent,
                        ),
                        _buildPropertyTag(
                          '通知',
                          _selectedCharacteristic!.properties.notify,
                          Colors.lightBlueAccent,
                        ),
                        _buildPropertyTag(
                          '指示',
                          _selectedCharacteristic!.properties.indicate,
                          Colors.purpleAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedService != null && _selectedCharacteristic != null) {
              // 构建属性对象
              final props = CharacteristicProperties(
                canRead: _selectedCharacteristic!.properties.read,
                canWrite:
                    _selectedCharacteristic!.properties.write ||
                    _selectedCharacteristic!.properties.writeWithoutResponse,
                canNotify:
                    _selectedCharacteristic!.properties.notify ||
                    _selectedCharacteristic!.properties.indicate,
              );

              widget.onConfirm(
                _selectedService!.uuid.toString(),
                _selectedCharacteristic!.uuid.toString(),
                props,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981), // Green
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildPropertyTag(String label, bool active, Color color) {
    if (!active) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 特征属性辅助类
class CharacteristicProperties {
  final bool canRead;
  final bool canWrite;
  final bool canNotify;

  CharacteristicProperties({
    required this.canRead,
    required this.canWrite,
    required this.canNotify,
  });
}
