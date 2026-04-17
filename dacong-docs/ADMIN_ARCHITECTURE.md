# 运营后台架构设计

> 版本：v1.0  
> 更新日期：2026-04-17  
> 负责人：Product Team

---

## 1. 问题陈述

### 1.1 核心问题

**运营团队需要什么能力？**
- 审核AI生成的内容（质量把关）
- 管理已发布的内容（编辑、下架、置顶）
- 处理用户反馈（评论审核、举报处理）
- 查看数据看板（实时监控、趋势分析）
- 管理用户（查看、封禁、权限）
- 配置系统参数（推荐策略、敏感词）

**不解决的代价：**
- 内容质量无法保证，用户体验差
- 违规内容无法及时处理，法律风险
- 运营效率低，人工成本高
- 无法快速响应用户反馈

### 1.2 用户画像

**主要用户：内容运营（2-3人）**
- 每天审核50-100条AI生成内容
- 每天处理10-20条用户反馈
- 每周查看数据报表，调整推荐策略
- 需要快捷操作，提升效率

**次要用户：管理员（1人）**
- 管理运营人员权限
- 查看系统日志
- 配置系统参数

---

## 2. 目标与成功指标

| 目标 | 指标 | 当前基线 | 目标值 | 度量窗口 |
|------|------|---------|--------|---------|
| 提升审核效率 | 人均审核量 | 0 | 50条/天 | Week 3 完成 |
| 降低审核时间 | 单条审核时间 | N/A | <30s | Week 3 完成 |
| 提升内容质量 | 内容有用率 | 70% | 80% | Week 4 |
| 快速响应反馈 | 反馈处理时长 | N/A | <24h | Week 4 |

---

## 3. 功能模块

### 3.1 内容管理

**核心功能：**

| 功能 | 描述 | 优先级 | 工作量 |
|------|------|--------|--------|
| 内容审核 | 审核AI生成的内容，通过/拒绝/修改 | P0 | 2天 |
| 内容编辑 | 修改已发布内容的标题、正文、标签 | P0 | 1天 |
| 内容下架 | 下架违规或低质量内容 | P0 | 0.5天 |
| 内容置顶 | 置顶优质内容到首页 | P1 | 0.5天 |
| 批量操作 | 批量审核、批量下架 | P1 | 1天 |

**审核工作流：**
```
AI生成内容
  ↓
进入审核队列（按优先级排序）
  ↓
运营人员审核
  ├─ 通过 → 发布到客户端
  ├─ 拒绝 → 标记原因，反馈给AI
  └─ 修改 → 人工编辑后发布
```

