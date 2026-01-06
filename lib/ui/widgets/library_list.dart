import 'package:flutter/material.dart';

/// 项目依赖库列表组件
///
/// 展示pubspec.yaml中的所有依赖库，按类型分类
class LibraryList extends StatelessWidget {
  final List<Map<String, dynamic>> dependencies;

  const LibraryList({super.key, required this.dependencies});

  /// 构建依赖项卡片
  Widget _buildDependencyItem(Map<String, dynamic> dependency) {
    final name = dependency['name'] ?? '';
    final version = dependency['version'] ?? '';
    final type = dependency['type'] ?? 'prod';
    final isPopular = dependency['isPopular'] ?? false;
    final description = dependency['description'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: type == 'prod'
            ? Colors.blue.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: type == 'prod'
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标标识
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: type == 'prod' ? Colors.blue : Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPopular ? Icons.star : Icons.code,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          // 信息区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Text(
                          '流行',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: type == 'prod'
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: type == 'prod'
                              ? Colors.blue.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        type == 'prod' ? '生产依赖' : '开发依赖',
                        style: TextStyle(
                          fontSize: 10,
                          color: type == 'prod' ? Colors.blue : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    version,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Courier',
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (dependencies.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.library_books, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('暂无依赖信息', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 分组显示
    final prodDependencies = dependencies
        .where((d) => d['type'] == 'prod')
        .toList();
    final devDependencies = dependencies
        .where((d) => d['type'] == 'dev')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 生产依赖
        if (prodDependencies.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  '生产依赖 (${prodDependencies.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...prodDependencies.map(
            (dep) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildDependencyItem(dep),
            ),
          ),
        ],

        // 开发依赖
        if (devDependencies.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.build, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  '开发依赖 (${devDependencies.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...devDependencies.map(
            (dep) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildDependencyItem(dep),
            ),
          ),
        ],
      ],
    );
  }
}
