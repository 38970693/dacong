# 批量操作功能说明

## 功能概述

DaCong 管理后台现已支持批量操作功能，包括批量审核、批量删除等操作，并提供了友好的进度提示和确认对话框。

## 已实现的功能

### 1. 批量选择组件 (`lib/widgets/batch_selection_widget.dart`)

#### BatchSelectionBar
- 显示已选择数量
- 全选/反选功能
- 取消选择按钮
- 批量操作按钮（支持自定义）
- 自动显示/隐藏动画

#### BatchOperationDialog
- 实时显示操作进度
- 显示当前处理项
- 进度百分比显示
- 错误处理和提示
- 操作完成自动关闭

### 2. 内容管理页面 (`lib/pages/content_management_page.dart`)

#### 批量操作功能
- **批量通过**: 一次性通过多条内容
- **批量拒绝**: 一次性拒绝多条内容
- **批量删除**: 删除多条内容（带确认对话框）
- **批量导出**: 导出选中内容为 CSV

#### 选择功能
- 单个选择：点击每项的复选框
- 全选/取消全选：点击快捷键栏的全选按钮
- 已选数量显示在 AppBar

#### 进度提示
- 单个操作：直接执行，显示成功/失败提示
- 批量操作（2项及以上）：显示进度对话框
  - 实时进度条
  - 当前处理项标题
  - 完成百分比
  - 操作完成提示

### 3. 评论审核页面 (`lib/pages/comment_moderation_page.dart`)

#### 批量操作功能
- **批量通过**: 一次性通过多条评论
- **批量删除**: 删除多条评论
  - 可选填写删除原因
  - 可选同时封禁用户

#### 选择功能
- 单个选择：点击每项的复选框
- 全选/取消全选：点击筛选栏的全选按钮
- 已选数量显示在 AppBar

#### 进度提示
- 单个操作：直接执行
- 批量操作：显示进度对话框
  - 显示评论内容预览（前20字符）
  - 实时进度更新

## 使用方法

### 内容管理

1. 进入"内容管理"页面
2. 勾选需要操作的内容项
3. 点击 AppBar 上的批量操作按钮：
   - "批量通过"：直接通过所有选中项
   - "批量拒绝"：直接拒绝所有选中项
   - "批量删除"：弹出确认对话框，确认后删除
   - "批量导出"：导出为 CSV 文件
4. 查看进度对话框（批量操作时）
5. 操作完成后自动刷新列表

### 评论审核

1. 进入"评论审核"页面
2. 勾选需要操作的评论
3. 点击 AppBar 上的批量操作按钮：
   - "批量通过"：直接通过所有选中评论
   - "批量删除"：弹出对话框
     - 可填写删除原因
     - 可选择同时封禁用户
4. 查看进度对话框
5. 操作完成后自动刷新列表

## 技术特性

### 性能优化
- 单个操作直接执行，无需进度对话框
- 批量操作逐个处理，避免服务器压力
- 请求间隔 100ms，防止请求过快

### 用户体验
- 确认对话框防止误操作
- 实时进度反馈
- 操作成功/失败明确提示
- 全选/反选快捷操作
- 已选数量实时显示

### 错误处理
- 操作失败显示错误信息
- 进度对话框捕获异常
- 不影响其他项的处理

## 组件 API

### BatchAction

```dart
BatchAction(
  label: '批量删除',           // 按钮文本
  icon: Icons.delete,          // 按钮图标
  color: Colors.red,           // 按钮颜色（可选）
  requiresConfirmation: true,  // 是否需要确认对话框
  confirmTitle: '确认删除',    // 确认对话框标题
  confirmMessage: '确定要删除吗？', // 确认对话框内容
  onPressed: () {              // 点击回调
    // 执行操作
  },
)
```

### BatchOperationDialog.show

```dart
final success = await BatchOperationDialog.show(
  context: context,
  title: '批量处理',
  totalCount: items.length,
  operation: (updateProgress) async {
    for (int i = 0; i < items.length; i++) {
      // 更新进度
      updateProgress(i, items[i].name);
      
      // 执行操作
      await processItem(items[i]);
      
      // 避免请求过快
      if (i < items.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    // 完成
    updateProgress(items.length, null);
  },
);

if (success) {
  // 操作成功
}
```

## 未来改进

- [ ] 支持批量编辑
- [ ] 支持撤销操作
- [ ] 支持操作历史记录
- [ ] 支持导出更多格式（JSON, Excel）
- [ ] 支持批量操作的并发处理
- [ ] 支持操作失败后的重试机制
