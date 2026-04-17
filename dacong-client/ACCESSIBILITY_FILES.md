# 无障碍功能文件清单

## 核心库文件

### 无障碍工具和常量
- `lib/core/accessibility/accessibility_constants.dart` - 无障碍常量定义
- `lib/core/accessibility/accessibility_utils.dart` - 无障碍工具类（对比度计算、触摸目标尺寸等）
- `lib/core/accessibility/focus_manager.dart` - 焦点管理系统

## 无障碍组件

### 带无障碍支持的 Widget
- `lib/presentation/widgets/accessible_content_card.dart` - 内容卡片（带 Semantics）
- `lib/presentation/widgets/accessible_recommendation_card.dart` - 推荐卡片（带 Semantics）
- `lib/presentation/widgets/accessible_scenario_selector.dart` - 场景选择器（带键盘导航）

### 示例页面
- `lib/presentation/pages/home/accessible_home_page.dart` - 首页无障碍实现示例

## 测试文件

### 单元测试
- `test/accessibility/accessibility_utils_test.dart` - 无障碍工具类测试（15个测试用例）
- `test/accessibility/accessibility_test_utils.dart` - 测试工具类

## 脚本

### 检查工具
- `scripts/check_contrast.dart` - 颜色对比度检查脚本

## 文档

### 使用指南
- `docs/ACCESSIBILITY.md` - 完整的无障碍指南（WCAG 2.1 AA 合规性）
- `docs/ACCESSIBILITY_QUICKSTART.md` - 快速开始指南
- `ACCESSIBILITY_IMPLEMENTATION.md` - 实现总结

## 统计

- **核心文件**: 3 个
- **组件文件**: 4 个
- **测试文件**: 2 个
- **脚本文件**: 1 个
- **文档文件**: 3 个
- **总计**: 13 个新文件

## 测试覆盖

```bash
flutter test test/accessibility/
```

结果: ✅ 15/15 测试通过

## 快速使用

### 1. 使用无障碍组件

```dart
import 'package:dacong_client/presentation/widgets/accessible_recommendation_card.dart';

AccessibleRecommendationCard(
  recommendation: recommendation,
  onTap: () {},
)
```

### 2. 检查对比度

```bash
dart scripts/check_contrast.dart
```

### 3. 使用焦点管理

```dart
import 'package:dacong_client/core/accessibility/focus_manager.dart';

FocusableButton(
  child: Text('按钮'),
  onPressed: () {},
)
```

### 4. 查看文档

- 详细指南: [docs/ACCESSIBILITY.md](docs/ACCESSIBILITY.md)
- 快速开始: [docs/ACCESSIBILITY_QUICKSTART.md](docs/ACCESSIBILITY_QUICKSTART.md)
