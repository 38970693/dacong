# Week 3 实施计划：数据分析与运营后台

> 版本：v1.0  
> 更新日期：2026-04-17  
> 负责人：Product Team  
> 工期：7天

---

## 1. 目标概述

### 1.1 核心目标

**建立数据驱动的产品运营能力**

- 实现完整的用户行为追踪（8个核心事件）
- 搭建运营后台（内容审核、用户管理、数据看板）
- 建立数据分析体系（实时统计、趋势分析）
- 提升运营效率（人均审核50条/天）

### 1.2 成功标准

| 指标 | 目标值 | 验收方式 |
|------|--------|---------|
| 事件覆盖率 | 100% | 所有核心页面都有埋点 |
| 数据准确性 | 100% | 与实际行为一致 |
| 查询性能 | <2s | 所有看板查询响应时间 |
| 审核效率 | 50条/天 | 运营人员实测 |
| 后台可用性 | 100% | 所有功能正常工作 |

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                   Flutter 客户端                             │
│              AnalyticsService (埋点SDK)                      │
└─────────────────────────────────────────────────────────────┘
                         ↓ HTTPS
┌─────────────────────────────────────────────────────────────┐
│                 Supabase Edge Functions                      │
│              /analytics/track (事件收集)                     │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                 PostgreSQL (Supabase)                        │
│         analytics_events + analytics_daily + ...            │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│              Flutter Web 运营后台                            │
│         内容审核 + 用户管理 + 数据看板                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Day 1-2：数据分析基础设施

### 3.1 任务清单

**数据库设计（4小时）**
- [x] 创建 analytics_events 表
- [x] 创建 analytics_daily 表
- [x] 创建 analytics_content 表
- [x] 创建触发器（自动更新统计）
- [x] 创建常用视图
- [x] 配置RLS策略

**Edge Function（3小时）**
- [ ] 创建 analytics-track 函数
- [ ] 实现批量事件接收
- [ ] 实现数据验证
- [ ] 实现错误处理
- [ ] 部署到Supabase

**埋点SDK（5小时）**
- [x] 创建 AnalyticsService
- [x] 创建 AnalyticsEvents 常量
- [x] 创建 AnalyticsConfig 配置
- [ ] 实现批量上报逻辑
- [ ] 实现本地缓存
- [ ] 实现自动重试
- [ ] 集成到客户端 main.dart

**验收标准：**
- [ ] 数据库表创建成功
- [ ] Edge Function 可以接收事件
- [ ] SDK 可以发送事件到服务端
- [ ] 事件数据正确存储到数据库

### 3.2 关键代码

**Edge Function (analytics-track)：**
```typescript
// supabase/functions/analytics-track/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { events } = await req.json()

    if (!Array.isArray(events) || events.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Invalid events' }),
        { status: 400 }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 批量插入事件
    const { error } = await supabase
      .from('analytics_events')
      .insert(events)

    if (error) throw error

    return new Response(
      JSON.stringify({ success: true, count: events.length }),
      { status: 200 }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500 }
    )
  }
})
```

**集成到客户端：**
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(...);
  
  // 初始化分析服务
  await AnalyticsService().init();

  configureDependencies();
  runApp(const DaCongApp());
}
```

---

## 4. Day 3-4：核心埋点实现

### 4.1 任务清单

**页面浏览埋点（2小时）**
- [ ] 首页埋点
- [ ] 推荐列表页埋点
- [ ] 内容详情页埋点
- [ ] 搜索页埋点
- [ ] 收藏页埋点

**交互事件埋点（3小时）**
- [ ] 场景点击埋点
- [ ] 内容查看埋点
- [ ] 搜索埋点
- [ ] 收藏/取消收藏埋点
- [ ] 分享埋点
- [ ] 反馈埋点

**测试验证（3小时）**
- [ ] 单元测试（每个事件）
- [ ] 集成测试（完整流程）
- [ ] 性能测试（不影响UI）
- [ ] 数据验证（数据库检查）

**验收标准：**
- [ ] 所有核心事件都能正确追踪
- [ ] 事件属性完整准确
- [ ] 无性能影响（<50ms）
- [ ] 数据正确存储到数据库

### 4.2 埋点示例

**首页埋点：**
```dart
// lib/presentation/pages/home/home_page.dart
class HomePage extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    
    // 追踪页面浏览
    AnalyticsService().trackPageView('home');
  }
}
```

**场景点击埋点：**
```dart
// lib/presentation/widgets/scenario_card.dart
onTap: () {
  // 追踪场景点击
  AnalyticsService().trackScenarioClick(
    scenario.id,
    scenario.name,
  );
  
  // 跳转到推荐列表
  context.push('/recommendations/${scenario.id}');
}
```

**内容查看埋点：**
```dart
// lib/presentation/pages/content_detail/content_detail_page.dart
@override
void initState() {
  super.initState();
  
  // 追踪内容查看
  AnalyticsService().trackContentView(
    widget.contentId,
    'recommendation',
    scenario: widget.scenario,
    referrer: 'recommendation_list',
  );
}
```

---

## 5. Day 5：数据处理与优化

### 5.1 任务清单

**实时统计（3小时）**
- [x] 创建触发器（自动更新内容统计）
- [ ] 测试触发器性能
- [ ] 优化触发器逻辑

**定时汇总（3小时）**
- [x] 创建每日汇总函数
- [ ] 配置定时任务（pg_cron或外部）
- [ ] 测试汇总准确性

**查询优化（2小时）**
- [x] 创建常用视图
- [ ] 添加索引
- [ ] 测试查询性能

**验收标准：**
- [ ] 内容统计实时更新（<1s延迟）
- [ ] 每日汇总准确无误
- [ ] 查询响应时间<2s

### 5.2 定时任务配置

**使用 pg_cron（推荐）：**
```sql
-- 启用 pg_cron 扩展
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 每天凌晨1点执行汇总
SELECT cron.schedule(
  'daily-metrics',
  '0 1 * * *',
  $$SELECT calculate_daily_metrics()$$
);
```

**或使用外部调度器（GitHub Actions）：**
```yaml
# .github/workflows/daily-metrics.yml
name: Daily Metrics
on:
  schedule:
    - cron: '0 17 * * *'  # UTC 17:00 = 北京时间 01:00
