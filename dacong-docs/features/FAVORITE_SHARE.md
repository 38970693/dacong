# 内容收藏和分享功能

## 功能概述

实现用户对 AI 工具内容的收藏和分享功能，提升用户参与度和内容传播效果。

## 功能特性

### 1. 收藏功能

- 用户可以收藏感兴趣的内容
- 支持一键切换收藏状态
- 收藏列表按时间倒序展示
- 收藏内容包含完整的内容信息
- 支持取消收藏

### 2. 分享功能

- 支持系统原生分享
- 支持复制链接
- 支持生成分享图卡（预留接口）
- 记录分享行为用于数据分析
- 支持匿名分享

## 技术架构

### 数据库设计

#### favorites 表

```sql
CREATE TABLE favorites (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  content_id UUID NOT NULL REFERENCES published_content(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, content_id)
);
```

#### shares 表

```sql
CREATE TABLE shares (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  content_id UUID NOT NULL REFERENCES published_content(id),
  platform VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### API 端点

#### 收藏相关

- `POST /toggle-favorite` - 切换收藏状态
- `GET /get-favorites` - 获取用户收藏列表

#### 分享相关

- `POST /record-share` - 记录分享行为
- `GET /generate-share-image` - 生成分享图卡

### 前端组件

#### FavoriteButton

```dart
FavoriteButton(
  contentId: 'xxx',
  isFavorited: true,
  onToggle: () => bloc.add(ToggleFavorite()),
)
```

#### ShareButton

```dart
ShareButton(
  contentId: 'xxx',
  title: '标题',
  summary: '摘要',
  onShareRecorded: () => bloc.add(RecordShare()),
)
```

## 使用指南

### 后端部署

1. 运行数据库迁移：

```bash
cd dacong-api/supabase
supabase db push
```

2. 部署 Edge Functions：

```bash
supabase functions deploy toggle-favorite
supabase functions deploy get-favorites
supabase functions deploy record-share
supabase functions deploy generate-share-image
```

### 前端集成

1. 安装依赖：

```bash
cd dacong-client
flutter pub get
```

2. 在内容详情页面使用组件：

```dart
import 'package:dacong_client/presentation/widgets/favorite_button.dart';
import 'package:dacong_client/presentation/widgets/share_button.dart';

// 在 AppBar 或内容区域添加
Row(
  children: [
    FavoriteButton(
      contentId: content.id,
      isFavorited: state.isFavorited,
      onToggle: () {
        context.read<ContentDetailBloc>().add(
          ToggleFavorite(content.id),
        );
      },
    ),
    ShareButton(
      contentId: content.id,
      title: content.title,
      summary: content.summary,
      onShareRecorded: () {
        context.read<ContentDetailBloc>().add(
          RecordShare(content.id, 'system'),
        );
      },
    ),
  ],
)
```

## 数据统计

### 收藏统计

- 用户收藏总数
- 内容被收藏次数
- 收藏趋势分析

### 分享统计

- 分享总数
- 各平台分享占比
- 分享用户数（去重）
- 分享时间分布

### 查询示例

```sql
-- 获取内容分享统计
SELECT * FROM content_share_stats WHERE content_id = 'xxx';

-- 获取用户收藏详情
SELECT * FROM user_favorites_detail WHERE user_id = 'xxx';
```

## 安全性

### RLS 策略

- 用户只能查看和管理自己的收藏
- 分享记录支持匿名，但用户只能查看自己的记录
- 所有操作都经过身份验证（分享除外）

### 数据验证

- 使用 Zod 进行请求参数验证
- UUID 格式验证
- 平台枚举值验证

## 性能优化

### 数据库索引

- `idx_favorites_user_id` - 用户收藏查询
- `idx_favorites_content_id` - 内容收藏统计
- `idx_shares_content_id` - 内容分享统计
- `idx_shares_platform` - 平台分享分析

### 缓存策略

- 收藏状态可缓存在客户端
- 分享统计可使用物化视图
- API 响应可添加 CDN 缓存

## 扩展功能

### 已实现

- ✅ 基础收藏功能
- ✅ 基础分享功能
- ✅ 分享统计
- ✅ 收藏列表

### 待实现

- ⏳ 分享图卡生成（已预留接口）
- ⏳ 社交媒体直接分享
- ⏳ 收藏夹分类
- ⏳ 收藏内容搜索

## 测试

### 单元测试

```bash
# 后端测试
cd dacong-api/supabase/functions
deno test

# 前端测试
cd dacong-client
flutter test
```

### 集成测试

1. 测试收藏功能
   - 添加收藏
   - 取消收藏
   - 查看收藏列表

2. 测试分享功能
   - 系统分享
   - 复制链接
   - 记录分享

## 故障排查

### 常见问题

1. **收藏失败**
   - 检查用户是否已登录
   - 检查内容 ID 是否有效
   - 查看 RLS 策略是否正确

2. **分享记录失败**
   - 检查平台参数是否在枚举范围内
   - 查看数据库触发器是否正常

3. **收藏列表为空**
   - 确认用户已收藏内容
   - 检查 RLS 策略
   - 查看视图定义是否正确

## 监控指标

- 收藏成功率
- 分享成功率
- API 响应时间
- 数据库查询性能

## 更新日志

### v1.0.0 (2026-04-18)

- ✅ 实现基础收藏功能
- ✅ 实现基础分享功能
- ✅ 添加数据统计视图
- ✅ 创建 Flutter 组件
- ✅ 完善 API 文档

## 相关文档

- [API 文档](../dacong-api/docs/api.md)
- [数据库设计](../dacong-api/docs/database.md)
- [Flutter 组件库](../dacong-client/docs/components.md)
