# 评论功能增强

## 概述

本文档描述了评论系统的增强功能，包括嵌套回复、评论树展示和排序功能。

## 功能特性

### 1. 嵌套评论支持

评论系统支持多层级的嵌套回复，用户可以直接回复任何一级评论。

#### 数据库设计

`comments` 表包含 `parent_id` 字段用于建立评论之间的父子关系：

```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY,
  content_id UUID NOT NULL,
  user_id UUID NOT NULL,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  likes_count INT DEFAULT 0,
  reply_count INT DEFAULT 0,
  ...
);
```

#### 触发器自动维护

数据库触发器自动维护 `reply_count` 字段：
- 插入回复时自动增加父评论的 `reply_count`
- 删除回复时自动减少父评论的 `reply_count`
- 软删除回复时也会更新计数

### 2. 评论回复 API

#### 提交回复

**端点**: `POST /submit-comment`

**请求体**:
```json
{
  "content_id": "uuid",
  "parent_id": "uuid",  // 可选，回复时提供
  "content": "回复内容"
}
```

**验证逻辑**:
1. 验证用户身份
2. 验证内容存在性
3. 如果是回复，验证父评论存在性
4. 内容清理和敏感词检测

**响应**:
```json
{
  "success": true,
  "data": {
    "comment": {
      "id": "uuid",
      "content_id": "uuid",
      "parent_id": "uuid",
      "content": "回复内容",
      "is_liked": false,
      ...
    },
    "moderation_status": "approved",
    "message": "Comment posted successfully"
  }
}
```

### 3. 评论排序 API

#### 获取评论列表

**端点**: `POST /get-comments`

**请求体**:
```json
{
  "content_id": "uuid",
  "parent_id": null,  // null 获取顶级评论，提供 ID 获取回复
  "page": 1,
  "limit": 20,
  "sort": "latest"  // "latest" 或 "popular"
}
```

**排序选项**:
- `latest`: 按创建时间降序（最新的在前）
- `popular`: 按点赞数降序（最热门的在前）

**响应**:
```json
{
  "success": true,
  "data": {
    "comments": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "has_more": true
    }
  }
}
```

### 4. 前端评论树展示

#### CommentTree 组件

`CommentTree` 组件负责递归展示嵌套评论结构。

**特性**:
- 支持最多 3 层嵌套（可配置）
- 懒加载回复列表
- 展开/收起回复
- 视觉缩进表示层级关系

**使用示例**:
```dart
CommentTree(
  comment: comment,
  contentId: contentId,
  depth: 0,
  maxDepth: 3,
)
```

**层级限制**:
- `depth`: 当前评论的深度（0 为顶级评论）
- `maxDepth`: 最大嵌套深度（默认 3）
- 超过最大深度的评论不显示回复按钮

#### 视觉设计

```
评论 A
  ├─ 回复 A1 (缩进 32px)
  │   └─ 回复 A1a (缩进 64px)
  └─ 回复 A2 (缩进 32px)
评论 B
```

### 5. 回复功能

#### CommentItem 组件增强

**新增功能**:
- 回复按钮（仅顶级评论显示）
- 内联回复输入框
- 自动聚焦输入框
- 提交后清空输入

**交互流程**:
1. 用户点击"Reply"按钮
2. 展开回复输入框并自动聚焦
3. 用户输入回复内容
4. 点击发送或按 Enter 提交
5. 提交成功后清空输入框并收起

**代码示例**:
```dart
// 回复按钮
InkWell(
  onTap: _toggleReplyInput,
  child: Row(
    children: [
      Icon(Icons.reply),
      Text('Reply'),
    ],
  ),
)

// 回复输入框
if (_showReplyInput)
  TextField(
    controller: _replyController,
    focusNode: _replyFocusNode,
    decoration: InputDecoration(
      hintText: 'Write a reply...',
    ),
    onSubmitted: (_) => _submitReply(),
  )
```

### 6. 排序切换

#### 排序选项 UI

使用 `ChoiceChip` 组件实现排序切换：

```dart
Row(
  children: [
    Text('Sort by:'),
    ChoiceChip(
      label: Text('Latest'),
      selected: _currentSort == 'latest',
      onSelected: (selected) {
        if (selected) _changeSortOrder('latest');
      },
    ),
    ChoiceChip(
      label: Text('Popular'),
      selected: _currentSort == 'popular',
      onSelected: (selected) {
        if (selected) _changeSortOrder('popular');
      },
    ),
  ],
)
```

#### 状态管理

使用 BLoC 模式管理排序状态：

