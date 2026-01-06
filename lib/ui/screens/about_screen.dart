import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/github_service.dart';
import '../../services/pubspec_service.dart';
import '../widgets/about_section.dart';
import '../widgets/developer_card.dart';
import '../widgets/library_list.dart';

/// About页面 - 展示项目信息和开发者详情
///
/// 功能特性：
/// - 项目概述和技术栈展示
/// - 自动提取pubspec.yaml依赖信息
/// - GitHub API获取开发者资料和统计数据
/// - 响应式布局和深色/浅色模式支持
/// - 流畅的动画效果和加载状态管理
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final GitHubService _githubService = GitHubService();
  final PubspecService _pubspecService = PubspecService();

  bool _isLoading = true;
  String? _errorMessage;

  // 缓存数据
  Map<String, dynamic>? _githubData;
  List<Map<String, dynamic>>? _dependencies;

  // 开发者GitHub用户名 - 可以根据实际情况修改
  static const String _githubUsername = 'L-X-J';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  /// 初始化动画控制器
  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
  }

  /// 加载数据 - 包括GitHub信息和项目依赖
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 并行加载GitHub数据和项目依赖
      final results = await Future.wait([
        _githubService.getUserInfo(_githubUsername),
        _pubspecService.extractDependencies(),
      ]);

      setState(() {
        _githubData = results[0] as Map<String, dynamic>?;
        _dependencies = results[1] as List<Map<String, dynamic>>?;
        _isLoading = false;
      });

      // 启动动画
      _animationController.forward();
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  /// 分享应用信息
  Future<void> _shareAppInfo() async {
    final shareText =
        '''
BLE设备调试工具 - About信息

项目名称: BLE设备调试工具
项目简介: 一个专业的BLE设备调试和管理工具，支持设备扫描、连接、数据传输和指令发送

技术栈:
- Flutter 3.x
- Flutter Blue Plus (BLE库)
- Provider (状态管理)
- Dart 3.x

开发者: $_githubUsername
GitHub: https://github.com/$_githubUsername

感谢使用！
''';

    try {
      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('分享失败: $error')));
      }
    }
  }

  /// 复制GitHub链接到剪贴板
  Future<void> _copyGitHubLink() async {
    final link = 'https://github.com/$_githubUsername';
    await Clipboard.setData(ClipboardData(text: link));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GitHub链接已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 构建错误状态视图
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '数据加载失败',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? '未知错误',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建加载状态视图
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            '正在加载信息...',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            '正在从GitHub获取开发者数据',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 构建主要内容视图
  Widget _buildContentView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            // 顶部间距
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top),
            ),

            // 项目Logo和标题
            SliverToBoxAdapter(child: _buildHeader()),

            // 项目概述部分
            SliverToBoxAdapter(
              child: AboutSection(
                title: '项目概述',
                icon: Icons.info_outline,
                child: _buildProjectOverview(),
              ),
            ),

            // 开发者信息
            if (_githubData != null)
              SliverToBoxAdapter(
                child: AboutSection(
                  title: '开发者信息',
                  icon: Icons.person_outline,
                  child: DeveloperCard(
                    githubData: _githubData!,
                    onCopyLink: _copyGitHubLink,
                  ),
                ),
              ),

            // 操作按钮
            SliverToBoxAdapter(child: _buildActionButtons()),

            // 主要功能
            SliverToBoxAdapter(
              child: AboutSection(
                title: '主要功能',
                icon: Icons.featured_play_list_outlined,
                child: _buildFeaturesList(),
              ),
            ),

            // 技术栈
            SliverToBoxAdapter(
              child: AboutSection(
                title: '技术栈',
                icon: Icons.code,
                child: _buildTechStack(),
              ),
            ),

            // 项目依赖
            if (_dependencies != null && _dependencies!.isNotEmpty)
              SliverToBoxAdapter(
                child: AboutSection(
                  title: '项目依赖',
                  icon: Icons.library_books,
                  child: LibraryList(dependencies: _dependencies!),
                ),
              ),

            // 底部信息
            SliverToBoxAdapter(child: _buildFooter()),

            // 底部间距
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建头部（Logo和标题）
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.bluetooth, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'BLE设备调试工具',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '专业的低功耗蓝牙调试助手',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建项目概述内容
  Widget _buildProjectOverview() {
    return const Text(
      'BLE设备调试工具Pro+是一个专业的移动端调试助手，专为BLE设备开发和测试而设计。'
      '该应用提供了完整的BLE设备管理功能，包括设备扫描、连接管理、数据传输和指令发送等核心功能。'
      '通过简洁现代的UI设计和流畅的用户体验，帮助开发者更高效地进行BLE设备调试工作。',
      style: TextStyle(fontSize: 16, height: 1.6, letterSpacing: 0.3),
    );
  }

  /// 构建功能列表
  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.bluetooth_searching,
        'title': '设备扫描',
        'desc': '自动扫描周边BLE设备，实时显示信号强度',
      },
      {'icon': Icons.link, 'title': '设备连接', 'desc': '支持快速连接和断开，连接状态实时监控'},
      {
        'icon': Icons.data_object,
        'title': '数据传输',
        'desc': '双向数据传输，支持十六进制和文本格式',
      },
      {'icon': Icons.code, 'title': '指令发送', 'desc': '自定义指令模板，快速发送常用命令'},
      {'icon': Icons.save_alt, 'title': '数据导出', 'desc': '支持导出传输记录和设备信息'},
      {'icon': Icons.dark_mode, 'title': '深色模式', 'desc': '完美适配深色/浅色主题，护眼舒适'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: features.map((feature) {
        return Container(
          width: (MediaQuery.of(context).size.width - 90) / 2,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[300]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(feature['icon'] as IconData, color: Colors.blue, size: 24),
              const SizedBox(height: 8),
              Text(
                feature['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feature['desc'] as String,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建技术栈展示
  Widget _buildTechStack() {
    final techStack = [
      {'name': 'Flutter', 'version': '3.x', 'color': Colors.blue},
      {'name': 'Dart', 'version': '3.x', 'color': Colors.cyan},
      {'name': 'Flutter Blue Plus', 'version': '^2.0.2', 'color': Colors.green},
      {'name': 'Provider', 'version': '^6.1.1', 'color': Colors.orange},
      {
        'name': 'Material Design 3',
        'version': 'Latest',
        'color': Colors.purple,
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: techStack.map((tech) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (tech['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (tech['color'] as Color).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tech['name'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tech['color'] as Color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                tech['version'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: (tech['color'] as Color).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _copyGitHubLink,
              icon: const Icon(Icons.link),
              label: const Text('GitHub'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareAppInfo,
              icon: const Icon(Icons.share),
              label: const Text('分享'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部信息
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            '版本 1.0.0+1',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2025 BLE Device Test. All rights reserved.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'Made with Flutter ❤️',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
      appBar: AppBar(
        title: const Text('关于'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
          ? _buildErrorView()
          : _buildContentView(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
