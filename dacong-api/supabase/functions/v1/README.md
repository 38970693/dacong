# API v1

这是 API 的第一个版本，包含所有核心功能。

## 状态
- **当前状态**: 稳定
- **弃用状态**: 未弃用
- **支持截止日期**: TBD

## 端点列表

### 推荐系统
- `GET /v1/recommend` - 获取场景推荐

### 搜索
- `GET /v1/search-content` - 搜索内容

### 内容管理
- `GET /v1/get-content-detail` - 获取内容详情
- `GET /v1/get-comments` - 获取评论
- `POST /v1/like-comment` - 点赞评论
- `POST /v1/report-comment` - 举报评论

### 用户功能
- `GET /v1/get-favorites` - 获取收藏列表
- `POST /v1/record-share` - 记录分享
- `POST /v1/generate-share-image` - 生成分享图片

### 分析统计
- `GET /v1/get-analytics` - 获取分析数据
- `GET /v1/get-realtime-stats` - 获取实时统计
- `GET /v1/get-trend-data` - 获取趋势数据
- `GET /v1/get-weekly-report` - 获取周报
- `GET /v1/get-performance-metrics` - 获取性能指标

### 管理功能
- `POST /v1/admin-user-management` - 用户管理
- `POST /v1/admin-content-management` - 内容管理
- `POST /v1/admin-comment-moderation` - 评论审核

## 迁移指南

如需迁移到 v2，请参考 [迁移指南](../../docs/API_VERSIONING.md#从-v1-迁移到-v2)。