**审核界面设计：**
```
┌─────────────────────────────────────────────────────────┐
│ 待审核队列 (50)                          [批量通过] [批量拒绝] │
├─────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 🔴 高优先级 | AI置信度: 0.75 | 场景: 写代码           │ │
│ │ 标题: Cursor + DeepSeek：最佳AI编程组合              │ │
│ │ 预览: Cursor是一款基于VSCode的AI编程工具...          │ │
│ │ [查看详情] [通过] [拒绝] [修改]                       │ │
│ └─────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 🟡 中优先级 | AI置信度: 0.88 | 场景: 做视频           │ │
│ │ 标题: Runway Gen-3：视频生成新标杆                   │ │
│ │ 预览: Runway Gen-3是最新的视频生成模型...            │ │
│ │ [查看详情] [通过] [拒绝] [修改]                       │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**快捷键：**
- `A` - 通过
- `R` - 拒绝
- `E` - 编辑
- `N` - 下一条

---

### 3.2 用户管理

**核心功能：**

| 功能 | 描述 | 优先级 | 工作量 |
|------|------|--------|--------|
| 用户列表 | 查看所有用户，支持搜索、筛选 | P0 | 1天 |
| 用户详情 | 查看用户资料、行为记录 | P0 | 1天 |
| 用户封禁 | 封禁违规用户 | P0 | 0.5天 |
| 权限管理 | 设置用户角色和权限 | P1 | 1天 |

**用户列表：**
```
┌─────────────────────────────────────────────────────────┐
│ 用户管理                    [搜索] [筛选: 全部▼]          │
├─────────────────────────────────────────────────────────┤
│ ID | 邮箱 | 注册时间 | 最后活跃 | 状态 | 操作           │
├─────────────────────────────────────────────────────────┤
│ 001 | user@example.com | 2026-04-10 | 2小时前 | 正常 | [详情] [封禁] │
│ 002 | test@example.com | 2026-04-12 | 1天前 | 正常 | [详情] [封禁] │
│ 003 | spam@example.com | 2026-04-15 | 3天前 | 已封禁 | [详情] [解封] │
└─────────────────────────────────────────────────────────┘
```

---

### 3.3 评论管理

**核心功能：**

| 功能 | 描述 | 优先级 | 工作量 |
|------|------|--------|--------|
| 评论审核 | 审核用户评论，通过/拒绝 | P1 | 1天 |
| 评论删除 | 删除违规评论 | P1 | 0.5天 |
| 举报处理 | 处理用户举报 | P1 | 1天 |

**注：评论功能在P2阶段，Week 3暂不实现**

---

### 3.4 数据看板

**核心功能：**

| 功能 | 描述 | 优先级 | 工作量 |
|------|------|--------|--------|
| 实时概览 | 今日DAU、PV、内容发布量 | P0 | 1天 |
| 内容统计 | 内容热度排行、有用率分布 | P0 | 1天 |
| 用户统计 | 用户增长、留存、活跃度 | P0 | 1天 |
| 趋势图表 | 7日/30日趋势图 | P1 | 1天 |

**实时概览：**
```
┌─────────────────────────────────────────────────────────┐
│ 数据看板 - 实时概览                    更新时间: 14:30   │
├─────────────────────────────────────────────────────────┤
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│ │ 今日DAU  │ │ 今日PV   │ │ 新增用户 │ │ 内容发布 │   │
│ │   156    │ │   892    │ │    23    │ │    12    │   │
│ │  ↑ 12%   │ │  ↑ 8%    │ │  ↓ 5%    │ │  ↑ 20%   │   │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘   │
├─────────────────────────────────────────────────────────┤
│ 热门内容 Top 5                                          │
│ 1. Cursor + DeepSeek组合 (234 views, 89% helpful)      │
│ 2. Claude Code使用教程 (189 views, 92% helpful)        │
│ 3. Runway Gen-3评测 (156 views, 85% helpful)           │
│ 4. 本周AI工具精选 (134 views, 88% helpful)             │
│ 5. GitHub Copilot对比 (112 views, 81% helpful)         │
└─────────────────────────────────────────────────────────┘
```

---

### 3.5 系统设置

**核心功能：**

| 功能 | 描述 | 优先级 | 工作量 |
|------|------|--------|--------|
| 推荐策略 | 配置场景推荐规则 | P1 | 1天 |
| 敏感词管理 | 添加/删除敏感词 | P1 | 0.5天 |
| 通知配置 | 配置邮件/Webhook通知 | P2 | 1天 |
| 系统日志 | 查看操作日志 | P2 | 1天 |

---

## 4. 技术方案

### 4.1 技术选型

**方案对比：**

| 方案 | 优势 | 劣势 | 推荐度 |
|------|------|------|--------|
| Flutter Web | 复用客户端代码，统一技术栈 | Web性能一般 | ⭐⭐⭐⭐ |
| React Admin | 生态成熟，组件丰富 | 新增技术栈 | ⭐⭐⭐⭐⭐ |
| Next.js + shadcn/ui | 现代化，开发体验好 | 需要学习 | ⭐⭐⭐⭐⭐ |
| Vue Admin | 国内流行，中文文档好 | 生态不如React | ⭐⭐⭐ |

**推荐方案：Flutter Web**

**理由：**
- 复用客户端代码（models, repositories, services）
- 团队已熟悉Flutter，无学习成本
- 统一技术栈，降低维护成本
- 性能足够（后台不需要极致性能）

**备选方案：Next.js + shadcn/ui**
- 如果团队有React经验，可选此方案
- 更好的Web体验
- 更丰富的组件库

---

### 4.2 架构设计

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter Web (后台)                     │
│         内容管理 + 用户管理 + 数据看板 + 系统设置         │
└─────────────────────────────────────────────────────────┘
                         ↓ HTTPS
┌─────────────────────────────────────────────────────────┐
│                 Supabase (后端)                          │
│         PostgreSQL + PostgREST + Auth + RLS             │
└─────────────────────────────────────────────────────────┘
```

**权限控制：**
```sql
-- 管理员表
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  email VARCHAR(255) UNIQUE NOT NULL,
  role VARCHAR(50) NOT NULL,  -- 'super_admin', 'content_admin', 'user_admin'
  permissions JSONB,  -- 细粒度权限
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS策略：只有管理员可以访问后台数据
CREATE POLICY "Only admins can access"
ON generated_content FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid()
  )
);
```

---

### 4.3 项目结构

