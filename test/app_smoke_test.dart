import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuji_suinian/app/app.dart';
import 'package:wuji_suinian/app/providers.dart';
import 'package:wuji_suinian/core/paths/app_paths.dart';
import 'package:wuji_suinian/data/db/database.dart';
import 'package:wuji_suinian/data/services/notification_service.dart';
import 'package:wuji_suinian/data/services/secure_store.dart';
import 'package:wuji_suinian/data/services/settings_store.dart';
import 'package:wuji_suinian/features/items/item_form_page.dart';
import 'package:wuji_suinian/features/settings/settings_page.dart';

/// 界面冒烟测试：验证 App 能本地启动、三大 Tab 可用、核心写入链路通畅。
///
/// 数据库使用内存 SQLite（前台连接）：生产环境的 `createInBackground`
/// 依赖 isolate 消息，在 widget 测试的 fake-async 里不可达，会导致
/// 界面永远停在 loading。内存库查询走微任务，`pump` 即可推进。
void main() {
  late Directory root;
  late AppPaths paths;
  late AppDatabase db;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wuji_widget_');
    paths = AppPaths(rootDir: root);
    await paths.ensure();
    db = AppDatabase.memory();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await db.close();
    try {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    } catch (_) {
      // Windows 下句柄可能延迟释放；临时目录交给系统清理即可。
    }
  });

  Future<Widget> buildApp() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        appPathsProvider.overrideWithValue(paths),
        settingsStoreProvider.overrideWithValue(SettingsStore(prefs)),
        secureStoreProvider.overrideWithValue(MemorySecureStore()),
        notificationServiceProvider
            .overrideWithValue(const NoopNotificationService()),
        databaseProvider.overrideWith(() => _MemoryDbNotifier(db)),
      ],
      child: const WujiApp(),
    );
  }

  /// 等待内存数据库微任务与真实文件 I/O（目录扫描等）完成，并推完路由动画。
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  /// 卸载界面，释放 BackupScheduler 定时器。
  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  /// 长列表是懒构建的，视口外的子项不会出现在元素树里；
  /// 断言前先把目标滚动到可见。
  Future<void> scrollTo(
    WidgetTester tester,
    Finder target,
    Finder scrollable,
  ) async {
    await tester.scrollUntilVisible(target, 400, scrollable: scrollable);
    await tester.pump();
  }

  testWidgets('启动后默认是碎碎念首页，底部三个 Tab 就绪', (tester) async {
    await tester.pumpWidget(await buildApp());
    await settle(tester);

    expect(find.text('碎碎念'), findsWidgets);
    expect(find.text('物品台账'), findsOneWidget);
    expect(find.text('设置与备份'), findsOneWidget);
    expect(find.text('还没有碎念'), findsOneWidget);
    // 输入框常驻底部
    expect(find.text('随手记一条…'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('底部输入框发送一条碎念后聊天流出现该条记录', (tester) async {
    await tester.pumpWidget(await buildApp());
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, '买牛奶');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await settle(tester);

    expect(find.text('买牛奶'), findsOneWidget);
    expect(find.text('还没有碎念'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('物品台账：空状态、新增物品表单保存后回到列表', (tester) async {
    await tester.pumpWidget(await buildApp());
    await settle(tester);

    await tester.tap(find.text('物品台账'));
    await settle(tester);
    expect(find.text('还没有物品'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    // 名称输入框在表单顶部，先填写再滚动
    await tester.enterText(find.byType(TextFormField).first, '博世电钻 GSB120');
    await tester.pump();

    // 保存按钮在懒加载列表底部，需要滚动到可见。
    // （表单内还有图片选择器等横向滚动区，取遍历顺序第一个即主列表）
    final formScrollable = find
        .descendant(
          of: find.byType(ItemFormPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await scrollTo(
      tester,
      find.widgetWithText(FilledButton, '保存物品'),
      formScrollable,
    );
    await tester.tap(find.widgetWithText(FilledButton, '保存物品'));
    await settle(tester);

    expect(find.text('博世电钻 GSB120'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('设置页展示主题、备份与存储入口', (tester) async {
    await tester.pumpWidget(await buildApp());
    await settle(tester);

    await tester.tap(find.text('设置与备份'));
    await settle(tester);

    expect(find.text('主题'), findsOneWidget);
    expect(find.text('WebDAV 配置'), findsOneWidget);
    expect(find.text('备份中心'), findsOneWidget);

    // 底部入口在懒加载列表视口外，滚动到可见后再断言
    final settingsScrollable = find.descendant(
      of: find.byType(SettingsPage),
      matching: find.byType(Scrollable),
    );
    await scrollTo(tester, find.text('存储统计与清理'), settingsScrollable);
    expect(find.text('存储统计与清理'), findsOneWidget);

    await scrollTo(tester, find.text('一键清空全部数据'), settingsScrollable);
    expect(find.text('一键清空全部数据'), findsOneWidget);

    await disposeApp(tester);
  });
}

/// 直接返回注入的内存数据库，不经过文件连接。
class _MemoryDbNotifier extends DatabaseNotifier {
  _MemoryDbNotifier(this._db);

  final AppDatabase _db;

  @override
  AppDatabase build() => _db;
}
