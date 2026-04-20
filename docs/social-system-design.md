# 社交互动系统 - 详细设计文档

> 工期：6-8周 | 工时：120-160小时 | 优先级：P1（高价值）

---

## 📋 工程概览

### 目标
构建完整的社交互动系统，提升用户留存率和活跃度，形成社区网络效应。

### 核心价值
- 提升用户留存率 30%+
- 增加用户活跃度 50%+
- 形成社区网络效应
- 增强用户粘性

---

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────┐
│                   用户界面层                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ 评论组件 │  │ 关注组件 │  │ 通知组件 │          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
└───────┼─────────────┼─────────────┼─────────────────┘
        │             │             │
┌───────┼─────────────┼─────────────┼─────────────────┐
│       │             │             │   业务逻辑层     │
│  ┌────▼─────┐  ┌───▼──────┐  ┌──▼───────┐         │
│  │评论服务  │  │关系服务  │  │通知服务  │         │
│  └────┬─────┘  └───┬──────┘  └──┬───────┘         │
└───────┼─────────────┼─────────────┼─────────────────┘
        │             │             │
┌───────┼─────────────┼─────────────┼─────────────────┐
│       │             │             │   数据层         │
│  ┌────▼─────┐  ┌───▼──────┐  ┌──▼───────┐         │
│  │comments  │  │follows   │  │notifications│       │
│  │likes     │  │favorites │  │activities│         │
│  └──────────┘  └──────────┘  └──────────┘         │
└─────────────────────────────────────────────────────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
              ┌───────▼───────┐
              │   Supabase    │
              │  PostgreSQL   │
              │   Realtime    │
              └───────────────┘
```

---

## 📊 数据库设计

### 1. 评论表 (comments)

```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL, -- 'model', 'news', 'weekly'
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE, -- 嵌套回复
  content TEXT NOT NULL CHECK (length(content) >= 1 AND length(content) <= 5000),
  likes_count INTEGER NOT NULL DEFAULT 0,
  replies_count INTEGER NOT NULL DEFAULT 0,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_comments_content ON comments(content_id, content_type) WHERE is_deleted = FALSE;
CREATE INDEX idx_comments_user ON comments(user_id) WHERE is_deleted = FALSE;
CREATE INDEX idx_comments_parent ON comments(parent_id) WHERE parent_id IS NOT NULL;
CREATE INDEX idx_comments_created ON comments(created_at DESC);

-- 触发器：更新父评论的回复数
CREATE OR REPLACE FUNCTION update_parent_replies_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.parent_id IS NOT NULL THEN
    UPDATE comments SET replies_count = replies_count + 1 WHERE id = NEW.parent_id;
  ELSIF TG_OP = 'DELETE' AND OLD.parent_id IS NOT NULL THEN
    UPDATE comments SET replies_count = replies_count - 1 WHERE id = OLD.parent_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_parent_replies_count
AFTER INSERT OR DELETE ON comments
FOR EACH ROW EXECUTE FUNCTION update_parent_replies_count();
```

### 2. 评论点赞表 (comment_likes)

```sql
CREATE TABLE comment_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

CREATE INDEX idx_comment_likes_comment ON comment_likes(comment_id);
CREATE INDEX idx_comment_likes_user ON comment_likes(user_id);

-- 触发器：更新评论点赞数
CREATE OR REPLACE FUNCTION update_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE comments SET likes_count = likes_count + 1 WHERE id = NEW.comment_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE comments SET likes_count = likes_count - 1 WHERE id = OLD.comment_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_comment_likes_count
AFTER INSERT OR DELETE ON comment_likes
FOR EACH ROW EXECUTE FUNCTION update_comment_likes_count();
```

### 3. 关注关系表 (follows)

```sql
CREATE TABLE follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- 关注者
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- 被关注者
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK(follower_id != following_id) -- 不能关注自己
);

CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- 触发器：更新用户关注数和粉丝数
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- 更新关注者的关注数
    UPDATE user_profiles SET following_count = following_count + 1 WHERE user_id = NEW.follower_id;
    -- 更新被关注者的粉丝数
    UPDATE user_profiles SET followers_count = followers_count + 1 WHERE user_id = NEW.following_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE user_profiles SET following_count = following_count - 1 WHERE user_id = OLD.follower_id;
    UPDATE user_profiles SET followers_count = followers_count - 1 WHERE user_id = OLD.following_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_follow_counts
AFTER INSERT OR DELETE ON follows
FOR EACH ROW EXECUTE FUNCTION update_follow_counts();
```

### 4. 收藏表 (favorites)

```sql
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL, -- 'model', 'news', 'weekly'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, content_id, content_type)
);

CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_content ON favorites(content_id, content_type);
CREATE INDEX idx_favorites_created ON favorites(created_at DESC);
```

### 5. 内容点赞表 (content_likes)

```sql
CREATE TABLE content_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL, -- 'model', 'news', 'weekly'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, content_id, content_type)
);

CREATE INDEX idx_content_likes_user ON content_likes(user_id);
CREATE INDEX idx_content_likes_content ON content_likes(content_id, content_type);
```

### 6. 通知表 (notifications)

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- 接收者
  actor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- 触发者
  type VARCHAR(50) NOT NULL, -- 'comment', 'like', 'follow', 'reply', 'mention'
  content TEXT,
  reference_id UUID, -- 关联的内容ID（评论ID、内容ID等）
  reference_type VARCHAR(50), -- 关联的内容类型
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
```

### 7. 用户活动表 (user_activities)

```sql
CREATE TABLE user_activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_type VARCHAR(50) NOT NULL, -- 'view', 'like', 'comment', 'favorite', 'share'
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL,
  metadata JSONB, -- 额外信息
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activities_user ON user_activities(user_id, created_at DESC);
CREATE INDEX idx_activities_content ON user_activities(content_id, content_type);
CREATE INDEX idx_activities_type ON user_activities(activity_type, created_at DESC);
```

### 8. 用户资料扩展表 (user_profiles)

```sql
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username VARCHAR(50) UNIQUE NOT NULL,
  avatar_url TEXT,
  bio TEXT CHECK (length(bio) <= 500),
  followers_count INTEGER NOT NULL DEFAULT 0,
  following_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_profiles_username ON user_profiles(username);
```

---

## 🔌 API设计

### 1. 评论相关API

#### 1.1 创建评论
```
POST /api/comments

Request:
{
  "content_id": "uuid",
  "content_type": "model",
  "content": "这个模型很不错！",
  "parent_id": "uuid" // 可选，回复评论时提供
}

Response:
{
  "id": "uuid",
  "content_id": "uuid",
  "content_type": "model",
  "user_id": "uuid",
  "parent_id": null,
  "content": "这个模型很不错！",
  "likes_count": 0,
  "replies_count": 0,
  "created_at": "2026-04-20T10:00:00Z",
  "user": {
    "id": "uuid",
    "username": "user123",
    "avatar_url": "https://..."
  }
}
```

#### 1.2 获取评论列表
```
GET /api/comments?content_id={uuid}&content_type={type}&sort={latest|hot}&page={1}&limit={20}

Response:
{
  "comments": [
    {
      "id": "uuid",
      "content": "评论内容",
      "likes_count": 10,
      "replies_count": 3,
      "created_at": "2026-04-20T10:00:00Z",
      "user": {...},
      "is_liked": true, // 当前用户是否点赞
      "replies": [ // 嵌套回复（最多2层）
        {
          "id": "uuid",
          "content": "回复内容",
          "user": {...}
        }
      ]
    }
  ],
  "total": 100,
  "page": 1,
  "limit": 20
}
```

#### 1.3 点赞/取消点赞评论
```
POST /api/comments/{id}/like
DELETE /api/comments/{id}/like

Response:
{
  "success": true,
  "likes_count": 11
}
```

#### 1.4 删除评论
```
DELETE /api/comments/{id}

Response:
{
  "success": true
}
```

---

### 2. 关注相关API

#### 2.1 关注用户
```
POST /api/follows

Request:
{
  "following_id": "uuid"
}

Response:
{
  "success": true,
  "follower_id": "uuid",
  "following_id": "uuid",
  "created_at": "2026-04-20T10:00:00Z"
}
```

#### 2.2 取消关注
```
DELETE /api/follows/{following_id}

Response:
{
  "success": true
}
```

#### 2.3 获取关注列表
```
GET /api/users/{user_id}/following?page={1}&limit={20}

Response:
{
  "users": [
    {
      "id": "uuid",
      "username": "user123",
      "avatar_url": "https://...",
      "bio": "个人简介",
      "is_following": true // 当前用户是否关注
    }
  ],
  "total": 50,
  "page": 1
}
```

#### 2.4 获取粉丝列表
```
GET /api/users/{user_id}/followers?page={1}&limit={20}

Response: 同上
```