```dart
// Event
class ChangeSortOrder extends CommentEvent {
  final String sort;
  const ChangeSortOrder(this.sort);
}

// State
class CommentLoaded extends CommentState {
  final List<Comment> comments;
  final String sort;
  ...
}

// BLoC
Future<void> _onChangeSortOrder(
  ChangeSortOrder event,
  Emitter<CommentState> emit,
) async {
  emit(CommentLoading());
  
  final result = await getComments(
    contentId: _currentContentId!,
    sort: event.sort,
  );
  
  result.fold(
    (failure) => emit(CommentError(message: failure.message)),
    (comments) => emit(CommentLoaded(
      comments: comments,
      sort: event.sort,
    )),
  );
}
```

## 技术实现

### 前端架构

```
presentation/
├── widgets/
│   └── comment/
│       ├── comment_section.dart    # 评论区容器
│       ├── comment_tree.dart       # 评论树（新增）
│       ├── comment_item.dart       # 单条评论（增强）
│       └── comment_input.dart      # 评论输入框
├── blocs/
│   └── comment/
│       ├── comment_bloc.dart       # 业务逻辑（增强）
│       ├── comment_event.dart      # 事件定义（新增 LoadReplies）
│       └── comment_state.dart      # 状态定义（新增回复状态）
```

### 状态管理

#### 新增 Event

```dart
class LoadReplies extends CommentEvent {
  final String contentId;
  final String parentId;
  final int page;
  final String sort;
  
  const LoadReplies({
    required this.contentId,
    required this.parentId,
    this.page = 1,
    this.sort = 'latest',
  });
}
```

#### 新增 State

```dart
class CommentRepliesLoading extends CommentState {
  final String parentId;
  const CommentRepliesLoading({required this.parentId});
}

class CommentRepliesLoaded extends CommentState {
  final String parentId;
  final List<Comment> replies;
  
  const CommentRepliesLoaded({
    required this.parentId,
    required this.replies,
  });
}
```

### 性能优化

1. **懒加载回复**: 只在用户展开时才加载回复列表
2. **局部重建**: 使用 `buildWhen` 只在相关状态变化时重建组件
3. **分页加载**: 支持分页加载大量回复
4. **乐观更新**: 点赞等操作立即更新 UI，后台异步同步

```dart
BlocBuilder<CommentBloc, CommentState>(
  buildWhen: (previous, current) {
    // 只在回复相关状态变化时重建
    if (current is CommentRepliesLoaded) {
      return current.parentId == widget.comment.id;
    }
    return false;
  },
  builder: (context, state) {
    // 构建回复列表
  },
)
```

## 用户体验

### 交互流程

1. **查看评论**
   - 用户进入内容详情页
   - 自动加载顶级评论（按最新排序）
   - 显示每条评论的回复数量

2. **展开回复**
   - 点击"Show N replies"按钮
   - 加载并展示回复列表
   - 回复以缩进形式显示

3. **发表回复**
   - 点击"Reply"按钮
   - 输入框展开并自动聚焦
   - 输入内容后点击发送
   - 回复立即显示在列表中

4. **切换排序**
   - 点击"Latest"或"Popular"标签
   - 重新加载评论列表
   - 保持当前排序状态

### 视觉反馈

- 加载状态显示 `CircularProgressIndicator`
- 提交成功显示 `SnackBar` 提示
- 错误状态显示错误信息和重试按钮
- 空状态显示友好提示文案

## 测试要点

### 功能测试

- [ ] 提交顶级评论
- [ ] 提交回复评论
- [ ] 展开/收起回复列表
- [ ] 切换排序方式（最新/最热）
- [ ] 分页加载更多评论
- [ ] 点赞/取消点赞
- [ ] 举报评论

### 边界测试

- [ ] 空评论列表
- [ ] 单条评论无回复
- [ ] 大量回复（100+）
- [ ] 深层嵌套（3 层）
- [ ] 超长评论内容
- [ ] 网络错误处理

### 性能测试

- [ ] 加载 100 条评论的响应时间
- [ ] 展开 50 条回复的响应时间
- [ ] 滚动流畅度（60fps）
- [ ] 内存占用

## 未来改进

1. **实时更新**: 使用 WebSocket 实现评论实时推送
2. **@提及**: 支持 @用户名 提及功能
3. **富文本**: 支持 Markdown 格式
4. **图片评论**: 支持上传图片
5. **表情回应**: 快速表情回应（👍❤️😂等）
6. **评论搜索**: 搜索评论内容
7. **评论置顶**: 管理员置顶重要评论
8. **评论编辑**: 用户编辑自己的评论

## 相关文档

- [评论系统 API 文档](../dacong-api/docs/api/comments.md)
- [数据库设计文档](../dacong-api/docs/database/schema.md)
- [前端架构文档](../dacong-client/ARCHITECTURE.md)
