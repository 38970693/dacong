# 数据分析架构设计

> 版本：v1.0  
> 更新日期：2026-04-17  
> 负责人：Product Team

---

## 1. 问题陈述

### 1.1 核心问题

**我们需要回答的关键问题：**
- 用户在使用什么功能？哪些场景最受欢迎？
- 用户在哪里流失？为什么不继续使用？
- 哪些内容最有价值？AI生成的质量如何？
- 产品性能如何？哪里有瓶颈？
- 业务增长如何？留存、转化、活跃度趋势？

**不解决的代价：**
- 盲目开发功能，浪费资源
- 无法发现用户痛点，留存率低
- 内容质量无法量化，AI成本失控
- 性能问题无法定位，用户体验差
- 无法向投资人/管理层证明产品价值

### 1.2 用户证据

**当前痛点：**
- 开发团队：不知道用户在用什么功能，优先级靠猜
- 运营团队：不知道内容效果，无法优化推荐策略
- 管理层：没有数据看板，无法做决策

---

## 2. 目标与成功指标

| 目标 | 指标 | 当前基线 | 目标值 | 度量窗口 |
|------|------|---------|--------|---------|
| 建立数据收集能力 | 事件覆盖率 | 0% | 100% | Week 3 完成 |
| 可视化核心指标 | 看板完成度 | 0% | 80% | Week 3 完成 |
| 支持产品决策 | 数据驱动决策占比 | 0% | 50% | Week 4 开始 |
| 降低分析成本 | 查询响应时间 | N/A | <2s | Week 3 完成 |

---

## 3. 分析维度

### 3.1 用户行为分析

**核心问题：用户在做什么？**

| 分析项 | 关键指标 | 业务价值 |
|--------|---------|---------|
| 页面浏览 | PV、UV、停留时长、跳出率 | 了解用户兴趣点 |
| 场景选择 | 各场景点击率、转化率 | 优化场景推荐 |
| 内容查看 | 内容详情打开率、完读率 | 评估内容质量 |
| 搜索行为 | 搜索词、搜索结果点击率 | 优化搜索算法 |
| 收藏行为 | 收藏率、取消收藏率 | 了解用户偏好 |
| 分享行为 | 分享率、分享渠道 | 评估传播效果 |

**用户旅程漏斗：**
```
首页访问 (100%)
  ↓ 80%
场景选择
  ↓ 50%
推荐列表
  ↓ 30%
内容详情
  ↓ 10%
收藏/分享
```

**关键问题：**
- 哪个环节流失最严重？
- 不同场景的转化率差异？
- 新用户 vs 老用户行为差异？

---

### 3.2 内容分析

**核心问题：什么内容有价值？**

| 分析项 | 关键指标 | 业务价值 |
|--------|---------|---------|
| 内容热度 | 浏览量、收藏量、分享量 | 识别爆款内容 |
| 内容质量 | 有用率、完读率、停留时长 | 评估AI生成质量 |
| 内容转化 | 点击率、转化率 | 优化推荐策略 |
| 内容留存 | 回访率、重复查看率 | 评估长期价值 |

**内容评分模型：**
```
Content Score = 
  0.3 * 浏览量归一化 +
  0.3 * 有用率 +
  0.2 * 收藏率 +
  0.2 * 分享率
```

**关键问题：**
- 哪些场景的内容最受欢迎？
- AI生成的内容质量如何？
- 哪些内容类型需要优化？

---

### 3.3 性能分析

**核心问题：系统性能如何？**

| 分析项 | 关键指标 | 告警阈值 |
|--------|---------|---------|
| API性能 | 响应时间、QPS、错误率 | P95 > 2s 或 错误率 > 1% |
| 页面性能 | FCP、LCP、TTI | LCP > 2.5s |
| 数据库性能 | 查询时间、连接数 | 慢查询 > 1s |
| 爬虫性能 | 成功率、采集量 | 成功率 < 90% |

**性能监控看板：**
- 实时QPS曲线
- API响应时间分布
- 错误率趋势
- 慢查询Top 10

---

### 3.4 业务分析

