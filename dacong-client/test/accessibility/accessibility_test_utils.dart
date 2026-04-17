import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/core/accessibility/accessibility_utils.dart';
import 'package:dacong_client/core/accessibility/accessibility_constants.dart';

/// 无障碍测试工具类
class AccessibilityTestUtils {
  AccessibilityTestUtils._();

  /// 检查 Widget 是否有语义标签
  static void expectHasSemanticLabel(WidgetTester tester, Finder finder) {
    final semantics = tester.getSemantics(finder);
    expect(
      semantics.label,
      isNotNull,
      reason: 'Widget should have a semantic label',
    );
    expect(
      semantics.label.isNotEmpty,
      isTrue,
      reason: 'Semantic label should not be empty',
    );
  }

  /// 检查按钮是否可访问
  static void expectButtonAccessible(WidgetTester tester, Finder finder) {
    // 检查是否有语义标签
    expectHasSemanticLabel(tester, finder);

    // 检查是否可点击（通过检查是否有 InkWell 或 GestureDetector）
    final hasInkWell = find.ancestor(
      of: finder,
      matching: find.byType(InkWell),
    ).evaluate().isNotEmpty;

    final hasGestureDetector = find.ancestor(
      of: finder,
      matching: find.byType(GestureDetector),
    ).evaluate().isNotEmpty;

    expect(
      hasInkWell || hasGestureDetector,
      isTrue,
      reason: 'Button should be tappable',
    );
  }

  /// 检查触摸目标尺寸
  static void expectMinTouchTargetSize(WidgetTester tester, Finder finder) {
    final size = tester.getSize(finder);
    expect(
      size.width >= AccessibilityConstants.minTouchTargetSize,
      isTrue,
      reason: 'Width should be at least ${AccessibilityConstants.minTouchTargetSize}',
    );
    expect(
      size.height >= AccessibilityConstants.minTouchTargetSize,
      isTrue,
      reason: 'Height should be at least ${AccessibilityConstants.minTouchTargetSize}',
    );
  }

  /// 检查颜色对比度
  static void expectMeetsContrastRequirement(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final meetsRequirement = AccessibilityUtils.meetsContrastRequirement(
      foreground,
      background,
      isLargeText: isLargeText,
    );
    final ratio = AccessibilityUtils.calculateContrastRatio(
      foreground,
      background,
    );
    final minRatio = isLargeText
        ? AccessibilityConstants.minContrastRatioLarge
        : AccessibilityConstants.minContrastRatioNormal;

    expect(
      meetsRequirement,
      isTrue,
      reason: 'Contrast ratio $ratio:1 should meet minimum requirement of $minRatio:1',
    );
  }

  /// 检查是否支持键盘导航
  static Future<void> expectSupportsKeyboardNavigation(
    WidgetTester tester,
    Finder finder,
  ) async {
    // 聚焦元素
    await tester.tap(finder);
    await tester.pumpAndSettle();

    // 检查是否可以接收焦点
    final focusNode = tester.widget<Focus>(
      find.ancestor(
        of: finder,
        matching: find.byType(Focus),
      ),
    ).focusNode;

    expect(
      focusNode?.hasFocus,
      isTrue,
      reason: 'Widget should be focusable',
    );
  }

  /// 检查文本是否可缩放
  static void expectTextScalable(WidgetTester tester, Finder finder) {
    final textWidget = tester.widget<Text>(finder);
    // 检查是否使用了 textScaler 而不是固定的 textScaleFactor
    expect(
      textWidget.textScaler,
      isNull,
      reason: 'Text should not have fixed textScaler',
    );
  }

  /// 检查图片是否有语义标签
  static void expectImageHasSemanticLabel(WidgetTester tester, Finder finder) {
    final semantics = tester.getSemantics(finder);
    expect(
      semantics.label,
      isNotNull,
      reason: 'Image should have semantic label for screen readers',
    );
  }

  /// 检查列表项是否可访问
  static void expectListItemAccessible(WidgetTester tester, Finder finder) {
    expectHasSemanticLabel(tester, finder);
    expectMinTouchTargetSize(tester, finder);
  }

  /// 运行完整的无障碍检查
  static Future<void> runFullAccessibilityCheck(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: widget,
        ),
      ),
    );

    // 检查所有按钮
    final buttons = find.byType(ElevatedButton);
    for (var i = 0; i < buttons.evaluate().length; i++) {
      final button = buttons.at(i);
      expectButtonAccessible(tester, button);
      expectMinTouchTargetSize(tester, button);
    }

    // 检查所有文本
    final texts = find.byType(Text);
    for (var i = 0; i < texts.evaluate().length; i++) {
      final text = texts.at(i);
      expectTextScalable(tester, text);
    }

    // 检查所有图片
    final images = find.byType(Image);
    for (var i = 0; i < images.evaluate().length; i++) {
      final image = images.at(i);
      expectImageHasSemanticLabel(tester, image);
    }
  }
}
