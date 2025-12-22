import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/ble_provider.dart';
import '../../models/ble_command.dart';
import '../../utils/hex_utils.dart';
import '../widgets/gradient_card.dart';

/// 快捷指令管理界面
/// 指令存储、发送、导入导出功能
class CommandsScreen extends StatefulWidget {
  const CommandsScreen({super.key});

  @override
  State<CommandsScreen> createState() => _CommandsScreenState();
}

class _CommandsScreenState extends State<CommandsScreen> {
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  String? _editingId;
  String _filterModel = '全部';

  @override
  void initState() {
    super.initState();
    // 加载指令
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BLEProvider>(context, listen: false).loadCommands();
    });
  }

  @override
  void dispose() {
    _modelController.dispose();
    _nameController.dispose();
    _hexController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  /// 显示编辑/新建指令对话框
  void _showEditDialog({BLECommand? command}) {
    if (command != null) {
      _modelController.text = command.deviceModel;
      _nameController.text = command.name;
      _hexController.text = command.hexContent;
      _remarkController.text = command.remark ?? '';
      _editingId = command.id;
    } else {
      _modelController.clear();
      _nameController.clear();
      _hexController.clear();
      _remarkController.clear();
      _editingId = null;

      // 如果当前连接了设备，自动填充型号
      final provider = Provider.of<BLEProvider>(context, listen: false);
      if (provider.currentBLEDevice != null) {
        _modelController.text = provider.currentBLEDevice!.displayModel;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              command == null ? Icons.add_circle : Icons.edit,
              color: const Color(0xFFA5B4FC),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              command == null ? '新建指令' : '编辑指令',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(
                controller: _modelController,
                label: '设备型号',
                hint: '唯一标识',
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                controller: _nameController,
                label: '指令名称',
                hint: '如：查询状态',
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                controller: _hexController,
                label: 'HEX指令内容',
                hint: '如：AA0102',
                isHex: true,
                onChanged: (value) {
                  // 自动格式化
                  if (value.isNotEmpty && !value.contains(' ')) {
                    if (value.length % 2 == 0 &&
                        RegExp(r'^[0-9A-Fa-f]+$').hasMatch(value)) {
                      _hexController.text = HexUtils.formatHex(value);
                      _hexController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _hexController.text.length),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildDialogTextField(
                controller: _remarkController,
                label: '备注（可选）',
                maxLines: 2,
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
            onPressed: () => _saveCommand(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isHex = false,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: isHex ? TextInputType.text : TextInputType.text,
      textCapitalization: isHex
          ? TextCapitalization.characters
          : TextCapitalization.none,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
        ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
      ),
    );
  }

  /// 保存指令
  Future<void> _saveCommand() async {
    final model = _modelController.text.trim();
    final name = _nameController.text.trim();
    final hex = _hexController.text.trim().replaceAll(' ', '');
    final remark = _remarkController.text.trim();

    if (model.isEmpty || name.isEmpty || hex.isEmpty) {
      _showSnackBar('请填写完整信息');
      return;
    }

    if (!HexUtils.isValidHex(hex)) {
      _showSnackBar('HEX格式无效');
      return;
    }

    final provider = Provider.of<BLEProvider>(context, listen: false);

    final command = BLECommand(
      id:
          _editingId ??
          provider.commands.length.toString() +
              DateTime.now().millisecondsSinceEpoch.toString(),
      deviceModel: model,
      name: name,
      hexContent: hex,
      remark: remark.isEmpty ? null : remark,
      createdAt: DateTime.now(),
    );

    final success = await provider.saveCommand(command);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      _showSnackBar(_editingId == null ? '指令已创建' : '指令已更新');
    } else {
      _showSnackBar('保存失败');
    }
  }

  /// 删除指令
  Future<void> _deleteCommand(String id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.redAccent),
            const SizedBox(width: 8),
            const Text(
              '确认删除',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          '确定要删除这条指令吗？此操作无法撤销。',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final provider = Provider.of<BLEProvider>(context, listen: false);
      final success = await provider.deleteCommand(id);
      if (!mounted) return;
      if (success) {
        _showSnackBar('指令已删除');
      }
    }
  }

  /// 导出指令
  Future<void> _exportCommands() async {
    final provider = Provider.of<BLEProvider>(context, listen: false);
    final result = await provider.exportCommands();
    if (!mounted) return;

    if (result != null) {
      // 显示导出成功的弹窗，提供打开文件位置的选项
      _showExportSuccessDialog(result);
    } else {
      _showSnackBar('没有可导出的指令');
    }
  }

  /// 显示导出成功的对话框
  void _showExportSuccessDialog(Map<String, String> exportInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 8),
            const Text(
              '导出成功',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '文件名: ${exportInfo['fileName']}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              '位置: ${exportInfo['directory']}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '包含内容：指令列表、收发配置、读取配置、设备映射',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Platform.isIOS ? '📱 iOS访问说明:' : '📱 Android访问说明:',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Platform.isIOS
                          ? '1. 使用文件App\n2. 浏览到"我的iPhone"\n3. 找到本应用的文件夹\n4. 查看导出的JSON文件'
                          : '1. 使用文件管理器\n2. 浏览到内部存储\n3. 找到Documents文件夹\n4. 查看导出的JSON文件',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openFileLocation(exportInfo['filePath']!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('打开文件位置'),
          ),
        ],
      ),
    );
  }

  /// 打开文件位置
  Future<void> _openFileLocation(String filePath) async {
    SharePlus.instance.share(
      ShareParams(subject: '分享指令文件', files: [XFile(filePath)]),
    );
  }

  /// 导入指令
  Future<void> _importCommands() async {
    final provider = Provider.of<BLEProvider>(context, listen: false);
    final count = await provider.importCommandsFromFile();
    if (!mounted) return;
    if (count > 0) {
      _showSnackBar('成功导入 $count 条指令');
    }
  }

  /// 显示提示信息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 构建指令列表项
  Widget _buildCommandItem(BLECommand command) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        title: Text(
          command.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '型号: ${command.deviceModel}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              command.formattedHex,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981), // Green
              ),
            ),
            if (command.remark != null && command.remark!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  command.remark!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF3B82F6)),
              onPressed: () => _sendCommandDirectly(command),
              tooltip: '直接发送',
            ),
            IconButton(
              icon: const Icon(Icons.playlist_add, color: Colors.white70),
              onPressed: () => _returnToDataTransmission(command),
              tooltip: '返回到数据传输页面',
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: () => _showEditDialog(command: command),
              tooltip: '编辑',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white30),
              onPressed: () => _deleteCommand(command.id),
              tooltip: '删除',
            ),
          ],
        ),
        onTap: () => _returnToDataTransmission(command),
      ),
    );
  }

  /// 返回到数据传输页面并传递指令数据
  void _returnToDataTransmission(BLECommand command) {
    Navigator.pop(context, {'hex': command.hexContent, 'name': command.name});
  }

  /// 直接发送指令
  Future<void> _sendCommandDirectly(BLECommand command) async {
    final provider = Provider.of<BLEProvider>(context, listen: false);

    // 检查是否连接设备和配置发送特征
    if (!provider.isConnected) {
      _showGlobalSnackBar('请先连接设备', isError: true);
      return;
    }

    if (!provider.transceiverConfig.hasSendConfig) {
      _showGlobalSnackBar('请先配置发送特征', isError: true);
      return;
    }

    try {
      await provider.sendWithConfig(command.hexContent);
      _showGlobalSnackBar('✅ 指令 "${command.name}" 发送成功', isError: false);
    } catch (e) {
      // 清理错误信息，移除换行符以便在SnackBar中显示
      String errorMsg = e.toString().replaceAll('\n', ' | ');
      _showGlobalSnackBar('❌ 发送失败: $errorMsg', isError: true);
    }
  }

  /// 显示全局提示（在当前页面）
  void _showGlobalSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 构建过滤器
  Widget _buildFilter(BLEProvider provider) {
    final models = provider.commands
        .map((cmd) => cmd.deviceModel)
        .toSet()
        .toList();
    models.sort();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          const Text(
            '过滤: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterModel,
                  dropdownColor: const Color(0xFF1F2937),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white70,
                  ),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: ['全部', ...models].map((model) {
                    return DropdownMenuItem(value: model, child: Text(model));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterModel = value ?? '全部';
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            size: 64,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无快捷指令',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮新建指令',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计信息
  Widget _buildStats(BLEProvider provider) {
    final total = provider.commands.length;
    final models = provider.commands
        .map((cmd) => cmd.deviceModel)
        .toSet()
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: GradientCard(
              colors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              child: Column(
                children: [
                  Text(
                    total.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '总指令',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GradientCard(
              colors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
              child: Column(
                children: [
                  Text(
                    models.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '设备型号',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '快捷指令',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA5B4FC),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.upload, color: Colors.white70),
              onPressed: _exportCommands,
              tooltip: '导出指令',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white70),
              onPressed: _importCommands,
              tooltip: '导入指令',
            ),
          ),
        ],
      ),
      body: Consumer<BLEProvider>(
        builder: (context, provider, child) {
          // 过滤指令
          final filteredCommands = _filterModel == '全部'
              ? provider.commands
              : provider.commands
                    .where((cmd) => cmd.deviceModel == _filterModel)
                    .toList();

          return Column(
            children: [
              // 统计信息
              _buildStats(provider),

              // 过滤器
              _buildFilter(provider),

              // 指令列表
              Expanded(
                child: filteredCommands.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredCommands.length,
                        itemBuilder: (context, index) {
                          return _buildCommandItem(filteredCommands[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新建指令'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
    );
  }
}
