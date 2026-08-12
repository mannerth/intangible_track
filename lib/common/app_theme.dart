import 'package:flutter/material.dart';

/// 设计稿中的颜色（非遗方舟）
abstract final class AppColors {
  /// 页面背景
  static const Color background = Color(0xFFFFFCF4);

  /// 顶部奶油色装饰区
  static const Color header = Color(0xFFFDF5E1);

  /// 品牌主色（朱砂橙）
  static const Color accent = Color(0xFFD27650);

  /// 底部导航选中态高亮
  static const Color tabHighlight = Color(0xFFFFF5DB);

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF515151);
  static const Color textHint = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color white = Color(0xFFFFFFFF);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.background,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'PingFang SC',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