#### 2.5 获取动态流
```
GET /api/feed?page={1}&limit={20}

Response:
{
  "activities": [
    {
      "id": "uuid",
      "user": {...},
      "activity_type": "comment",
      "content": {...}, // 内容详情
      "created_at": "2026-04-20T10:00:00Z"
    }
  ],
  "total": 100,
  "page": 1
}
```

---

### 3. 收藏相关API

#### 3.1 添加收藏
```
POST /api/favorites

Request:
{
  "content_id": "uuid",
  "content_type": "model"
}

Response:
{
  "success": true,
  "id": "uuid",
  "created_at": "2026-04-20T10:00:00Z"
}
```

#### 3.2 取消收藏
```
DELETE /api/favorites?content_id={uuid}&content_type={type}

Response:
{
  "success": true
}
```

#### 3.3 获取收藏列表
```
GET /api/favorites?content_type={model|news|weekly}&page={1}&limit={20}

Response:
{
  "favorites": [
    {
      "id": "uuid",
      "content": {...}, // 内容详情
      "created_at": "2026-04-20T10:00:00Z"
    }
  ],
  "total": 50,
  "page": 1
}
```

---

### 4. 通知相关API

#### 4.1 获取通知列表
```
GET /api/notifications?is_read={true|false}&page={1}&limit={20}

Response:
{
  "notifications": [
    {
      "id": "uuid",
      "type": "comment",
      "content": "user123 评论了你的内容",
      "actor": {
        "id": "uuid",
        "username": "user123",
        "avatar_url": "https://..."
      },
      "reference_id": "uuid",
      "reference_type": "comment",
      "is_read": false,
      "created_at": "2026-04-20T10:00:00Z"
    }
  ],
  "unread_count": 5,
  "total": 100,
  "page": 1
}
```

#### 4.2 标记通知已读
```
PUT /api/notifications/{id}/read

Response:
{
  "success": true
}
```

#### 4.3 标记所有通知已读
```
PUT /api/notifications/read-all

Response:
{
  "success": true,
  "count": 5
}
```

---

### 5. Realtime订阅

#### 5.1 订阅新通知
```typescript
const subscription = supabase
  .channel('notifications')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'notifications',
    filter: `user_id=eq.${userId}`
  }, (payload) => {
    console.log('New notification:', payload.new);
    showNotification(payload.new);
  })
  .subscribe();
```

#### 5.2 订阅新评论
```typescript
const subscription = supabase
  .channel(`comments:${contentId}`)
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'comments',
    filter: `content_id=eq.${contentId}`
  }, (payload) => {
    console.log('New comment:', payload.new);
    addCommentToList(payload.new);
  })
  .subscribe();
```

---

## 🎨 前端组件设计

### 1. 评论组件树

```
CommentSection
├── CommentInput (评论输入框)
├── CommentList (评论列表)
│   └── CommentItem (单条评论)
│       ├── UserAvatar (用户头像)
│       ├── CommentContent (评论内容)
│       ├── CommentActions (操作按钮)
│       │   ├── LikeButton (点赞)
│       │   ├── ReplyButton (回复)
│       │   └── DeleteButton (删除)
│       └── CommentReplies (嵌套回复)
│           └── CommentItem (递归)
└── CommentSorter (排序选择器)
```

### 2. 关注组件

```
FollowButton
├── FollowingState (已关注状态)
└── NotFollowingState (未关注状态)

UserList
└── UserCard
    ├── UserAvatar
    ├── UserInfo
    │   ├── Username
    │   ├── Bio
    │   └── FollowStats
    └── FollowButton
```

### 3. 通知组件

```
NotificationCenter
├── NotificationBadge (未读数角标)
├── NotificationList
│   └── NotificationItem
│       ├── ActorAvatar
│       ├── NotificationContent
│       ├── NotificationTime
│       └── ReadIndicator
└── NotificationSettings (通知设置)
```

---

## 📱 页面设计

### 1. 评论页面
- 路由: `/content/{id}/comments`
- 功能: 显示评论列表、发表评论、回复评论、点赞评论

### 2. 用户主页
- 路由: `/users/{id}`
- 功能: 显示用户信息、关注/粉丝数、用户动态

### 3. 关注列表页
- 路由: `/users/{id}/following`
- 功能: 显示关注的用户列表

### 4. 粉丝列表页
- 路由: `/users/{id}/followers`
- 功能: 显示粉丝列表

### 5. 收藏页面
- 路由: `/favorites`
- 功能: 显示收藏的内容列表

### 6. 通知中心
- 路由: `/notifications`
- 功能: 显示通知列表、标记已读

### 7. 动态流页面
- 路由: `/feed`
- 功能: 显示关注用户的动态

---

