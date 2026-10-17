import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../data/services/backup_scheduler.dart';
import '../features/settings/backup_controller.dart';
import '../features/items/items_page.dart';
import '../features/notes/notes_page.dart';
import '../features/settings/settings_page.dart';
import 'providers.dart';

class WujiApp extends ConsumerStatefulWidget {
  const WujiApp({super.key});

  @override
  ConsumerState<WujiApp> createState() => _WujiAppState();
}

class _WujiAppState extends ConsumerState<WujiApp> {
  BackupScheduler? _scheduler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // 质保提醒排期（无通知权限时静默失败）
    try {
      await ref.read(warrantyReminderServiceProvider).reschedule();
    } catch (_) {
      // ignore
    }
    _scheduler = BackupScheduler(
      settingsReader: () => ref.read(settingsProvider),
      onAutoBackup: (reason) async {
        if (ref.read(activeWebdavConfigProvider) == null) return;
        await ref.read(backupServiceProvider).backup(createSnapshot: false);
        ref.invalidate(backupCenterProvider);
      },
    )..start();
  }

  @override
  void dispose() {
    _scheduler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // Material 组件中文化：日期选择器 / 对话框按钮等跟随系统语言，
      // 中文系统显示「年月日」「取消 / 确定」。
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
      theme: AppTheme.forPreset(settings.themePreset, Brightness.light),
      darkTheme: AppTheme.forPreset(settings.themePreset, Brightness.dark),
      themeMode: settings.themeMode,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeShell(),
    );
  }
}

/// 底部三 Tab：碎碎念（默认）/ 物品台账 / 设置与备份
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          NotesPage(),
          ItemsPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '碎碎念',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '物品台账',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置与备份',
          ),
        ],
      ),
    );
  }
}