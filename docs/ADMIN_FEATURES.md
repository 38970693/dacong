# 大聪管理后台功能文档

## 概述

大聪管理后台（dacong-admin）是基于 Flutter 开发的跨平台管理系统，提供内容审核、用户管理、数据统计等核心功能。

## 核心功能

### 1. 数据看板（Dashboard）

#### 实时概览
- **今日 DAU**：日活跃用户数，显示较昨日变化百分比
- **今日 PV**：页面浏览量，显示较昨日变化百分比
- **今日 UV**：独立访客数，显示较昨日变化百分比
- **新增用户**：今日新注册用户数，显示较昨日变化百分比

#### 趋势分析
- 支持查看 7 天和 30 天的趋势数据
- 折线图展示 DAU、PV、UV 的变化趋势
- 自动刷新，缓存时间 1 分钟

#### 待处理事项
- **待审核内容**：显示待审核的内容数量，点击跳转到内容管理页面
- **待审核评论**：显示待审核的评论数量，点击跳转到评论审核页面
- **待处理举报**：显示待处理的举报数量，点击跳转到举报处理页面
- **待处理申诉**：显示待处理的申诉数量，点击跳转到申诉处理页面

#### 内容统计
- 饼图展示内容分布（总内容、已发布、待审核）
- 柱状图展示用户概览（总用户、今日活跃、新增用户）

#### 热门内容 Top 10
- 按浏览量排序的热门内容列表
- 显示标题、浏览量、有用率
- 点击可查看内容详情

#### 搜索热词 Top 10
- 最近 7 天的搜索关键词统计
- 按搜索次数降序排列

---

### 2. 内容管理（Content Management）

#### 批量操作
- **批量选择**：通过 Checkbox 选择多条内容
- **批量通过**：一键通过选中的所有内容
- **批量拒绝**：一键拒绝选中的所有内容
- **批量删除**：删除选中的内容（需二次确认）
- **批量导出**：将选中的内容导出为 CSV 文件

#### 搜索和筛选
- **搜索框**：支持按标题和内容搜索
- **状态筛选**：全部、待审核、已通过、已拒绝
- **高级筛选**：
  - 排序字段：创建时间、更新时间、浏览量、点赞数
  - 排序方式：升序、降序

#### 快捷键操作
- **1**：通过当前内容
- **2**：拒绝当前内容
- **E**：编辑当前内容
- **N**：跳转到下一条内容

#### 单条操作
- **查看详情**：查看内容完整信息
- **通过**：审核通过
- **拒绝**：审核拒绝
- **编辑**：修改标题和内容

#### 分页
- 每页显示 20 条记录
- 支持上一页、下一页导航

---

### 3. 用户管理（User Management）

#### 搜索和筛选
- **搜索框**：按用户名搜索
- **状态筛选**：全部、正常、已封禁

#### 用户列表
- 表格展示用户信息：
  - 用户名（带头像）
  - 用户 ID（前 8 位）
  - 注册时间
  - 状态（正常/已封禁）

#### 用户操作
- **查看详情**：
  - 基本信息：用户名、ID、注册时间、状态、封禁原因
  - 统计信息：发帖数、评论数、粉丝数、关注数
  - 最近活动：最近发帖、最近评论
- **封禁/解封**：
  - 封禁时需填写封禁原因
  - 解封无需原因
- **删除用户**：
  - 需二次确认
  - 不可恢复

#### 分页
- 每页显示 20 条记录
- 支持上一页、下一页导航

---

### 4. 评论审核（Comment Moderation）

#### 功能特性
- 查看待审核评论列表
- 支持按状态筛选（待审核、已通过、已拒绝）
- 支持仅显示被举报的评论
- 批量审核（通过/拒绝）
- 审核时可选择是否封禁用户

---

### 5. 数据导出（Export）

#### 支持的导出格式
- **CSV**：通用格式，可被 Excel 打开
- **Excel**：实际为 CSV 格式，兼容 Excel

#### 导出功能
- **通用导出方法**：
  - `exportToCsv(data, filename)`：导出为 CSV
  - `exportToExcel(data, filename)`：导出为 Excel 兼容格式
- **预定义导出**：
  - `exportUsersToCsv()`：导出用户数据
  - `exportContentToCsv()`：导出内容数据
  - `exportCommentsToCsv()`：导出评论数据
  - `exportAnalyticsReport(startDate, endDate)`：导出分析报告

