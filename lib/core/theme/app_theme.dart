import 'package:flutter/material.dart';

/// 主题风格预设。
///
/// 需求 3：除默认墨绿外，增加樱花粉 / 天空蓝 / 毛玻璃等配色；
/// 与「主题模式」（跟随系统 / 浅色 / 深色）正交组合。
enum AppThemePreset {
  defaultTheme('default', '默认（墨绿）'),
  sakura('sakura', '樱花粉'),
  sky('sky', '天空蓝'),
  frosted('frosted', '毛玻璃'),
  ink('ink', '墨韵紫');

  const AppThemePreset(this.value, this.label);

  /// 持久化到 shared_preferences 的值（稳定，不随枚举名重命名变化）。
  final String value;
  final String label;

  static AppThemePreset fromValue(String? value) {
    for (final preset in AppThemePreset.values) {
      if (preset.value == value) return preset;
    }
    return AppThemePreset.defaultTheme;
  }
}

/// 简洁卡片风主题，支持多套配色预设 × 深色 / 浅色。
class AppTheme {
  AppTheme._();

  /// 各预设的种子色
  static const Color _defaultSeed = Color(0xFF3F6E6A);

  static ThemeData light() => forPreset(AppThemePreset.defaultTheme, Brightness.light);

  static ThemeData dark() => forPreset(AppThemePreset.defaultTheme, Brightness.dark);

  /// 按预设 + 明暗生成主题。
  static ThemeData forPreset(AppThemePreset preset, Brightness brightness) {
    final seed = switch (preset) {
      AppThemePreset.defaultTheme => _defaultSeed,
      AppThemePreset.sakura => const Color(0xFFF2A0BE),
      AppThemePreset.sky => const Color(0xFF4FA8E8),
      AppThemePreset.frosted => const Color(0xFF8FA8C0),
      AppThemePreset.ink => const Color(0xFF6D6A8D),
    };

    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    // 毛玻璃预设：冷白蓝背景 + 半透明卡片，模拟磨砂质感
    //（真正的实时高斯模糊需 BackdropFilter，主题层以半透明色近似）。
    final Color lightBackground;
    final CardThemeData cardTheme;
    switch (preset) {
      case AppThemePreset.frosted:
        lightBackground = const Color(0xFFEAF0F6);
        cardTheme = CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: brightness == Brightness.light
              ? const Color(0xB3FFFFFF) // 70% 白
              : const Color(0x33FFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        );
      default:
        lightBackground = const Color(0xFFF6F6F4);
        cardTheme = CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
        );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? lightBackground
          : scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: brightness == Brightness.light
            ? lightBackground
            : scheme.surface,
      ),
      cardTheme: cardTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      listTileTheme: const ListTileThemeData(dense: false),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
