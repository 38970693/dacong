# DaCong 无障碍指南

本文档描述了 DaCong 应用的无障碍功能实现和最佳实践。

## 目录

- [概述](#概述)
- [WCAG 2.1 AA 合规性](#wcag-21-aa-合规性)
- [屏幕阅读器支持](#屏幕阅读器支持)
- [键盘导航](#键盘导航)
- [颜色对比度](#颜色对比度)
- [触摸目标尺寸](#触摸目标尺寸)
- [文本缩放](#文本缩放)
- [焦点管理](#焦点管理)
- [测试](#测试)
- [开发指南](#开发指南)

## 概述

DaCong 致力于为所有用户提供无障碍的体验，包括使用辅助技术的用户。我们遵循 WCAG 2.1 AA 标准，确保应用对所有人都可用。

### 支持的辅助技术

- **屏幕阅读器**: TalkBack (Android), VoiceOver (iOS)
- **键盘导航**: 完整的键盘操作支持
- **文本缩放**: 支持系统文本缩放 (100%-200%)
- **高对比度模式**: 自动适配系统高对比度设置

## WCAG 2.1 AA 合规性

### 感知性 (Perceivable)

#### 1.1 文本替代
- ✅ 所有图片都有语义标签
- ✅ 图标按钮有描述性标签
- ✅ 装饰性图片被标记为装饰性

#### 1.3 适应性
- ✅ 内容可以以不同方式呈现
- ✅ 语义化的 HTML 结构
- ✅ 正确的标题层级

#### 1.4 可辨别性
- ✅ 颜色对比度符合 WCAG 2.1 AA 标准
  - 普通文本: ≥ 4.5:1
  - 大文本: ≥ 3.0:1
- ✅ 文本可缩放至 200%
- ✅ 不仅依赖颜色传达信息

### 可操作性 (Operable)

#### 2.1 键盘可访问
- ✅ 所有功能可通过键盘访问
- ✅ 无键盘陷阱
- ✅ 快捷键支持

#### 2.4 导航
- ✅ 清晰的焦点指示器
- ✅ 合理的焦点顺序
- ✅ 描述性的链接文本

#### 2.5 输入方式
- ✅ 触摸目标至少 44x44 dp
- ✅ 支持多种输入方式

### 可理解性 (Understandable)

#### 3.1 可读性
- ✅ 明确的语言设置
- ✅ 清晰的错误消息

#### 3.2 可预测性
- ✅ 一致的导航
- ✅ 一致的标识

#### 3.3 输入辅助
- ✅ 错误识别
- ✅ 标签或说明

### 健壮性 (Robust)

#### 4.1 兼容性
- ✅ 与辅助技术兼容
- ✅ 正确的语义标记

## 屏幕阅读器支持

### 语义标签

所有交互元素都有描述性的语义标签：

```dart
Semantics(
  label: '推荐工具卡片',
  hint: '双击查看详情',
  button: true,
  child: RecommendationCard(...),
)
```

### 使用无障碍组件

我们提供了带无障碍支持的组件：

- `AccessibleContentCard` - 内容卡片
- `AccessibleRecommendationCard` - 推荐卡片
- `AccessibleScenarioSelector` - 场景选择器

### 最佳实践

1. **提供有意义的标签**
   ```dart
   final semanticLabel = AccessibilityUtils.generateSemanticLabel(
     label: '按钮',
     value: '提交',
     hint: '双击以提交表单',
   );
   ```

2. **标记标题**
   ```dart
   Semantics(
     header: true,
     child: Text('页面标题'),
   )
   ```

3. **隐藏装饰性元素**
   ```dart
   Semantics(
     excludeSemantics: true,
     child: DecorativeImage(),
   )
   ```

## 键盘导航

### 支持的快捷键

| 按键 | 功能 |
|------|------|
| Tab | 移动到下一个可聚焦元素 |
| Shift + Tab | 移动到上一个可聚焦元素 |
| Enter / Space | 激活当前元素 |
| Esc | 关闭对话框/返回 |
| ↑ / ↓ | 在垂直列表中导航 |
| ← / → | 在水平列表中导航 |

### 焦点管理

使用 `FocusManager` 管理焦点：

```dart
// 注册焦点组
FocusManager.registerFocusGroup('myGroup', focusNodes);

// 移动焦点
FocusManager.moveToNext(context, 'myGroup');
FocusManager.moveToPrevious(context, 'myGroup');

// 清除焦点
FocusManager.clearFocus(context);
```

### 焦点指示器

所有可聚焦元素都有清晰的焦点指示器：

```dart
FocusableButton(
  child: Text('按钮'),
  onPressed: () {},
)
```

## 颜色对比度

### 检查对比度

使用 `AccessibilityUtils` 检查颜色对比度：

```dart
final ratio = AccessibilityUtils.calculateContrastRatio(
  foreground,
  background,
);

final meetsRequirement = AccessibilityUtils.meetsContrastRequirement(
  foreground,
  background,
  isLargeText: false,
);
```

### 运行对比度检查脚本

```bash
dart scripts/check_contrast.dart
```

### 颜色使用指南

1. **普通文本** (< 18pt)
   - 最小对比度: 4.5:1
   - 推荐: 7:1 或更高

2. **大文本** (≥ 18pt 或 ≥ 14pt 粗体)
   - 最小对比度: 3.0:1
   - 推荐: 4.5:1 或更高

3. **UI 组件**
   - 最小对比度: 3.0:1

### 常用颜色组合

| 前景色 | 背景色 | 对比度 | 状态 |
|--------|--------|--------|------|
| 黑色 | 白色 | 21:1 | ✅ 优秀 |
| 深灰 (#424242) | 白色 | 12.6:1 | ✅ 优秀 |
| 蓝色 (#2196F3) | 白色 | 3.1:1 | ⚠️ 仅大文本 |
| 白色 | 蓝色 (#2196F3) | 3.1:1 | ⚠️ 仅大文本 |

## 触摸目标尺寸

### 最小尺寸要求

所有可点击元素必须至少 **44x44 dp**：

```dart
final size = AccessibilityUtils.ensureMinTouchTargetSize(
  Size(width, height),
);
```

### 实现示例

```dart
Container(
  constraints: BoxConstraints(
    minHeight: AccessibilityConstants.minTouchTargetSize,
    minWidth: AccessibilityConstants.minTouchTargetSize,
  ),
  child: IconButton(...),
)
```

### 间距要求

- 相邻触摸目标之间至少 8dp 间距
- 推荐 16dp 间距以提高可用性

## 文本缩放

### 支持范围

应用支持系统文本缩放 **100%-200%**：

```dart
final scaleFactor = AccessibilityUtils.getTextScaleFactor(context);
final isSupported = AccessibilityUtils.isTextScaleFactorSupported(context);
```

### 最佳实践

1. **不要使用固定的 textScaleFactor**
   ```dart
   // ❌ 错误
   Text('Hello', textScaleFactor: 1.0)
   
   // ✅ 正确
   Text('Hello')
   ```

2. **使用灵活的布局**
   ```dart
   // 使用 Flexible, Expanded 等
   Row(
     children: [
       Flexible(child: Text('长文本...')),
     ],
   )
   ```

3. **测试不同缩放级别**
   - 100% (默认)
   - 150%
   - 200% (最大)

## 焦点管理

### FocusOrderScope

自动管理子组件的焦点顺序：

```dart
FocusOrderScope(
  groupId: 'myList',
  direction: Axis.vertical,
  children: [
    ListItem1(),
    ListItem2(),
    ListItem3(),
  ],
)
```

### FocusableButton

提供完整键盘导航支持的按钮：

```dart
FocusableButton(
  child: Text('提交'),
  onPressed: () {},
  autofocus: true,
)
```

### FocusableCard

为卡片组件提供焦点指示器：

```dart
FocusableCard(
  child: ContentCard(...),
  onTap: () {},
)
```

## 测试

### 单元测试

```dart
import 'package:dacong_client/test/accessibility/accessibility_test_utils.dart';

testWidgets('Button should be accessible', (tester) async {
  await tester.pumpWidget(MyButton());
  
  final button = find.byType(ElevatedButton);
  
  // 检查语义标签
  AccessibilityTestUtils.expectHasSemanticLabel(tester, button);
  
  // 检查触摸目标尺寸
  AccessibilityTestUtils.expectMinTouchTargetSize(tester, button);
  
  // 检查按钮可访问性
  AccessibilityTestUtils.expectButtonAccessible(tester, button);
});
```

### 对比度测试

```dart
test('Text color should meet contrast requirement', () {
  AccessibilityTestUtils.expectMeetsContrastRequirement(
    Colors.black,
    Colors.white,
  );
});
```

### 完整检查

```dart
testWidgets('Widget should be fully accessible', (tester) async {
  await AccessibilityTestUtils.runFullAccessibilityCheck(
    tester,
    MyWidget(),
  );
});
```

### 手动测试清单

- [ ] 使用 TalkBack/VoiceOver 测试所有页面
- [ ] 使用键盘导航测试所有功能
- [ ] 测试文本缩放 100%-200%
- [ ] 测试高对比度模式
- [ ] 验证所有触摸目标尺寸
- [ ] 检查焦点指示器可见性

## 开发指南

### 创建新组件时

1. **添加语义标签**
   ```dart
   Semantics(
     label: '描述性标签',
     hint: '操作提示',
     child: YourWidget(),
   )
   ```

2. **确保触摸目标尺寸**
   ```dart
   Container(
     constraints: BoxConstraints(
       minHeight: 44,
       minWidth: 44,
     ),
     child: YourButton(),
   )
   ```

3. **支持键盘导航**
   ```dart
   FocusableButton(
     child: YourButton(),
     onPressed: onPressed,
   )
   ```

4. **检查颜色对比度**
   ```dart
   final meetsRequirement = AccessibilityUtils.meetsContrastRequirement(
     foreground,
     background,
   );
   ```

5. **编写无障碍测试**
   ```dart
   testWidgets('should be accessible', (tester) async {
     // 测试代码
   });
   ```

### 代码审查清单

- [ ] 所有交互元素有语义标签
- [ ] 触摸目标至少 44x44 dp
- [ ] 颜色对比度符合标准
- [ ] 支持键盘导航
- [ ] 文本可缩放
- [ ] 有焦点指示器
- [ ] 编写了无障碍测试

### 常见问题

#### Q: 如何为图标按钮添加标签？

```dart
Semantics(
  label: '搜索',
  button: true,
  child: IconButton(
    icon: Icon(Icons.search),
    onPressed: onSearch,
  ),
)
```

#### Q: 如何隐藏装饰性元素？

```dart
Semantics(
  excludeSemantics: true,
  child: DecorativeImage(),
)
```

#### Q: 如何宣布消息给屏幕阅读器？

```dart
AccessibilityUtils.announce(context, '操作成功');
```

#### Q: 如何检查是否启用了屏幕阅读器？

```dart
final isEnabled = AccessibilityUtils.isScreenReaderEnabled(context);
```

## 资源

### 官方文档

- [Flutter 无障碍](https://flutter.dev/docs/development/accessibility-and-localization/accessibility)
- [WCAG 2.1 指南](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design 无障碍](https://material.io/design/usability/accessibility.html)

### 测试工具

- **Android**: TalkBack, Accessibility Scanner
- **iOS**: VoiceOver, Accessibility Inspector
- **Web**: WAVE, axe DevTools

### 相关文件

- `lib/core/accessibility/accessibility_constants.dart` - 无障碍常量
- `lib/core/accessibility/accessibility_utils.dart` - 无障碍工具类
- `lib/core/accessibility/focus_manager.dart` - 焦点管理器
- `scripts/check_contrast.dart` - 对比度检查脚本
- `test/accessibility/` - 无障碍测试

## 联系方式

如有无障碍相关问题或建议，请联系开发团队。

---

最后更新: 2026-04-17
