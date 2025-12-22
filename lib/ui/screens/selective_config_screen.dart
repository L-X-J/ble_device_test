import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';

/// 选择式收发特征配置界面
/// 支持从已连接设备选择服务和特征，并根据特征属性动态配置
class SelectiveConfigScreen extends StatefulWidget {
  const SelectiveConfigScreen({super.key});

  @override
  State<SelectiveConfigScreen> createState() => _SelectiveConfigScreenState();
}

class _SelectiveConfigScreenState extends State<SelectiveConfigScreen> {
  final _deviceModelController = TextEditingController();
  final _sendServiceController = TextEditingController();
  final _sendCharacteristicController = TextEditingController();
  final _receiveServiceController = TextEditingController();
  final _receiveCharacteristicController = TextEditingController();
  final _notifyServiceController = TextEditingController();
  final _notifyCharacteristicController = TextEditingController();
  BluetoothService? _selectedService;
  BluetoothCharacteristic? _selectedCharacteristic;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing config
    final provider = Provider.of<BLEProvider>(context, listen: false);
    _deviceModelController.text = provider.transceiverConfig.deviceModel ?? '';
    _sendServiceController.text =
        provider.transceiverConfig.sendServiceUuid ?? '';
    _sendCharacteristicController.text =
        provider.transceiverConfig.sendCharacteristicUuid ?? '';
    _receiveServiceController.text =
        provider.transceiverConfig.receiveServiceUuid ?? '';
    _receiveCharacteristicController.text =
        provider.transceiverConfig.receiveCharacteristicUuid ?? '';
    _notifyServiceController.text =
        provider.transceiverConfig.notifyServiceUuid ?? '';
    _notifyCharacteristicController.text =
        provider.transceiverConfig.notifyCharacteristicUuid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BLEProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('特征配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              provider.transceiverConfig.clear();
              provider.saveTransceiverConfig();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已清除所有配置')));
            },
            tooltip: '清除配置',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              provider.transceiverConfig.deviceModel =
                  _deviceModelController.text;
              provider.saveTransceiverConfig();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('配置已保存')));
            },
            tooltip: '保存配置',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.isConnected
          ? _buildConfigBody(provider)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bluetooth_disabled,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('请先连接设备'),
                ],
              ),
            ),
    );
  }

  Widget _buildConfigBody(BLEProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 服务和特征选择区
          _buildSelectionArea(provider),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          // 配置分配区
          _buildConfigAssignment(provider),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          // 当前配置预览
          _buildConfigPreview(provider),
        ],
      ),
    );
  }

  Widget _buildSelectionArea(BLEProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. 设备型号',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deviceModelController,
              decoration: const InputDecoration(
                hintText: '输入设备型号（可选）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '2. 选择服务和特征',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 服务选择
            DropdownButton<BluetoothService>(
              isExpanded: true,
              value: _selectedService,
              hint: const Text('选择服务'),
              items: provider.services.map((service) {
                return DropdownMenuItem(
                  value: service,
                  child: Text(
                    _formatServiceName(service),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (service) {
                setState(() {
                  _selectedService = service;
                  _selectedCharacteristic = null;
                });
              },
            ),
            const SizedBox(height: 4),

            // 特征选择（仅在服务选择后显示）
            if (_selectedService != null)
              DropdownButton<BluetoothCharacteristic>(
                isExpanded: true,
                value: _selectedCharacteristic,
                hint: const Text('选择特征'),
                items: _selectedService!.characteristics.map((characteristic) {
                  return DropdownMenuItem(
                    value: characteristic,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatCharacteristicName(characteristic),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildPropertyIcons(characteristic),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (characteristic) {
                  setState(() {
                    _selectedCharacteristic = characteristic;
                    // 自动缓存特征属性
                    if (characteristic != null) {
                      provider.transceiverConfig.setCharacteristicProperties(
                        _selectedService!.uuid.toString(),
                        characteristic.uuid.toString(),
                        characteristic.properties.read,
                        characteristic.properties.write,
                        characteristic.properties.notify ||
                            characteristic.properties.indicate,
                      );
                    }
                  });
                },
              ),

            if (_selectedCharacteristic != null) ...[
              const SizedBox(height: 8),
              _buildCharacteristicProperties(_selectedCharacteristic!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigAssignment(BLEProvider provider) {
    if (_selectedService == null || _selectedCharacteristic == null) {
      return const SizedBox.shrink();
    }

    final serviceUuid = _selectedService!.uuid.toString();
    final charUuid = _selectedCharacteristic!.uuid.toString();
    final properties = _selectedCharacteristic!.properties;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3. 分配配置',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '将选中的特征分配到以下配置中：',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // 发送配置（需要可写）
            if (properties.write)
              _buildAssignmentButton(
                '📤 发送配置',
                '用于发送数据到设备',
                Icons.send,
                Colors.blue,
                () {
                  provider.transceiverConfig.sendServiceUuid = serviceUuid;
                  provider.transceiverConfig.sendCharacteristicUuid = charUuid;
                  provider.saveTransceiverConfig();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已分配到发送配置')));
                },
              ),

            if (properties.write) const SizedBox(height: 8),

            // 接收配置（需要可读）
            if (properties.read)
              _buildAssignmentButton(
                '📥 接收配置（读取）',
                '用于从设备读取数据',
                Icons.arrow_downward,
                Colors.orange,
                () {
                  provider.transceiverConfig.receiveServiceUuid = serviceUuid;
                  provider.transceiverConfig.receiveCharacteristicUuid =
                      charUuid;
                  provider.saveTransceiverConfig();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已分配到接收配置')));
                },
              ),

            if (properties.read) const SizedBox(height: 8),

            // 通知配置（需要通知属性）
            if (properties.notify || properties.indicate)
              _buildAssignmentButton(
                '🔔 通知配置',
                '用于监听设备主动通知',
                Icons.notifications_active,
                Colors.purple,
                () {
                  provider.transceiverConfig.notifyServiceUuid = serviceUuid;
                  provider.transceiverConfig.notifyCharacteristicUuid =
                      charUuid;
                  provider.saveTransceiverConfig();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已分配到通知配置')));
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _buildConfigPreview(BLEProvider provider) {
    final config = provider.transceiverConfig;

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 8),

            if (config.hasSendConfig)
              _buildPreviewItem(
                '📤 发送',
                config.sendServiceUuid!,
                config.sendCharacteristicUuid!,
                config.canWrite(
                  config.sendServiceUuid!,
                  config.sendCharacteristicUuid!,
                ),
              ),

            if (config.hasReceiveConfig) ...[
              const SizedBox(height: 4),
              _buildPreviewItem(
                '📥 接收（读取）',
                config.receiveServiceUuid!,
                config.receiveCharacteristicUuid!,
                config.canRead(
                  config.receiveServiceUuid!,
                  config.receiveCharacteristicUuid!,
                ),
              ),
            ],

            if (config.hasNotifyConfig) ...[
              const SizedBox(height: 4),
              _buildPreviewItem(
                '🔔 通知',
                config.notifyServiceUuid!,
                config.notifyCharacteristicUuid!,
                config.canNotify(
                  config.notifyServiceUuid!,
                  config.notifyCharacteristicUuid!,
                ),
              ),
            ],

            if (!config.hasSendConfig &&
                !config.hasReceiveConfig &&
                !config.hasNotifyConfig)
              const Text(
                '暂无配置，请选择特征并分配',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(
    String title,
    String serviceUuid,
    String charUuid,
    bool isValid,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            if (!isValid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '属性不匹配',
                  style: TextStyle(fontSize: 9, color: Colors.red[800]),
                ),
              ),
          ],
        ),
        Text(
          '服务: ${_shortenUuid(serviceUuid)}',
          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
        ),
        Text(
          '特征: ${_shortenUuid(charUuid)}',
          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _buildCharacteristicProperties(
    BluetoothCharacteristic characteristic,
  ) {
    final props = characteristic.properties;
    final items = <Widget>[];

    if (props.read) {
      items.add(_buildPropertyChip('可读', Colors.green));
    }
    if (props.write) {
      items.add(_buildPropertyChip('可写', Colors.blue));
    }
    if (props.notify) {
      items.add(_buildPropertyChip('Notify', Colors.purple));
    }
    if (props.indicate) {
      items.add(_buildPropertyChip('Indicate', Colors.purpleAccent));
    }

    return Wrap(spacing: 4, runSpacing: 4, children: items);
  }

  Widget _buildPropertyChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPropertyIcons(BluetoothCharacteristic characteristic) {
    final props = characteristic.properties;
    final icons = <Widget>[];

    if (props.read) {
      icons.add(
        const Icon(Icons.arrow_downward, size: 12, color: Colors.green),
      );
    }
    if (props.write) {
      icons.add(const Icon(Icons.arrow_upward, size: 12, color: Colors.blue));
    }
    if (props.notify) {
      icons.add(
        const Icon(Icons.notifications, size: 12, color: Colors.purple),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  String _formatServiceName(BluetoothService service) {
    final uuid = service.uuid.toString();
    return '服务: ${_shortenUuid(uuid)}';
  }

  String _formatCharacteristicName(BluetoothCharacteristic characteristic) {
    final uuid = characteristic.uuid.toString();
    return '特征: ${_shortenUuid(uuid)}';
  }

  String _shortenUuid(String uuid) {
    if (uuid.length > 8) {
      return '${uuid.substring(0, 8)}...${uuid.substring(uuid.length - 6)}';
    }
    return uuid;
  }
}
