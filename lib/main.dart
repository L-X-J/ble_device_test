import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ble_provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/device_management_screen.dart';
import 'ui/screens/data_transmission_screen.dart';
import 'ui/screens/commands_screen.dart';
import 'ui/screens/about_screen.dart';

void main() {
  runApp(const BLEDeviceManagerApp());
}

/// BLE设备管理应用主入口
class BLEDeviceManagerApp extends StatelessWidget {
  const BLEDeviceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BLEProvider())],
      child: MaterialApp(
        title: 'BLE设备管理器',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // 强制使用暗色主题以匹配新的UI风格
        initialRoute: '/',
        routes: {
          '/': (context) => const DeviceManagementScreen(),
          '/data_transmission': (context) => const DataTransmissionScreen(),
          '/commands': (context) => const CommandsScreen(),
          '/about': (context) => const AboutScreen(),
        },
        onGenerateRoute: (settings) {
          // 可以在这里添加更复杂的路由逻辑
          return null;
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) =>
                const Scaffold(body: Center(child: Text('页面未找到'))),
          );
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
