# 无障碍功能快速开始

本指南帮助开发者快速集成和使用 DaCong 的无障碍功能。

## 快速开始

### 1. 使用无障碍组件

替换现有组件为无障碍版本：

```dart
// 之前
import 'package:dacong_client/presentation/widgets/content_card.dart';

ContentCard(
  content: content,
  onTap: () {},
)

// 之后
import 'package:dacong_client/presentation/widgets/accessible_content_card.dart';

AccessibleContentCard(
  content: content,
  onTap: () {},
)
```

### 2. 添加语义标签

```dart
import 'package:dacong_client/core/accessibility/accessibility_utils.dart';

Semantics(
  label: AccessibilityUtils.generateSemanticLabel(
    label: '推荐卡片',
    value: '工具名称',
    hint: '双击查看详情',
  ),
  button: true,
  child: YourWidget(),
)
```

### 3. 使用焦点管理

```dart
import 'package:dacong_client/core/accessibility/focus_manager.dart';

// 可聚焦按钮
FocusableButton(
  child: Text('提交'),
  onPressed: () {},
)

// 焦点顺序管理
FocusOrderScope(
  groupId: 'myList',
  direction: Axis.vertical,
  children: [
    Item1(),
    Item2(),
    Item3(),
  ],
)
```

### 4. 检查颜色对比度

```dart
import 'package:dacong_client/core/accessibility/accessibility_utils.dart';

final meetsRequirement = AccessibilityUtils.meetsContrastRequirement(
  foreground: Colors.black,
  background: Colors.white,
  isLargeText: false,
);

if (!meetsRequirement) {
  // 调整颜色
}
```

### 5. 确保触摸目标尺寸

```dart
import 'package:dacong_client/core/accessibility/accessibility_constants.dart';

Container(
  constraints: BoxConstraints(
    minHeight: AccessibilityConstants.minTouchTargetSize,
    minWidth: AccessibilityConstants.minTouchTargetSize,
  ),
  child: YourButton(),
)
```

## 运行测试

### 单元测试

```bash
flutter test test/accessibility/
```

### 对比度检查

```bash
dart scripts/check_contrast.dart
```

### 完整测试

```bash
flutter test
```

## 可用组件

### 无障碍组件

- `AccessibleContentCard` - 内容卡片
- `AccessibleRecommendationCard` - 推荐卡片
- `AccessibleScenarioSelector` - 场景选择器

### 焦点管理组件

- `FocusableButton` - 可聚焦按钮
- `FocusableCard` - 可聚焦卡片
- `FocusOrderScope` - 焦点顺序管理

### 工具类

- `AccessibilityUtils` - 无障碍工具方法
- `AccessibilityConstants` - 无障碍常量
- `FocusManager` - 焦点管理器

## 测试工具

### 测试工具类

```dart
import 'package:dacong_client/test/accessibility/accessibility_test_utils.dart';

testWidgets('should be accessible', (tester) async {
  await tester.pumpWidget(MyWidget());
  
  final widget = find.byType(MyWidget);
  
  // 检查语义标签
  AccessibilityTestUtils.expectHasSemanticLabel(tester, widget);
  
  // 检查触摸目标尺寸
  AccessibilityTestUtils.expectMinTouchTargetSize(tester, widget);
  
  // 检查按钮可访问性
  AccessibilityTestUtils.expectButtonAccessible(tester, widget);
});
```

## 更多信息

详细文档请参阅 [docs/ACCESSIBILITY.md](docs/ACCESSIBILITY.md)

## 验收标准

- ✅ 通过 WCAG 2.1 AA 标准
- ✅ 屏幕阅读器可正常使用
- ✅ 键盘导航完整
- ✅ 颜色对比度符合标准
- ✅ 触摸目标尺寸符合标准
- ✅ 支持文本缩放
- ✅ 文档完善
