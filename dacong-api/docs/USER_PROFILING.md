# 用户画像系统文档

## 概述

用户画像系统通过追踪和分析用户行为，构建完整的用户画像，实现个性化推荐和精准运营。

## 核心功能

### 1. 用户行为追踪

系统支持以下事件类型的追踪：

#### 导航类事件
- `page_view` - 页面浏览
- `link_click` - 外链点击

#### 内容类事件
- `content_view` - 内容查看
- `content_click` - 内容点击
- `scroll_depth` - 滚动深度
- `read_time` - 阅读时长
- `video_play` - 视频播放
- `video_pause` - 视频暂停
- `video_complete` - 视频完成

#### 交互类事件
- `search` - 搜索行为
- `search_result_click` - 搜索结果点击
- `favorite_add` - 添加收藏
- `favorite_remove` - 取消收藏
- `share` - 分享内容
- `comment` - 评论
- `comment_like` - 点赞评论
- `feedback` - 反馈（有用/无用）
- `download` - 下载

#### 系统类事件
- `session_start` - 会话开始
- `session_end` - 会话结束
- `error` - 错误事件

### 2. 用户画像计算

用户画像包含以下维度：

#### 兴趣标签
基于用户浏览和互动的内容，自动提取兴趣标签，每个标签包含：
- `tag` - 标签名称
- `score` - 兴趣评分（0-1）

计算规则：
- 内容浏览：权重 1
- 收藏：权重 3
- 分享：权重 2
- 评论：权重 2

#### 活跃度等级
- `new` - 新用户
- `active` - 活跃用户（最近7天内活跃，且事件数≥10）
- `inactive` - 不活跃用户（7-30天未活跃）
- `churned` - 流失用户（30天以上未活跃）

#### 活跃度评分（0-100分）
- 活跃天数得分（最高40分）：最近30天活跃天数 × 1.33
- 平均事件数得分（最高60分）：平均每天事件数 × 3

#### 偏好场景
统计用户最常浏览的内容场景，包含：
- `scenario` - 场景名称
- `frequency` - 访问频次

#### 参与度评分（0-100分）
- 浏览：最高30分（每次0.5分）
- 收藏：最高30分（每次3分）
- 分享：最高20分（每次4分）
- 评论：最高20分（每次5分）

#### 用户分群
- `new_user` - 新用户（注册≤7天）
- `power_user` - 重度用户（活跃度≥70，参与度≥60）
- `casual_user` - 轻度用户（中等活跃度和参与度）
- `at_risk` - 流失风险用户（活跃度<30或参与度<20）

### 3. RFM 分析

RFM 模型用于用户价值分层：

#### R - Recency（最近活跃）
- 评分1-5：距离最后活跃天数越少，分数越高
- 1分：>14天
- 2分：8-14天
- 3分：4-7天
- 4分：2-3天
- 5分：≤1天

#### F - Frequency（活跃频率）
- 评分1-5：30天内活跃天数越多，分数越高
- 1分：<2天
- 2分：2-4天
- 3分：5-9天
- 4分：10-19天
- 5分：≥20天

#### M - Monetary（价值贡献）
- 评分1-5：综合互动价值越高，分数越高
- 计算公式：浏览×1 + 收藏×3 + 分享×5 + 评论×4
- 1分：<5
- 2分：5-19
- 3分：20-49
- 4分：50-99
- 5分：≥100

#### RFM 分群
- `champions` - 冠军用户（R≥4, F≥4, M≥4）
- `loyal` - 忠诚用户（R≥3, F≥3, M≥3）
- `potential` - 潜力用户（R≥4, F≤2）
- `at_risk` - 流失风险（R≤2, F≥3）
- `lost` - 流失用户（R≤2, F≤2）
- `casual` - 其他用户

### 4. 个性化推荐

基于用户画像的内容推荐算法：

#### 相关性评分（0-100分）
- 标签匹配度（0-50分）：每个匹配标签10分
- 场景匹配度（0-30分）：场景访问频次 × 0.5
- 内容热度（0-20分）：归一化浏览量 × 20

#### 推荐策略
1. 优先推荐与用户兴趣标签匹配的内容
2. 其次推荐用户偏好场景的内容
3. 排除7天内已查看的内容
4. 如果用户画像不存在，推荐热门内容

