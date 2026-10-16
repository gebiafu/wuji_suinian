import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/paths/app_paths.dart';
import 'data/services/notification_service.dart';
import 'data/services/secure_store.dart';
import 'data/services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全离线启动：只准备本地目录与本地存储，不发起任何网络请求。
  final paths = await AppPaths.resolve();
  final prefs = await SharedPreferences.getInstance();

  final notifications = LocalNotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        appPathsProvider.overrideWithValue(paths),
        settingsStoreProvider.overrideWithValue(SettingsStore(prefs)),
        secureStoreProvider.overrideWithValue(FlutterSecureStore()),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const WujiApp(),
    ),
  );
}