jobs:
  calculate:
    runs-on: ubuntu-latest
    steps:
      - name: Call Supabase Function
        run: |
          curl -X POST \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_KEY }}" \
            https://your-project.supabase.co/rest/v1/rpc/calculate_daily_metrics
```

---

## 6. Day 6-7：运营后台开发

### 6.1 任务清单

**基础框架（3小时）**
- [x] 创建 dacong-admin 项目
- [x] 配置 Flutter Web
- [x] 实现登录页
- [x] 实现侧边栏导航
- [ ] 配置路由

**内容管理（5小时）**
- [x] 实现内容审核页面
- [ ] 实现审核操作（通过/拒绝/修改）
- [ ] 实现批量操作
- [ ] 实现快捷键
- [ ] 连接后端API

**用户管理（3小时）**
- [x] 实现用户列表页面
- [ ] 实现用户详情页面
- [ ] 实现用户封禁功能
- [ ] 实现搜索和筛选

**数据看板（3小时）**
- [x] 实现实时概览
- [ ] 实现热门内容排行
- [ ] 连接后端数据
- [ ] 实现自动刷新

**部署（2小时）**
- [ ] 配置环境变量
- [ ] 构建生产版本
- [ ] 部署到Vercel或Firebase Hosting
- [ ] 配置域名

**验收标准：**
- [ ] 管理员可以登录后台
- [ ] 可以审核AI生成的内容
- [ ] 可以查看用户列表
- [ ] 可以查看数据看板
- [ ] 人均审核效率达到50条/天

### 6.2 权限配置

**创建管理员账号：**
```sql
-- 1. 在 Supabase Auth 中创建用户
-- 2. 将用户添加到 admin_users 表
INSERT INTO admin_users (user_id, email, role, permissions)
VALUES (
  'user-uuid-from-auth',
  'admin@dacong.ai',
  'super_admin',
  '{
    "content": ["review", "edit", "publish", "delete"],
    "user": ["view", "ban"],
    "analytics": ["view"],
    "settings": ["view", "edit"]
  }'::jsonb
);
```

---

## 7. 风险与应对

### 7.1 技术风险

| 风险 | 可能性 | 影响 | 应对措施 |
|------|--------|------|---------|
| Edge Function 性能不足 | 中 | 高 | 批量处理、异步队列 |
| 数据库写入压力大 | 中 | 高 | 批量插入、索引优化 |
| 查询性能慢 | 中 | 中 | 汇总表、缓存 |
| Flutter Web 性能差 | 低 | 中 | 优化渲染、懒加载 |

### 7.2 进度风险

| 风险 | 可能性 | 影响 | 应对措施 |
|------|--------|------|---------|
| 埋点遗漏 | 中 | 中 | 代码Review、测试清单 |
| 后台功能不完善 | 中 | 低 | MVP优先、迭代优化 |
| 部署问题 | 低 | 中 | 提前测试、备用方案 |

### 7.3 数据质量风险

| 风险 | 可能性 | 影响 | 应对措施 |
|------|--------|------|---------|
| 事件丢失 | 中 | 高 | 本地缓存、重试机制 |
| 数据不准确 | 中 | 高 | 数据验证、人工抽查 |
| 匿名用户追踪困难 | 高 | 中 | 使用 session_id |

---

## 8. 测试计划

### 8.1 单元测试

**埋点SDK测试：**
```dart
// test/core/analytics/analytics_service_test.dart
void main() {
  group('AnalyticsService', () {
    test('should track page view', () async {
      final service = AnalyticsService();
      await service.init();
      
      service.trackPageView('home');
      
      expect(service.eventQueue.length, 1);
      expect(service.eventQueue.first.eventType, 'page_view');
    });

    test('should flush when queue is full', () async {
      final service = AnalyticsService();
      await service.init();
      
      for (int i = 0; i < 100; i++) {
        service.track('test_event');
      }
      
      // 应该自动上报
      await Future.delayed(Duration(seconds: 1));
      expect(service.eventQueue.length, 0);
    });
  });
}
```

### 8.2 集成测试

**完整流程测试：**
```dart
// integration_test/analytics_flow_test.dart
void main() {
  testWidgets('Analytics flow test', (tester) async {
    await tester.pumpWidget(const DaCongApp());
    
    // 1. 首页浏览
    await tester.pumpAndSettle();
    
    // 2. 点击场景
    await tester.tap(find.text('写代码'));
    await tester.pumpAndSettle();
    
    // 3. 查看内容
    await tester.tap(find.text('Cursor + DeepSeek'));
    await tester.pumpAndSettle();
    
    // 4. 验证事件已发送
    final events = await getEventsFromDatabase();
    expect(events.length, greaterThanOrEqualTo(3));
  });
}
```

### 8.3 性能测试

**埋点性能测试：**
```dart
void main() {
  test('Analytics should not block UI', () async {
    final stopwatch = Stopwatch()..start();
    
    AnalyticsService().trackPageView('test');
    
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(50));
  });
}
```

---

## 9. 部署清单

### 9.1 数据库迁移

```bash
# 1. 连接到 Supabase
psql "postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres"