**核心问题：产品增长如何？**

| 分析项 | 关键指标 | 目标值 |
|--------|---------|--------|
| 用户增长 | DAU、MAU、新增用户 | Week 4: 100 DAU |
| 用户留存 | 次日留存、7日留存、30日留存 | 7日留存 > 30% |
| 用户活跃 | 人均使用时长、人均浏览量 | 人均 > 5 PV/天 |
| 内容消费 | 内容浏览量、内容发布量 | 日均 > 500 PV |

**北极星指标：**
```
周活跃用户数 (WAU)
= 7天内至少查看过1个内容详情的用户数
```

**关键问题：**
- 用户增长是否健康？
- 留存率是否达标？
- 哪些渠道带来的用户质量最高？

---

## 4. 技术方案

### 4.1 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter 客户端                         │
│              AnalyticsService (埋点SDK)                  │
└─────────────────────────────────────────────────────────┘
                         ↓ HTTPS
┌─────────────────────────────────────────────────────────┐
│                 Supabase Edge Functions                  │
│              /analytics/track (事件收集)                 │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                 PostgreSQL (Supabase)                    │
│         analytics_events (原始事件表)                    │
│         analytics_daily (每日汇总表)                     │
│         analytics_content (内容统计表)                   │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│              数据可视化 (Metabase / 自建)                │
│         实时看板 + 自定义报表 + 告警                     │
└─────────────────────────────────────────────────────────┘
```

### 4.2 事件追踪设计

**事件分类：**

| 事件类型 | 事件名称 | 触发时机 | 关键属性 |
|---------|---------|---------|---------|
| 页面事件 | page_view | 页面加载完成 | page_name, referrer |
| 场景事件 | scenario_click | 点击场景卡片 | scenario_id, scenario_name |
| 内容事件 | content_view | 打开内容详情 | content_id, content_type |
| 搜索事件 | search | 执行搜索 | query, result_count |
| 收藏事件 | favorite_add | 添加收藏 | content_id |
| 分享事件 | share | 点击分享 | content_id, platform |
| 反馈事件 | feedback | 点击有用/无用 | content_id, is_helpful |

**事件属性标准：**
```json
{
  "event_type": "content_view",
  "user_id": "uuid-or-anonymous",
  "session_id": "session-uuid",
  "timestamp": "2026-04-17T14:00:00Z",
  "properties": {
    "content_id": "uuid",
    "content_type": "recommendation",
    "scenario": "coding",
    "referrer": "home_page"
  },
  "device": {
    "platform": "web",
    "os": "Windows",
    "browser": "Chrome"
  }
}
```

### 4.3 数据存储设计

**原始事件表 (analytics_events)：**
```sql
CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type VARCHAR(50) NOT NULL,
  user_id UUID,  -- 可为空（匿名用户）
  session_id UUID NOT NULL,
  content_id UUID,  -- 可为空（非内容事件）
  properties JSONB,  -- 灵活存储事件属性
  device_info JSONB,  -- 设备信息
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引优化
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_user ON analytics_events(user_id);
CREATE INDEX idx_analytics_events_content ON analytics_events(content_id);
CREATE INDEX idx_analytics_events_created_at ON analytics_events(created_at DESC);
CREATE INDEX idx_analytics_events_type_created ON analytics_events(event_type, created_at DESC);
```

**每日汇总表 (analytics_daily)：**
```sql
CREATE TABLE analytics_daily (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,
  metric_type VARCHAR(50) NOT NULL,  -- 'dau', 'pv', 'content_view'等
  metric_value BIGINT NOT NULL,
  dimensions JSONB,  -- 维度信息（场景、内容类型等）
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(date, metric_type, dimensions)
);

