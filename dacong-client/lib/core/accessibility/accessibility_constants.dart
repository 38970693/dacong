/// 无障碍常量定义
class AccessibilityConstants {
  AccessibilityConstants._();

  // 最小触摸目标尺寸 (WCAG 2.1 AA 标准)
  static const double minTouchTargetSize = 44.0;

  // 最小文本对比度 (WCAG 2.1 AA 标准)
  static const double minContrastRatioNormal = 4.5; // 普通文本
  static const double minContrastRatioLarge = 3.0; // 大文本 (18pt+ 或 14pt+ 粗体)

  // 语义标签
  static const String semanticButton = 'button';
  static const String semanticLink = 'link';
  static const String semanticImage = 'image';
  static const String semanticHeader = 'header';

  // 焦点顺序优先级
  static const int focusPriorityHigh = 1;
  static const int focusPriorityMedium = 2;
  static const int focusPriorityLow = 3;

  // 屏幕阅读器提示
  static const String hintTapToActivate = '点击以激活';
  static const String hintDoubleTapToOpen = '双击以打开';
  static const String hintSwipeToNavigate = '滑动以导航';
}