#### 导出字段
- **用户导出**：ID、用户名、邮箱、注册时间、最后登录、状态
- **内容导出**：ID、标题、作者 ID、状态、浏览量、点赞数、创建时间、发布时间
- **评论导出**：ID、内容 ID、用户 ID、评论内容、状态、创建时间
- **分析报告**：日期、DAU、PV、UV、新增用户

---

### 6. 操作日志（Admin Logs）

#### 日志记录
所有管理操作都会自动记录到 `admin_logs` 表，包括：
- 管理员 ID
- 操作类型（action）
- 目标类型（target_type）
- 目标 ID 列表（target_ids）
- 操作详情（details）
- 操作时间（created_at）

#### 记录的操作类型
- `moderate_content`：内容审核
- `edit_content`：编辑内容
- `delete_content`：删除内容
- `ban_user`：封禁用户
- `unban_user`：解封用户
- `delete_user`：删除用户
- `moderate_comment`：评论审核

#### 日志查询
- 支持按管理员 ID 筛选
- 支持按操作类型筛选
- 支持按时间范围筛选
- 支持分页查询

---

## 技术架构

### 前端技术栈
- **Flutter**：跨平台 UI 框架
- **Riverpod**：状态管理
- **fl_chart**：图表库
- **csv**：CSV 导出

### 后端集成
- **Supabase**：后端服务
  - 数据库：PostgreSQL
  - 认证：Supabase Auth
  - Edge Functions：业务逻辑

### 核心服务
- **AdminApiService**：管理 API 调用
- **DashboardService**：数据看板服务
- **ExportService**：数据导出服务

---

## 数据库表结构

### admin_logs（操作日志表）
```sql
CREATE TABLE admin_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES auth.users(id),
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_ids TEXT[] NOT NULL,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### reports（举报表）
```sql
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES auth.users(id),
  target_type TEXT NOT NULL,
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### user_appeals（用户申诉表）
```sql
CREATE TABLE user_appeals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 性能优化

### 缓存策略
- 数据看板实时统计缓存 1 分钟
- 避免频繁请求后端

### 分页加载
- 所有列表页面支持分页
- 默认每页 20 条记录
- 减少单次数据传输量

### 并行查询
- 待处理事项统计使用 `Future.wait` 并行查询
- 提升数据加载速度

---

## 安全机制

### 权限验证
- 所有 API 请求需要管理员 Token
- 后端验证管理员权限

### 操作确认
- 删除操作需要二次确认
- 封禁用户需要填写原因

### 日志审计
- 所有管理操作记录日志
- 可追溯操作历史

---

## 使用指南

### 登录
1. 使用管理员账号登录
2. 系统验证权限后进入管理后台

### 内容审核
1. 进入"内容管理"页面
2. 筛选"待审核"状态
3. 使用快捷键或按钮进行审核
4. 批量操作可提高效率

### 用户管理
1. 进入"用户管理"页面
2. 搜索或筛选目标用户
3. 查看用户详情
4. 根据需要封禁或删除用户

### 数据导出
1. 在内容管理页面选择要导出的内容
2. 点击"批量导出"按钮
3. 系统生成 CSV 文件并保存到本地

### 查看统计
1. 进入"数据看板"页面
2. 查看实时概览和趋势分析
3. 点击待处理事项快速跳转

---

## 常见问题

### Q: 如何批量审核内容？
A: 在内容管理页面，勾选多条内容，然后点击顶部的"批量通过"或"批量拒绝"按钮。

### Q: 导出的文件保存在哪里？
A: 
- **移动端**：保存在应用文档目录
- **桌面端**：保存在应用文档目录
- **Web 端**：浏览器下载目录

### Q: 如何查看操作日志？
A: 调用 `AdminApiService.getAdminLogs()` 方法，支持按管理员、操作类型、时间范围筛选。

### Q: 封禁用户后如何解封？
A: 在用户管理页面找到被封禁的用户，点击"解封"按钮即可。

---

## 更新日志

### v1.0.0 (2024-04-17)
- ✅ 批量操作功能（选择、审核、删除、导出）
- ✅ 数据导出功能（CSV、Excel）
- ✅ 操作日志记录
- ✅ 待处理事项统计
- ✅ 高级搜索和筛选
- ✅ 快捷键操作

---

## 联系方式

如有问题或建议，请联系开发团队。