CREATE INDEX idx_analytics_daily_date ON analytics_daily(date DESC);
CREATE INDEX idx_analytics_daily_type ON analytics_daily(metric_type);
```

**内容统计表 (analytics_content)：**
```sql
CREATE TABLE analytics_content (
  content_id UUID PRIMARY KEY,
  view_count BIGINT DEFAULT 0,
  unique_view_count BIGINT DEFAULT 0,
  favorite_count BIGINT DEFAULT 0,
  share_count BIGINT DEFAULT 0,
  helpful_count BIGINT DEFAULT 0,
  unhelpful_count BIGINT DEFAULT 0,
  avg_read_time FLOAT,  -- 平均阅读时长（秒）
  last_viewed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_analytics_content_view_count ON analytics_content(view_count DESC);
CREATE INDEX idx_analytics_content_helpful_rate ON analytics_content((helpful_count::float / NULLIF(helpful_count + unhelpful_count, 0)) DESC);
```

### 4.4 数据处理流程

**实时处理：**
```sql
-- 触发器：更新内容统计
CREATE OR REPLACE FUNCTION update_content_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.event_type = 'content_view' THEN
    INSERT INTO analytics_content (content_id, view_count, unique_view_count, last_viewed_at)
    VALUES (NEW.content_id, 1, 1, NEW.created_at)
    ON CONFLICT (content_id) DO UPDATE SET
      view_count = analytics_content.view_count + 1,
      last_viewed_at = NEW.created_at;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_content_stats
AFTER INSERT ON analytics_events
FOR EACH ROW EXECUTE FUNCTION update_content_stats();
```

**定时汇总（每日凌晨执行）：**
```sql
-- 计算每日DAU
INSERT INTO analytics_daily (date, metric_type, metric_value)
SELECT 
  CURRENT_DATE - 1 as date,
  'dau' as metric_type,
  COUNT(DISTINCT user_id) as metric_value
FROM analytics_events
WHERE created_at >= CURRENT_DATE - 1
  AND created_at < CURRENT_DATE
  AND user_id IS NOT NULL;

-- 计算每日PV
INSERT INTO analytics_daily (date, metric_type, metric_value)
SELECT 
  CURRENT_DATE - 1 as date,
  'pv' as metric_type,
  COUNT(*) as metric_value
FROM analytics_events
WHERE created_at >= CURRENT_DATE - 1
  AND created_at < CURRENT_DATE
  AND event_type = 'page_view';
```

### 4.5 数据可视化方案

**方案对比：**

| 方案 | 优势 | 劣势 | 成本 | 推荐度 |
|------|------|------|------|--------|
| Metabase | 开源、易用、SQL查询 | 定制化弱 | 免费 | ⭐⭐⭐⭐⭐ |
| Grafana | 强大、插件多 | 学习曲线陡 | 免费 | ⭐⭐⭐⭐ |
| 自建看板 | 完全定制 | 开发成本高 | 高 | ⭐⭐⭐ |
| Supabase Dashboard | 集成好 | 功能有限 | 免费 | ⭐⭐⭐ |

**推荐方案：Metabase（开源版）**

**核心看板：**

1. **实时概览看板**
   - 今日DAU、PV、新增用户
   - 实时在线用户数
   - 今日热门内容Top 10
   - 今日错误率、API响应时间

2. **用户行为看板**
   - 用户旅程漏斗
   - 各场景点击率
   - 内容查看分布
   - 搜索词云

3. **内容分析看板**
   - 内容热度排行
   - 内容有用率分布
   - AI生成质量趋势
   - 内容类型占比

4. **业务增长看板**
   - DAU/MAU趋势
   - 留存率曲线
   - 新增用户来源
   - 用户活跃度分布

---

## 5. 埋点SDK设计

### 5.1 SDK架构

```dart
// lib/core/analytics/
├── analytics_service.dart      // 核心服务
├── event_tracker.dart          // 事件追踪器
├── analytics_events.dart       // 事件定义
├── analytics_config.dart       // 配置
└── analytics_storage.dart      // 本地缓存
```

### 5.2 核心代码

**AnalyticsService：**
```dart
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final _supabase = Supabase.instance.client;
  final _eventQueue = <AnalyticsEvent>[];
  Timer? _flushTimer;

  // 初始化
  Future<void> init() async {
    // 启动定时上报（每30秒或队列满100条）
    _flushTimer = Timer.periodic(Duration(seconds: 30), (_) => flush());
  }

  // 追踪事件
  void track(String eventType, {Map<String, dynamic>? properties}) {
    final event = AnalyticsEvent(
      eventType: eventType,
      userId: _getCurrentUserId(),
      sessionId: _getSessionId(),
      properties: properties,
      deviceInfo: _getDeviceInfo(),
      timestamp: DateTime.now(),
    );

    _eventQueue.add(event);

    // 队列满100条立即上报
    if (_eventQueue.length >= 100) {
      flush();
    }
  }

  // 上报事件
  Future<void> flush() async {
    if (_eventQueue.isEmpty) return;

    final events = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    try {
      await _supabase.functions.invoke(
        'analytics-track',
        body: {'events': events.map((e) => e.toJson()).toList()},
      );
    } catch (e) {
      // 失败重新加入队列
      _eventQueue.addAll(events);
      print('Analytics flush failed: $e');
    }
  }

  // 页面浏览
  void trackPageView(String pageName, {String? referrer}) {
    track(AnalyticsEvents.pageView, properties: {
      'page_name': pageName,
      'referrer': referrer,
    });
  }

  // 内容查看
  void trackContentView(String contentId, String contentType, {String? scenario}) {
    track(AnalyticsEvents.contentView, properties: {
      'content_id': contentId,
      'content_type': contentType,
      'scenario': scenario,
    });
  }

  // 搜索
  void trackSearch(String query, int resultCount) {
    track(AnalyticsEvents.search, properties: {
      'query': query,
      'result_count': resultCount,
    });
  }

  // 收藏
  void trackFavorite(String contentId, bool isAdd) {
    track(isAdd ? AnalyticsEvents.favoriteAdd : AnalyticsEvents.favoriteRemove, 
      properties: {'content_id': contentId});
  }

  // 分享
  void trackShare(String contentId, String platform) {
    track(AnalyticsEvents.share, properties: {
      'content_id': contentId,
      'platform': platform,
    });
  }

  // 反馈
  void trackFeedback(String contentId, bool isHelpful) {
    track(AnalyticsEvents.feedback, properties: {
      'content_id': contentId,
      'is_helpful': isHelpful,
    });
  }

  String? _getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  String _getSessionId() {
    // 从本地存储获取或生成新的session_id
    return 'session-uuid';
  }

  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': 'web',  // 或 'android', 'ios'
      'os': 'Windows',
      'browser': 'Chrome',
    };
  }

  void dispose() {
    _flushTimer?.cancel();
    flush();
  }
}
```

**AnalyticsEvents（事件常量）：**
```dart
class AnalyticsEvents {
  static const String pageView = 'page_view';
  static const String scenarioClick = 'scenario_click';
  static const String contentView = 'content_view';
  static const String search = 'search';
  static const String favoriteAdd = 'favorite_add';
  static const String favoriteRemove = 'favorite_remove';
  static const String share = 'share';
  static const String feedback = 'feedback';
}
```

### 5.3 使用示例

```dart
// 在页面中使用
class ContentDetailPage extends StatefulWidget {
  final String contentId;