# 2. 执行迁移
\i supabase/migrations/20260417_week3_analytics_admin.sql

# 3. 验证表创建
\dt analytics_*
\dt admin_*
```

### 9.2 Edge Function 部署

```bash
# 1. 安装 Supabase CLI
npm install -g supabase

# 2. 登录
supabase login

# 3. 部署函数
supabase functions deploy analytics-track

# 4. 测试函数
curl -X POST \
  -H "Authorization: Bearer [anon-key]" \
  -H "Content-Type: application/json" \
  -d '{"events": [{"event_type": "test"}]}' \
  https://[project].supabase.co/functions/v1/analytics-track
```

### 9.3 运营后台部署

```bash
# 1. 构建生产版本
cd dacong-admin
flutter build web --release

# 2. 部署到 Vercel
vercel --prod

# 或部署到 Firebase Hosting
firebase deploy --only hosting
```

---

## 10. 交付物清单

### 10.1 代码交付

- [x] 数据库迁移文件
- [x] 埋点SDK代码
- [ ] Edge Function代码
- [x] 运营后台代码
- [ ] 单元测试
- [ ] 集成测试

### 10.2 文档交付

- [x] 数据分析架构设计
- [x] 运营后台架构设计
- [x] Week 3 实施计划
- [ ] 埋点使用文档
- [ ] 运营后台使用手册
- [ ] 数据看板说明

### 10.3 部署交付

- [ ] 数据库表已创建
- [ ] Edge Function已部署
- [ ] 运营后台已上线
- [ ] 管理员账号已创建
- [ ] 监控告警已配置

---

## 11. 下一步（Week 4）

### 11.1 数据分析优化

- 实现更多维度的分析（用户画像、行为路径）
- 实现A/B测试框架
- 实现漏斗分析
- 实现留存分析

### 11.2 运营后台增强

- 实现评论管理
- 实现举报处理
- 实现系统设置
- 实现操作日志查询

### 11.3 数据可视化

- 部署Metabase
- 创建更多看板
- 实现自定义报表
- 实现数据导出

---

## 12. 参考资料

### 12.1 技术文档

- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Flutter Analytics Best Practices](https://docs.flutter.dev/cookbook/plugins/analytics)
- [PostgreSQL Triggers](https://www.postgresql.org/docs/current/triggers.html)
- [pg_cron Documentation](https://github.com/citusdata/pg_cron)

### 12.2 设计参考

- [Google Analytics Events](https://developers.google.com/analytics/devguides/collection/ga4/events)
- [Mixpanel Event Tracking](https://mixpanel.com/blog/event-tracking-best-practices/)
- [Segment Spec](https://segment.com/docs/connections/spec/)

---

**文档版本历史：**

| 版本 | 日期 | 更新内容 | 作者 |
|------|------|---------|------|
| v1.0 | 2026-04-17 | 初始版本 | Product Team |
