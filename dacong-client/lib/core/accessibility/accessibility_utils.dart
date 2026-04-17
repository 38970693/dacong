import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'accessibility_constants.dart';

/// 无障碍工具类
class AccessibilityUtils {
  AccessibilityUtils._();

  /// 计算颜色对比度
  /// 返回值范围: 1.0 (无对比) 到 21.0 (最大对比)
  static double calculateContrastRatio(Color foreground, Color background) {
    final l1 = _calculateRelativeLuminance(foreground);
    final l2 = _calculateRelativeLuminance(background);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 检查对比度是否符合 WCAG 2.1 AA 标准
  static bool meetsContrastRequirement(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    final minRatio = isLargeText
        ? AccessibilityConstants.minContrastRatioLarge
        : AccessibilityConstants.minContrastRatioNormal;
    return ratio >= minRatio;
  }

  /// 计算相对亮度 (WCAG 2.1 标准)
  static double _calculateRelativeLuminance(Color color) {
    final r = _linearizeColorComponent((color.r * 255.0).round().clamp(0, 255) / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round().clamp(0, 255) / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round().clamp(0, 255) / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// 线性化颜色分量
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  /// 确保触摸目标尺寸符合标准
  static Size ensureMinTouchTargetSize(Size size) {
    return Size(
      math.max(size.width, AccessibilityConstants.minTouchTargetSize),
      math.max(size.height, AccessibilityConstants.minTouchTargetSize),
    );
  }

  /// 检查是否启用了屏幕阅读器
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// 检查是否启用了高对比度模式
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// 获取文本缩放因子
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0);
  }

  /// 检查文本缩放是否在合理范围内 (1.0 - 2.0)
  static bool isTextScaleFactorSupported(BuildContext context) {
    final factor = getTextScaleFactor(context);
    return factor >= 1.0 && factor <= 2.0;
  }

  /// 生成语义标签
  static String generateSemanticLabel({
    required String label,
    String? value,
    String? hint,
  }) {
    final parts = <String>[label];
    if (value != null && value.isNotEmpty) {
      parts.add(value);
    }
    if (hint != null && hint.isNotEmpty) {
      parts.add(hint);
    }
    return parts.join(', ');
  }

  /// 宣布消息给屏幕阅读器
  static void announce(BuildContext context, String message) {
    // 使用 Semantics widget 的方式来宣布消息
    // 在实际使用中，应该通过 Semantics widget 包装来实现
    if (isScreenReaderEnabled(context)) {
      // 可以通过 SnackBar 或其他方式提供反馈
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