  @override
  void initState() {
    super.initState();
    
    // 追踪页面浏览
    AnalyticsService().trackPageView('content_detail');
    
    // 追踪内容查看
    AnalyticsService().trackContentView(
      contentId,
      'recommendation',
      scenario: 'coding',
    );
  }

  void _onFavoritePressed() {
    // 追踪收藏
    AnalyticsService().trackFavorite(contentId, true);
  }

  void _onSharePressed(String platform) {
    // 追踪分享
    AnalyticsService().trackShare(contentId, platform);
  }
}
```

---

## 6. 实施计划

### 6.1 Day 1-2：基础设施

**任务：**
- [ ] 创建数据库表（analytics_events, analytics_daily, analytics_content）
- [ ] 创建Edge Function（analytics-track）
- [ ] 实现埋点SDK（AnalyticsService）
- [ ] 集成到客户端（main.dart初始化）

**验收标准：**
- 数据库表创建成功
- Edge Function可以接收事件
- SDK可以发送事件到服务端
- 事件数据正确存储到数据库

### 6.2 Day 3-4：核心埋点

**任务：**
- [ ] 实现页面浏览埋点（所有页面）
- [ ] 实现内容查看埋点（详情页）
- [ ] 实现搜索埋点（搜索页）
- [ ] 实现收藏/分享/反馈埋点

**验收标准：**
- 所有核心事件都能正确追踪
- 事件属性完整准确
- 无性能影响（<50ms）

### 6.3 Day 5-6：数据处理

**任务：**
- [ ] 实现实时统计触发器
- [ ] 实现每日汇总定时任务
- [ ] 创建常用查询视图
- [ ] 优化查询性能

**验收标准：**
- 内容统计实时更新
- 每日汇总准确无误
- 查询响应时间<2s

### 6.4 Day 7：数据可视化

**任务：**
- [ ] 部署Metabase
- [ ] 连接Supabase数据库
- [ ] 创建核心看板（4个）
- [ ] 配置告警规则

**验收标准：**
- Metabase可以访问
- 看板数据准确
- 告警规则生效

---

## 7. 风险与应对

### 7.1 性能风险

**风险：大量事件写入影响数据库性能**
- 应对：批量写入（100条/批）、异步处理、分表存储

**风险：查询慢影响看板加载**
- 应对：创建索引、使用汇总表、缓存查询结果

### 7.2 数据质量风险

**风险：埋点遗漏或错误**
- 应对：代码Review、自动化测试、数据校验

**风险：匿名用户无法追踪**
- 应对：使用session_id、设备指纹

### 7.3 成本风险

**风险：数据量增长导致存储成本上升**
- 应对：定期归档历史数据、压缩存储

---

## 8. 成功标准

**Week 3 结束时：**
- [ ] 所有核心事件埋点完成（8个事件）
- [ ] 数据正确存储到数据库
- [ ] 4个核心看板上线
- [ ] 查询响应时间<2s
- [ ] 无性能影响（客户端<50ms，服务端<100ms）

**Week 4 开始时：**
- [ ] 至少1个产品决策基于数据做出
- [ ] 识别出至少3个优化点
- [ ] 团队开始使用看板做日常分析

---

## 9. 附录

### 9.1 常用SQL查询

**今日DAU：**
```sql
SELECT COUNT(DISTINCT user_id) as dau
FROM analytics_events
WHERE created_at >= CURRENT_DATE
  AND user_id IS NOT NULL;