## 🔄 状态管理

### 使用Bloc模式

```dart
// lib/blocs/comment_bloc.dart
class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final CommentRepository repository;
  
  CommentBloc(this.repository) : super(CommentInitial()) {
    on<LoadComments>(_onLoadComments);
    on<AddComment>(_onAddComment);
    on<LikeComment>(_onLikeComment);
    on<DeleteComment>(_onDeleteComment);
  }
  
  Future<void> _onLoadComments(LoadComments event, Emitter<CommentState> emit) async {
    emit(CommentLoading());
    try {
      final comments = await repository.getComments(
        contentId: event.contentId,
        contentType: event.contentType,
        sort: event.sort,
      );
      emit(CommentLoaded(comments));
    } catch (e) {
      emit(CommentError(e.toString()));
    }
  }
}
```

---

## 📋 实施计划

### Phase 1: 评论系统（Week 1-2，32小时）

**Week 1: 后端开发**
- [ ] 创建数据库表（comments, comment_likes）
- [ ] 实现评论CRUD API
- [ ] 实现点赞API
- [ ] 实现评论排序逻辑
- [ ] 编写单元测试

**Week 2: 前端开发**
- [ ] 创建评论组件
- [ ] 实现评论列表展示
- [ ] 实现评论输入和提交
- [ ] 实现嵌套回复
- [ ] 实现点赞功能
- [ ] 集成Realtime订阅

---

### Phase 2: 关注系统（Week 3-4，32小时）

**Week 3: 后端开发**
- [ ] 创建数据库表（follows, user_profiles）
- [ ] 实现关注/取消关注API
- [ ] 实现关注列表API
- [ ] 实现粉丝列表API
- [ ] 实现动态流API
- [ ] 编写单元测试

**Week 4: 前端开发**
- [ ] 创建关注按钮组件
- [ ] 实现用户主页
- [ ] 实现关注列表页
- [ ] 实现粉丝列表页
- [ ] 实现动态流页面

---

### Phase 3: 收藏和点赞（Week 5，16小时）

- [ ] 创建数据库表（favorites, content_likes）
- [ ] 实现收藏API
- [ ] 实现点赞API
- [ ] 前端集成收藏功能
- [ ] 前端集成点赞功能
- [ ] 实现收藏列表页

---

### Phase 4: 通知系统（Week 6-7，40小时）

**Week 6: 后端开发**
- [ ] 创建数据库表（notifications）
- [ ] 实现通知生成逻辑（触发器）
- [ ] 实现通知API
- [ ] 集成FCM推送
- [ ] 实现邮件通知

**Week 7: 前端开发**
- [ ] 创建通知组件
- [ ] 实现通知中心页面
- [ ] 实现通知角标
- [ ] 集成Realtime订阅
- [ ] 实现通知设置

---

### Phase 5: 用户画像（Week 8，16小时）

- [ ] 创建数据库表（user_activities）
- [ ] 实现行为追踪
- [ ] 实现兴趣标签提取
- [ ] 实现个性化推荐算法
- [ ] 前端集成推荐功能

---

## 🧪 测试计划

### 1. 单元测试
- 评论CRUD逻辑
- 关注关系逻辑
- 通知生成逻辑
- 推荐算法

### 2. 集成测试
- 评论API端到端测试
- 关注API端到端测试
- 通知API端到端测试
- Realtime订阅测试

### 3. E2E测试
- 用户发表评论流程
- 用户关注流程
- 用户收藏流程
- 通知接收流程

### 4. 性能测试
- 评论列表加载性能（1000+评论）
- 动态流加载性能
- Realtime订阅性能
- 数据库查询性能

---

## ✅ 验收标准

### 功能验收
- [ ] 用户可以发表评论和回复
- [ ] 用户可以点赞评论
- [ ] 用户可以关注/取消关注其他用户
- [ ] 用户可以查看关注列表和粉丝列表
- [ ] 用户可以收藏内容
- [ ] 用户可以点赞内容
- [ ] 用户可以接收通知（站内、邮件、推送）
- [ ] 用户可以查看动态流

### 性能指标
- 评论列表加载时间 < 500ms
- 动态流加载时间 < 1s
- Realtime延迟 < 100ms
- 通知推送延迟 < 5s

### 用户体验指标
- 评论功能使用率 > 20%
- 关注功能使用率 > 15%
- 收藏功能使用率 > 30%
- 通知打开率 > 40%

---

**设计者**: Claude Code  
**审核状态**: 待审核  
**开始日期**: 待定  
**预计完成日期**: 开始后6-8周