```
dacong-admin/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   └── utils/
│   ├── data/
│   │   ├── models/
│   │   │   ├── admin_user.dart
│   │   │   ├── review_item.dart
│   │   │   └── stats.dart
│   │   ├── repositories/
│   │   │   ├── content_repository.dart
│   │   │   ├── user_repository.dart
│   │   │   └── analytics_repository.dart
│   │   └── providers/
│   ├── presentation/
│   │   ├── pages/
│   │   │   ├── login_page.dart
│   │   │   ├── dashboard_page.dart
│   │   │   ├── content_management_page.dart
│   │   │   ├── user_management_page.dart
│   │   │   └── analytics_page.dart
│   │   ├── widgets/
│   │   │   ├── stat_card.dart
│   │   │   ├── review_card.dart
│   │   │   ├── data_table.dart
│   │   │   └── chart_widget.dart
│   │   └── providers/
│   └── main.dart
├── web/
│   ├── index.html
│   └── favicon.png
├── pubspec.yaml
└── README.md
```

---

### 4.4 核心代码

**ContentManagementPage（内容审核）：**
```dart
class ContentManagementPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewQueue = ref.watch(reviewQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('内容审核'),
        actions: [
          TextButton(
            onPressed: () => _batchApprove(ref),
            child: Text('批量通过'),
          ),
        ],
      ),
      body: reviewQueue.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ReviewCard(
              item: item,
              onApprove: () => _approve(ref, item.id),
              onReject: () => _reject(ref, item.id),
              onEdit: () => _edit(context, item),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }

  Future<void> _approve(WidgetRef ref, String id) async {
    final repo = ref.read(contentRepositoryProvider);
    await repo.approveContent(id);
    ref.invalidate(reviewQueueProvider);
  }

  Future<void> _reject(WidgetRef ref, String id) async {
    final reason = await _showRejectDialog();
    if (reason != null) {
      final repo = ref.read(contentRepositoryProvider);
      await repo.rejectContent(id, reason);
      ref.invalidate(reviewQueueProvider);
    }
  }
}
```

**DashboardPage（数据看板）：**
```dart
class DashboardPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('数据看板')),
      body: stats.when(
        data: (data) => SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // 实时概览
              Row(
                children: [
                  Expanded(child: StatCard(
                    title: '今日DAU',
                    value: data.dau.toString(),
                    change: data.dauChange,
                  )),
                  SizedBox(width: 16),
                  Expanded(child: StatCard(
                    title: '今日PV',
                    value: data.pv.toString(),
                    change: data.pvChange,
                  )),
                  SizedBox(width: 16),
                  Expanded(child: StatCard(
                    title: '新增用户',
                    value: data.newUsers.toString(),
                    change: data.newUsersChange,
                  )),
                  SizedBox(width: 16),
                  Expanded(child: StatCard(
                    title: '内容发布',
                    value: data.publishedContent.toString(),
                    change: data.publishedContentChange,
                  )),
                ],
              ),
              SizedBox(height: 24),
              
              // 热门内容
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('热门内容 Top 5', style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 16),
                      ...data.topContent.map((item) => ListTile(
                        title: Text(item.title),
                        subtitle: Text('${item.viewCount} views, ${item.helpfulRate}% helpful'),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }
}
```

**StatCard（统计卡片）：**
```dart
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final double change;  // 变化百分比

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 4),
                Text(
                  '${change.abs().toStringAsFixed(1)}%',
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. 数据库设计

### 5.1 管理员表

```sql
-- 管理员用户表
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) UNIQUE,
  email VARCHAR(255) UNIQUE NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'content_admin',
  permissions JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 角色定义
-- super_admin: 超级管理员，所有权限
-- content_admin: 内容管理员，审核、编辑、发布内容
-- user_admin: 用户管理员，管理用户、处理举报

-- 权限示例
-- {
--   "content": ["review", "edit", "publish", "delete"],
--   "user": ["view", "ban"],
--   "analytics": ["view"],
--   "settings": ["view", "edit"]
-- }

CREATE INDEX idx_admin_users_user_id ON admin_users(user_id);
CREATE INDEX idx_admin_users_role ON admin_users(role);
```

### 5.2 审核记录表

```sql
-- 审核记录表
CREATE TABLE review_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content_id UUID REFERENCES generated_content(id),
  admin_id UUID REFERENCES admin_users(id),
  action VARCHAR(50) NOT NULL,  -- 'approve', 'reject', 'edit'
  reason TEXT,  -- 拒绝原因或修改说明
  before_data JSONB,  -- 修改前数据
  after_data JSONB,  -- 修改后数据
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_review_logs_content ON review_logs(content_id);
CREATE INDEX idx_review_logs_admin ON review_logs(admin_id);
CREATE INDEX idx_review_logs_created_at ON review_logs(created_at DESC);
```

### 5.3 操作日志表

```sql
-- 操作日志表
CREATE TABLE admin_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID REFERENCES admin_users(id),
  action VARCHAR(100) NOT NULL,  -- 'login', 'ban_user', 'edit_content'等
  resource_type VARCHAR(50),  -- 'user', 'content', 'settings'
  resource_id UUID,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_admin_logs_admin ON admin_logs(admin_id);