```

**内容热度排行：**
```sql
SELECT 
  c.content_id,
  p.title,
  c.view_count,
  c.favorite_count,
  c.helpful_count::float / NULLIF(c.helpful_count + c.unhelpful_count, 0) as helpful_rate
FROM analytics_content c
JOIN published_content p ON c.content_id = p.id
ORDER BY c.view_count DESC
LIMIT 10;
```

**用户旅程漏斗：**
```sql
WITH funnel AS (
  SELECT 
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN session_id END) as step1,
    COUNT(DISTINCT CASE WHEN event_type = 'scenario_click' THEN session_id END) as step2,
    COUNT(DISTINCT CASE WHEN event_type = 'content_view' THEN session_id END) as step3,
    COUNT(DISTINCT CASE WHEN event_type IN ('favorite_add', 'share') THEN session_id END) as step4
  FROM analytics_events
  WHERE created_at >= CURRENT_DATE - 7
)
SELECT 
  'Page View' as step, step1 as count, 100.0 as rate FROM funnel
UNION ALL
SELECT 'Scenario Click', step2, step2::float / step1 * 100 FROM funnel
UNION ALL
SELECT 'Content View', step3, step3::float / step1 * 100 FROM funnel
UNION ALL
SELECT 'Engage', step4, step4::float / step1 * 100 FROM funnel;
```

### 9.2 参考资料

- [Segment Spec](https://segment.com/docs/connections/spec/)
- [Google Analytics 4 Events](https://developers.google.com/analytics/devguides/collection/ga4/events)
- [Mixpanel Best Practices](https://mixpanel.com/blog/event-tracking-best-practices/)
