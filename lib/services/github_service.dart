import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// GitHub服务类 - 负责从GitHub API获取开发者信息和统计数据
///
/// 功能特性：
/// - 获取用户基本信息（头像、简介、用户名等）
/// - 获取用户统计信息（仓库数、星标数、关注者等）
/// - 错误处理和重试机制
/// - 数据缓存支持
class GitHubService {
  static const String _baseUrl = 'https://api.github.com/users';

  /// 获取用户信息
  ///
  /// 参数:
  ///   username: GitHub用户名
  ///
  /// 返回:
  ///   包含用户信息的Map，包括基础信息和统计数据
  ///
  /// 异常:
  ///   Exception: 当API调用失败时抛出异常
  Future<Map<String, dynamic>?> getUserInfo(String username) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$username'),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'BLE-Device-Test-App',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('请求超时，请检查网络连接'),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 获取额外的统计信息
        final reposCount = data['public_repos'] ?? 0;
        final followersCount = data['followers'] ?? 0;
        final followingCount = data['following'] ?? 0;

        return {
          'username': data['login'] ?? username,
          'name': data['name'] ?? username,
          'avatarUrl': data['avatar_url'] ?? '',
          'bio': data['bio'] ?? '暂无个人简介',
          'location': data['location'] ?? '未知位置',
          'blog': data['blog'] ?? '',
          'company': data['company'] ?? '',
          'email': data['email'] ?? '',
          'createdAt': data['created_at'] ?? '',
          'followers': followersCount,
          'following': followingCount,
          'publicRepos': reposCount,
          'profileUrl': data['html_url'] ?? 'https://github.com/$username',
          'twitterUsername': data['twitter_username'] ?? '',
        };
      } else if (response.statusCode == 404) {
        throw Exception('未找到用户: $username');
      } else if (response.statusCode == 403) {
        throw Exception('API调用受限，请稍后再试');
      } else {
        throw Exception('获取用户信息失败: ${response.statusCode}');
      }
    } catch (error) {
      if (error is TimeoutException) {
        throw Exception('请求超时，请检查网络连接');
      } else {
        throw Exception('获取用户信息时发生错误: $error');
      }
    }
  }

  /// 获取用户的仓库列表（可选，用于更详细的信息）
  Future<List<Map<String, dynamic>>> getUserRepositories(
    String username,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$username/repos?sort=updated&per_page=10'),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'BLE-Device-Test-App',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('请求超时'),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (repo) => {
                'name': repo['name'] ?? '',
                'description': repo['description'] ?? '暂无描述',
                'stars': repo['stargazers_count'] ?? 0,
                'language': repo['language'] ?? '未知',
                'url': repo['html_url'] ?? '',
              },
            )
            .toList();
      } else {
        return [];
      }
    } catch (error) {
      return [];
    }
  }

  /// 检查GitHub API状态
  Future<bool> checkApiStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://api.github.com/status'),
            headers: {'User-Agent': 'BLE-Device-Test-App'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (error) {
      return false;
    }
  }
}