CREATE INDEX idx_admin_logs_action ON admin_logs(action);
CREATE INDEX idx_admin_logs_created_at ON admin_logs(created_at DESC);
```

---

## 6. 权限设计

### 6.1 角色权限矩阵

| 功能 | super_admin | content_admin | user_admin |
|------|-------------|---------------|------------|
| 内容审核 | ✅ | ✅ | ❌ |
| 内容编辑 | ✅ | ✅ | ❌ |
| 内容删除 | ✅ | ✅ | ❌ |
| 用户查看 | ✅ | ✅ | ✅ |
| 用户封禁 | ✅ | ❌ | ✅ |
| 数据看板 | ✅ | ✅ | ✅ |
| 系统设置 | ✅ | ❌ | ❌ |
| 管理员管理 | ✅ | ❌ | ❌ |

### 6.2 RLS策略

```sql
-- 只有管理员可以访问待审核内容
CREATE POLICY "Admins can access review queue"
ON generated_content FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid()
  )
);

-- 只有内容管理员可以审核内容
CREATE POLICY "Content admins can review"
ON generated_content FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid()
      AND (role = 'super_admin' OR role = 'content_admin')
  )
);

-- 只有用户管理员可以封禁用户
CREATE POLICY "User admins can ban users"
ON auth.users FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM admin_users
    WHERE user_id = auth.uid()
      AND (role = 'super_admin' OR role = 'user_admin')
  )
);
```

---

## 7. 实施计划

### 7.1 Day 1-2：基础框架

**任务：**
- [ ] 创建dacong-admin项目
- [ ] 配置Flutter Web
- [ ] 实现登录页（Supabase Auth）
- [ ] 实现侧边栏导航
- [ ] 创建管理员表和权限系统

**验收标准：**
- 管理员可以登录
- 侧边栏导航正常
- 权限验证生效

### 7.2 Day 3-4：内容管理

**任务：**
- [ ] 实现内容审核页面
- [ ] 实现审核操作（通过/拒绝/修改）
- [ ] 实现批量操作
- [ ] 实现快捷键
- [ ] 创建审核记录表

**验收标准：**
- 可以查看待审核队列
- 可以审核内容
- 审核记录正确保存
- 快捷键正常工作

### 7.3 Day 5：用户管理

**任务：**
- [ ] 实现用户列表页面
- [ ] 实现用户详情页面
- [ ] 实现用户封禁功能
- [ ] 实现搜索和筛选

**验收标准：**
- 可以查看用户列表
- 可以查看用户详情
- 可以封禁/解封用户

### 7.4 Day 6-7：数据看板

**任务：**
- [ ] 实现实时概览
- [ ] 实现热门内容排行
- [ ] 实现统计图表
- [ ] 集成Metabase（iframe嵌入）

**验收标准：**
- 数据准确显示
- 图表正常渲染
- 刷新及时

---

## 8. 风险与应对

### 8.1 安全风险

**风险：管理员账号泄露**
- 应对：强制2FA、IP白名单、操作日志

**风险：权限绕过**
- 应对：RLS策略、前后端双重验证

### 8.2 性能风险

**风险：审核队列加载慢**
- 应对：分页加载、索引优化

**风险：数据看板查询慢**
- 应对：使用汇总表、缓存

### 8.3 可用性风险

**风险：运营人员不会用**
- 应对：提供培训文档、快捷键提示

---

## 9. 成功标准

**Week 3 结束时：**
- [ ] 管理员可以登录后台
- [ ] 可以审核AI生成的内容
- [ ] 可以查看用户列表
- [ ] 可以查看数据看板
- [ ] 人均审核效率达到50条/天

**Week 4 开始时：**
- [ ] 运营团队开始使用后台
- [ ] 内容有用率提升到80%
- [ ] 审核队列无堆积（<20条）

---

## 10. 附录

### 10.1 快捷键列表

| 快捷键 | 功能 |
|--------|------|
| A | 通过当前内容 |
| R | 拒绝当前内容 |
| E | 编辑当前内容 |
| N | 下一条 |
| P | 上一条 |
| Ctrl+S | 保存修改 |
| Ctrl+/ | 显示快捷键帮助 |

### 10.2 审核标准

**通过标准：**
- 内容准确无误
- 格式规范
- 无敏感词
- AI置信度 > 0.8

**拒绝原因：**
- 信息错误
- 格式混乱
- 包含敏感词
- 重复内容
- 质量过低

### 10.3 参考资料

- [React Admin](https://marmelab.com/react-admin/)
- [Flutter Web Best Practices](https://docs.flutter.dev/platform-integration/web)
- [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