## API 使用

### 1. 计算用户画像

**Endpoint:** `POST /functions/v1/compute-user-profile`

**请求体:**
```json
{
  "user_id": "uuid"
}
```

**响应:**
```json
{
  "success": true,
  "profile": {
    "user_id": "uuid",
    "interests": [
      {"tag": "职场沟通", "score": 0.85},
      {"tag": "团队管理", "score": 0.72}
    ],
    "activity_level": "active",
    "activity_score": 75.5,
    "preferred_scenarios": [
      {"scenario": "职场", "frequency": 45},
      {"scenario": "生活", "frequency": 23}
    ],
    "engagement_score": 68.0,
    "user_segment": "power_user",
    "stats": {
      "total_views": 120,
      "total_favorites": 15,
      "total_shares": 8,
      "total_comments": 5,
      "total_searches": 20
    }
  }
}
```

### 2. 批量更新用户画像

**Endpoint:** `POST /functions/v1/batch-update-profiles`

**请求体:**
```json
{
  "limit": 100
}
```

**响应:**
```json
{
  "success": true,
  "summary": {
    "total": 95,
    "succeeded": 93,
    "failed": 2
  },
  "failures": [
    {
      "user_id": "uuid",
      "error": "error message"
    }
  ]
}
```

### 3. 获取个性化推荐

**SQL 函数:**
```sql
SELECT * FROM get_personalized_recommendations(
  'user_id',  -- 用户ID
  10          -- 推荐数量
);
```

**返回字段:**
- `content_id` - 内容ID
- `title` - 内容标题
- `content_type` - 内容类型
- `scenario` - 场景
- `relevance_score` - 相关性评分
- `reason` - 推荐理由

### 4. 获取用户完整画像

**SQL 函数:**
```sql
SELECT get_user_profile_detail('user_id');
```

**返回 JSON 包含:**
- 基本信息（email, 注册日期等）
- 画像信息（兴趣、活跃度、分群等）
- 行为统计（浏览、收藏、分享等）
- RFM 评分
- 最近20条活动记录

### 5. 查找相似用户

**SQL 函数:**
```sql
SELECT * FROM get_similar_users(
  'user_id',  -- 用户ID
  10          -- 返回数量
);
```

**返回字段:**
- `user_id` - 相似用户ID
- `email` - 邮箱
- `similarity_score` - 相似度评分
- `common_interests` - 共同兴趣
- `common_scenarios` - 共同场景

### 6. 获取用户行为时间线

**SQL 函数:**
```sql
SELECT * FROM get_user_timeline(
  'user_id',  -- 用户ID
  30,         -- 天数
  100         -- 限制数量
);
```

## 数据库表结构

### user_profiles
用户画像主表

| 字段 | 类型 | 说明 |
|------|------|------|
| user_id | UUID | 用户ID（主键） |
| interests | JSONB | 兴趣标签 |
| activity_level | VARCHAR | 活跃度等级 |
| activity_score | FLOAT | 活跃度评分 |
| preferred_scenarios | JSONB | 偏好场景 |
| engagement_score | FLOAT | 参与度评分 |
| user_segment | VARCHAR | 用户分群 |
| total_views | INT | 总浏览数 |
| total_favorites | INT | 总收藏数 |
| total_shares | INT | 总分享数 |
| total_comments | INT | 总评论数 |
| last_active_at | TIMESTAMPTZ | 最后活跃时间 |

### user_sessions
用户会话表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 会话ID（主键） |
| user_id | UUID | 用户ID |
| session_id | UUID | 会话标识 |
| started_at | TIMESTAMPTZ | 开始时间 |
| ended_at | TIMESTAMPTZ | 结束时间 |
| duration | INT | 时长（秒） |
| page_views | INT | 页面浏览数 |
| content_views | INT | 内容查看数 |
| searches | INT | 搜索次数 |
| interactions | INT | 互动次数 |

### user_rfm_scores
RFM 评分表

| 字段 | 类型 | 说明 |
|------|------|------|
| user_id | UUID | 用户ID（主键） |
| recency_days | INT | 最近活跃天数 |
| recency_score | INT | R评分（1-5） |
| frequency_count | INT | 活跃天数 |
| frequency_score | INT | F评分（1-5） |
| monetary_value | FLOAT | 价值贡献 |
| monetary_score | INT | M评分（1-5） |
| rfm_score | VARCHAR | RFM组合评分 |
| rfm_segment | VARCHAR | RFM分群 |

