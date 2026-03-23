# BLE Device Manager

iOS Test Flight: https://testflight.apple.com/join/H9Tr7QFh

[![Flutter](https://img.shields.io/badge/Flutter-3.38.4-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-green.svg)](https://flutter.dev/docs)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个基于Flutter开发的多平台BLE设备管理应用，支持设备扫描、连接、数据收发和快捷指令管理。

> 🚀 **项目特色**: 完整的BLE设备管理解决方案，支持HEX数据格式、快捷指令管理、多平台兼容

## 功能特性

### 1. 核心功能架构
- ✅ BLE设备扫描、连接、指令读写和数据监听功能
- ✅ 数据收发页面采用单页面设计，顶部为数据接收区，底部为指令发送区
- ✅ 支持服务和UUID选择功能

### 2. 数据展示规范
- ✅ 发送数据仅支持HEX格式，并实现美化展示（如AA0102显示为AA 01 02）
- ✅ 接收数据根据端点特性区分：
  - Notify端点：实时监听并展示数据集合
  - Read端点：提供两种读取方式：
    - 手动点击读取
    - 定时读取（可设置周期如3秒）

### 3. 设备管理界面
- ✅ 展示完整的设备广播信息，包括所有ADV数据
- ✅ 实现设备型号唯一性管理

### 4. 快捷指令功能
- ✅ 提供指令存储功能，包含字段：
  - 设备型号（唯一标识）
  - 指令名称
  - HEX指令内容
  - 备注（可选）
- ✅ 实现快捷发送面板：
  - 弹窗展示型号和指令名称
  - 点击后自动填充到发送输入框
- ✅ 支持指令集的JSON格式导入导出

### 5. 技术实现要求
- ✅ 使用Flutter框架开发（通过fvm管理Flutter版本）
- ✅ 采用响应式设计支持多平台
- ✅ 实现炫酷的UI效果

## 项目架构

```
ble_device_test/
├── lib/                          # Dart/Flutter 源代码
│   ├── main.dart                 # 应用入口
│   ├── models/                   # 数据模型
│   │   ├── ble_device.dart       # BLE设备模型
│   │   ├── ble_command.dart      # 指令模型
│   │   └── data_transmission.dart # 数据传输模型
│   ├── services/                 # 业务服务层
│   │   ├── ble_service.dart      # BLE核心服务
│   │   ├── command_service.dart  # 指令管理服务
│   │   └── data_manager_service.dart # 数据管理服务
│   ├── providers/                # 状态管理层
│   │   └── ble_provider.dart     # BLE状态管理器
│   ├── ui/                       # 用户界面层
│   │   ├── theme/                # 主题配置
│   │   │   └── app_theme.dart
│   │   └── screens/              # 页面组件
│   │       ├── device_management_screen.dart    # 设备管理
│   │       ├── data_transmission_screen.dart    # 数据收发
│   │       └── commands_screen.dart             # 指令管理
│   └── utils/                    # 工具类
│       └── hex_utils.dart        # HEX处理工具
├── android/                      # Android 原生配置
│   ├── app/                      # 应用模块
│   ├── gradle/                   # Gradle配置
│   └── local.properties          # 本地配置（已忽略）
├── ios/                          # iOS 原生配置
│   ├── Flutter/                  # Flutter桥接
│   ├── Pods/                     # CocoaPods依赖
│   └── Runner.xcodeproj/         # Xcode项目
├── .fvm/                         # FVM版本管理
│   ├── flutter_sdk -> versions/3.38.4
│   └── versions/                 # Flutter版本（已忽略）
├── .vscode/                      # VS Code配置
├── .idea/                        # IntelliJ/Android Studio配置
├── build/                        # 构建输出（已忽略）
├── pubspec.yaml                  # Flutter依赖配置
├── README.md                     # 项目文档
├── .gitignore                    # Git忽略配置
└── analysis_options.yaml         # Dart代码分析配置
```

### 关键配置文件说明

- **pubspec.yaml**: Flutter项目依赖和配置
- **.gitignore**: 已配置忽略敏感文件、构建产物和本地配置
- **android/local.properties**: 包含签名配置（已忽略）
- **.fvm/versions/**: Flutter版本缓存（已忽略）

## 核心依赖包

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # BLE核心功能
  flutter_blue_plus: ^1.30.0      # 蓝牙低功耗功能
  
  # 状态管理
  provider: ^6.1.1                # 状态管理解决方案
  
  # 数据持久化
  shared_preferences: ^2.2.2      # 本地存储
  path_provider: ^2.1.1           # 文件路径获取
  
  # 文件操作
  file_picker: ^6.1.1             # 文件选择器
  
  # UI组件
  fluttertoast: ^8.2.4            # Toast通知
  uuid: ^4.2.1                    # UUID生成
  
  # 数据序列化
  json_annotation: ^4.8.1         # JSON注解

dev_dependencies:
  build_runner: ^2.4.0            # 代码生成
  json_serializable: ^6.7.1       # JSON序列化生成
  flutter_lints: ^2.0.0           # 代码规范
```

### 可选依赖（根据平台）
- **share_plus**: ^7.0.0 - 分享功能
- **device_info_plus**: ^9.0.0 - 设备信息
- **permission_handler**: ^11.0.0 - 权限管理

## 使用说明

### 1. 设备管理
1. 打开应用，进入设备管理页面
2. 点击"开始扫描"搜索附近的BLE设备
3. 选择设备进行连接
4. 设置设备型号（用于快捷指令管理）

### 2. 数据收发
1. 连接设备后，进入数据收发页面
2. 选择服务和特征UUID
3. 发送数据：在底部输入HEX数据并发送
4. 接收数据：
   - Notify端点：自动监听并显示
   - Read端点：手动点击读取或设置定时读取

### 3. 快捷指令
1. 在数据收发页面点击"快捷指令"按钮
2. 新建指令：填写型号、名称、HEX内容和备注
3. 使用指令：在快捷指令面板点击指令，自动填充到发送框
4. 导入导出：支持JSON格式的指令集管理

## 开发环境要求

### 环境配置
- **Flutter**: 3.38.4 (通过 FVM 管理)
- **Dart**: >= 2.19.0
- **平台支持**: iOS 12.0+, Android 5.0+, Windows, macOS, Linux

### 开发工具
- **推荐**: VS Code + Flutter插件
- **备选**: Android Studio / IntelliJ IDEA
- **版本管理**: FVM (Flutter Version Management)

### 快速开始

1. **环境准备**
   ```bash
   # 安装 FVM (如果未安装)
   dart pub global activate fvm

   # 切换到项目目录
   cd ble_device_test

   # 使用项目指定的 Flutter 版本
   fvm flutter --version
   ```

2. **安装依赖**
   ```bash
   # 设置代理（国内用户可选）
   export https_proxy=http://127.0.0.1:7890
   export http_proxy=http://127.0.0.1:7890
   export all_proxy=socks5://127.0.0.1:7890

   # 安装依赖
   fvm flutter pub get
   ```

3. **生成代码**
   ```bash
   # 生成 JSON 序列化代码
   fvm flutter pub run build_runner build --delete-conflicting-outputs

   # 或者使用 watch 模式（开发时推荐）
   fvm flutter pub run build_runner watch --delete-conflicting-outputs
   ```

4. **运行应用**
   ```bash
   # 运行在连接的设备/模拟器
   fvm flutter run

   # 指定设备运行
   fvm flutter run -d <device_id>

   # 查看可用设备
   fvm flutter devices
   ```

5. **代码质量检查**
   ```bash
   # 静态分析
   fvm flutter analyze .

   # 格式化代码
   fvm flutter format .

   # 运行测试
   fvm flutter test
   ```

### 构建发布版本

```bash
# Android APK
fvm flutter build apk --release

# Android App Bundle
fvm flutter build appbundle --release

# iOS (需要 macOS)
fvm flutter build ios --release

# macOS (需要 macOS)
fvm flutter build macos --release
```

### 开发工作流

```bash
# 1. 拉取代码后
git clone git@github.com:L-X-J/ble_device_test.git
cd ble_device_test
fvm flutter pub get

# 2. 开发过程中
fvm flutter pub run build_runner watch  # 自动生成代码
fvm flutter run                         # 运行应用

# 3. 提交代码前
fvm flutter analyze .                   # 代码分析
fvm flutter test                        # 运行测试
flutter format .                        # 格式化代码
```

## 项目配置

### 权限配置

#### Android
在 `android/app/src/main/AndroidManifest.xml` 中添加：
```xml
<!-- 蓝牙权限 -->
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Android 12+ 需要额外权限 -->
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
```

#### iOS
在 `ios/Runner/Info.plist` 中添加：
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限来扫描和连接BLE设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要蓝牙权限来与BLE设备通信</string>
```

### 签名配置（发布应用）

#### Android
在 `android/local.properties` 中配置（已忽略）：
```properties
sdk.dir=/path/to/android/sdk
flutter.sdk=/path/to/flutter
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
PackageSignature.storePassword=your_store_password
PackageSignature.keyPassword=your_key_password
PackageSignature.keyAlias=your_key_alias
PackageSignature.storeFile=/path/to/your_keystore.jks
```

#### iOS
在 Xcode 中配置 Signing & Capabilities。

## 常见问题

### Q: 无法扫描到BLE设备？
**A**: 
1. 检查设备蓝牙是否开启
2. 确认应用有蓝牙权限
3. Android 6.0+ 需要动态位置权限
4. iOS 需要在设置中允许蓝牙访问

### Q: 构建时出现依赖冲突？
**A**:
```bash
# 清理缓存
fvm flutter clean
fvm flutter pub cache repair

# 重新安装依赖
fvm flutter pub get
```

### Q: JSON序列化代码未生成？
**A**:
```bash
# 确保在项目根目录执行
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

### Q: FVM 版本不一致？
**A**:
```bash
# 查看当前项目使用的 Flutter 版本
cat .fvm/flutter_sdk/version

# 切换到正确版本
fvm use 3.38.4
```

## 性能优化建议

1. **BLE扫描优化**:
   - 设置合理的扫描超时时间
   - 使用过滤器减少设备列表
   - 及时停止扫描以节省电量

2. **数据处理优化**:
   - 使用流(Stream)处理实时数据
   - 避免在UI线程进行耗时操作
   - 合理使用缓存机制

3. **内存管理**:
   - 及时释放BLE连接
   - 避免内存泄漏
   - 使用`dispose()`清理资源

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 代码规范
- 遵循 [Flutter 官方代码风格](https://flutter.dev/docs/development/tools/formatting)
- 使用 `flutter analyze` 检查代码质量
- 添加必要的文档注释
- 编写单元测试

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系方式

- **项目地址**: https://github.com/L-X-J/ble_device_test
- **问题反馈**: 请在 GitHub Issues 中提交

## 致谢

- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus) - BLE核心功能
- [Provider](https://pub.dev/packages/provider) - 状态管理
- [Flutter 社区](https://flutter.dev/) - 强大的跨平台框架

---

**重要提示**: 
- 本项目使用 FVM 管理 Flutter 版本，确保团队开发环境一致性
- 敏感信息（如签名文件、本地配置）已通过 `.gitignore` 排除
- 发布前请确保已正确配置所有权限和签名信息