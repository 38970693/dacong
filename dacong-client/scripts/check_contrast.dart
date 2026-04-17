import 'dart:io';
import 'package:flutter/material.dart';
import '../lib/core/accessibility/accessibility_utils.dart';

/// 颜色对比度检查脚本
/// 用于验证应用中的颜色组合是否符合 WCAG 2.1 AA 标准
void main() {
  print('=== DaCong 无障碍颜色对比度检查 ===\n');

  // 定义应用中使用的颜色组合
  final colorCombinations = [
    ColorCombination(
      name: '主题色 - 白色背景',
      foreground: Colors.blue,
      background: Colors.white,
      isLargeText: false,
    ),
    ColorCombination(
      name: '主题色容器 - 主题色文字',
      foreground: Colors.blue,
      background: Colors.blue.withValues(alpha: 0.2),
      isLargeText: false,
    ),
    ColorCombination(
      name: '灰色文字 - 白色背景',
      foreground: Colors.grey[700]!,
      background: Colors.white,
      isLargeText: false,
    ),
    ColorCombination(
      name: '绿色标签 - 白色背景',
      foreground: Colors.green,
      background: Colors.white,
      isLargeText: false,
    ),
    ColorCombination(
      name: '橙色标签 - 白色背景',
      foreground: Colors.orange,
      background: Colors.white,
      isLargeText: false,
    ),
    ColorCombination(
      name: '红色标签 - 白色背景',
      foreground: Colors.red,
      background: Colors.white,
      isLargeText: false,
    ),
    ColorCombination(
      name: '琥珀色标签 - 白色背景',
      foreground: Colors.amber,
      background: Colors.white,
      isLargeText: false,
    ),
    ColorCombination(
      name: '白色文字 - 蓝色背景',
      foreground: Colors.white,
      background: Colors.blue,
      isLargeText: false,
    ),
    ColorCombination(
      name: '黑色文字 - 白色背景',
      foreground: Colors.black,
      background: Colors.white,
      isLargeText: false,
    ),
    ColorCombination(
      name: '标题文字 (大) - 白色背景',
      foreground: Colors.black,
      background: Colors.white,
      isLargeText: true,
    ),
    ColorCombination(
      name: '绿色芯片文字 - 绿色背景',
      foreground: Colors.green,
      background: Colors.green.withValues(alpha: 0.1),
      isLargeText: false,
    ),
    ColorCombination(
      name: '橙色芯片文字 - 橙色背景',
      foreground: Colors.orange,
      background: Colors.orange.withValues(alpha: 0.1),
      isLargeText: false,
    ),
    ColorCombination(
      name: '红色芯片文字 - 红色背景',
      foreground: Colors.red,
      background: Colors.red.withValues(alpha: 0.1),
      isLargeText: false,
    ),
    ColorCombination(
      name: '蓝色芯片文字 - 蓝色背景',
      foreground: Colors.blue,
      background: Colors.blue.withValues(alpha: 0.1),
      isLargeText: false,
    ),
  ];

  int passCount = 0;
  int failCount = 0;
  final failures = <String>[];

  for (final combination in colorCombinations) {
    final ratio = AccessibilityUtils.calculateContrastRatio(
      combination.foreground,
      combination.background,
    );

    final meetsRequirement = AccessibilityUtils.meetsContrastRequirement(
      combination.foreground,
      combination.background,
      isLargeText: combination.isLargeText,
    );

    final minRatio = combination.isLargeText ? 3.0 : 4.5;
    final status = meetsRequirement ? '✓ 通过' : '✗ 失败';
    final textSize = combination.isLargeText ? '大文本' : '普通文本';

    print('${combination.name} ($textSize)');
    print('  对比度: ${ratio.toStringAsFixed(2)}:1');
    print('  要求: ≥ $minRatio:1');
    print('  状态: $status\n');

    if (meetsRequirement) {
      passCount++;
    } else {
      failCount++;
      failures.add(combination.name);
    }
  }

  print('=== 检查结果 ===');
  print('总计: ${colorCombinations.length} 个颜色组合');
  print('通过: $passCount');
  print('失败: $failCount');

  if (failures.isNotEmpty) {
    print('\n未通过的颜色组合:');
    for (final failure in failures) {
      print('  - $failure');
    }
    print('\n建议: 调整这些颜色组合以提高对比度');
    exit(1);
  } else {
    print('\n🎉 所有颜色组合均符合 WCAG 2.1 AA 标准！');
    exit(0);
  }
}

/// 颜色组合
class ColorCombination {
  final String name;
  final Color foreground;
  final Color background;
  final bool isLargeText;

  ColorCombination({
    required this.name,
    required this.foreground,
    required this.background,
    required this.isLargeText,
  });
}