### user_interest_history
用户兴趣演化历史表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 记录ID（主键） |
| user_id | UUID | 用户ID |
| interests | JSONB | 兴趣快照 |
| change_type | VARCHAR | 变化类型 |
| change_summary | TEXT | 变化描述 |
| created_at | TIMESTAMPTZ | 创建时间 |

## 视图

### v_user_profiles_complete
用户画像完整视图，包含用户基本信息、画像数据和RFM评分

### v_user_segment_stats
用户分群统计视图，展示各分群的用户数量和平均指标

### v_active_users
活跃用户视图，按活跃度评分排序

### v_at_risk_users
流失风险用户视图，按最后活跃时间排序

### v_rfm_segment_stats
RFM分群统计视图

### v_user_behavior_trends
用户行为趋势视图（最近30天）

### v_user_interest_distribution
用户兴趣分布视图

### v_scenario_preference_distribution
场景偏好分布视图

### v_user_retention
用户留存分析视图

## 定时任务

### 1. 批量更新用户画像
**建议频率:** 每小时执行一次

```sql
SELECT * FROM batch_update_user_profiles(100);
```

### 2. 计算 RFM 评分
**建议频率:** 每天执行一次

```sql
-- 为所有活跃用户计算 RFM
DO $$
DECLARE
  v_user RECORD;
BEGIN
  FOR v_user IN
    SELECT DISTINCT user_id
    FROM analytics_events
    WHERE created_at >= NOW() - INTERVAL '30 days'
  LOOP
    PERFORM calculate_rfm_scores(v_user.user_id);
  END LOOP;
END $$;
```

### 3. 记录兴趣演化
**建议频率:** 每周执行一次

```sql
-- 记录用户兴趣变化
INSERT INTO user_interest_history (user_id, interests, change_type)
SELECT
  user_id,
  interests,
  'update'
FROM user_profiles
WHERE updated_at >= NOW() - INTERVAL '7 days';
```

## 性能优化

### 索引策略
- 所有 JSONB 字段使用 GIN 索引
- 时间字段使用 BTREE 索引
- 分群和评分字段使用 BTREE 索引

### 查询优化
- 使用物化视图缓存复杂统计
- 画像计算使用异步队列
- 批量更新限制并发数

### 数据归档
- 定期归档90天前的事件数据
- 保留用户画像历史快照

## 监控指标

### 系统健康度
- 画像更新延迟
- 画像计算成功率
- 推荐响应时间

### 业务指标
- 各分群用户占比
- 平均活跃度评分
- 平均参与度评分
- 推荐点击率

## 最佳实践

### 1. 事件追踪
- 在客户端埋点时包含完整的上下文信息
- 使用统一的 session_id 追踪用户会话
- 记录设备信息用于多端分析

### 2. 画像更新
- 新用户首次活跃后立即计算画像
- 活跃用户每小时更新一次
- 不活跃用户每天更新一次

### 3. 推荐策略
- 新用户推荐热门内容
- 活跃用户基于兴趣推荐
- 流失风险用户推荐高互动内容

### 4. 隐私保护
- 所有画像数据启用 RLS
- 用户只能查看自己的画像
- 管理员需要权限才能查看

## 故障排查

### 画像未更新
1. 检查事件是否正常记录到 `analytics_events`
2. 检查触发器是否正常执行
3. 手动调用 `update_user_profile(user_id)` 测试

### 推荐结果为空
1. 检查用户画像是否存在
2. 检查内容是否已发布
3. 检查是否所有内容都已被用户查看

### RFM 评分异常
1. 检查事件数据是否完整
2. 手动调用 `calculate_rfm_scores(user_id)` 测试
3. 检查评分规则是否需要调整

## 扩展功能

### 1. 协同过滤推荐
基于相似用户的行为进行推荐

### 2. 内容冷启动
为新内容快速积累曝光

### 3. A/B 测试
测试不同推荐策略的效果

### 4. 实时画像
使用流式计算实现实时画像更新

## 相关文档

- [数据分析文档](./ANALYTICS.md)
- [推荐系统文档](./RECOMMENDATION.md)
- [API 文档](./API.md)
