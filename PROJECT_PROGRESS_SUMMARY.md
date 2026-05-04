# DaCong 项目进度汇总

**更新时间**: 2026-05-04
**Git 提交**: `9f6787c` feat(console): add Zustand stores and auth components

---

## 项目结构概览

```
dacong/
├── dacong-console/     # Next.js 主应用（移动端 + Web）
├── dacong-spider/      # Python 爬虫（多来源）
├── dacong-worker/      # Node.js 后台任务（Supabase Edge Functions）
├── dacong-admin/       # Flutter 管理员 App
├── dacong-client/      # Flutter 用户 App
├── dacong-api/         # API 文档
├── dacong-docs/        # 项目文档
├── supabase/           # 数据库 Schema
├── config/             # 配置文件
├── tests/              # 测试脚本
└── scripts/            # 部署脚本
```

---

## 一、dacong-console (Next.js 前端)

### 1.1 技术栈
- **框架**: Next.js 16 (App Router)
- **样式**: Tailwind CSS + 渐变设计
- **状态管理**: Zustand
- **数据库**: Supabase (PostgreSQL + Auth)
- **部署**: Netlify (Vercel 备选)

### 1.2 组件 (11 个)
| 组件 | 功能 | 状态 |
|------|------|------|
| PostCard | 帖子卡片（支持点赞/收藏） | ✅ |
| PostList | 帖子列表 | ✅ |
| TrendingList | 趋势列表 | ✅ |
| SearchBar | 搜索栏 | ✅ |
| TagsFilter | 标签筛选 | ✅ |
| TabBar | 底部导航 | ✅ |
| Profile | 用户资料 | ✅ |
| Messages | 消息列表 | ✅ |
| WebHeader | Web 端头部 | ✅ |
| WebSidebar | Web 端侧边栏 | ✅ |
| RightSidebar | Web 端右侧栏 | ✅ |

### 1.3 状态管理 (Zustand)
| Store | 功能 | 状态 |
|--------|------|------|
| authStore | 认证状态 | ✅ |
| postsStore | 帖子数据缓存 | ✅ |
| favoritesStore | 收藏列表 | ✅ |
| likesStore | 点赞列表 | ✅ |

### 1.4 页面路由
- `/` - 首页（帖子列表）
- `/web` - Web 版首页
- `/web/trending` - 趋势热榜
- `/web/search` - 搜索
- `/web/ranking` - AI 模型排行
- `/web/review` - 评论
- `/web/following` - 关注
- `/web/saved` - 收藏
- `/web/profile` - 个人资料
- `/api/test/route.ts` - API 测试端点

### 1.5 数据库 Schema
```sql
-- posts 表（核心）
posts (id, title, content, url, source, author, tags, status, metadata, created_at, updated_at)

-- AI 模型（参考排行）
models (id, name, provider, benchmark_scores, context_window, pricing, created_at)

-- 用户数据
favorites (id, user_id, post_id, created_at)
likes (id, user_id, post_id, created_at)
reviews (id, user_id, post_id, rating, content, created_at)
user_follows (id, follower_id, following_id, created_at)
```

---

## 二、dacong-spider (Python 爬虫)

### 2.1 爬虫列表
| 爬虫 | 来源 | 状态 |
|------|------|------|
| hackernews_spider | Hacker News | ✅ |
| openrouter_spider | OpenRouter | ✅ |
| reddit_spider | Reddit | ✅ |
| github_trending | GitHub Trending | ✅ |
| huggingface_spider | HuggingFace | ✅ |
| github_spider | GitHub | ✅ |

### 2.2 架构
- **调度器**: SpiderRegistry + Scheduler
- **处理器**: ContentProcessor (去重/分类)
- **存储**: SupabaseStorage
- **日志**: StructuredLogger

### 2.3 近期优化
- 添加 RLS 策略（行级安全）
- 优化去重逻辑
- 改进错误处理

---

## 三、dacong-worker (Node.js 后台)

### 3.1 任务类型
- **爬虫触发**: 定时调用 GitHub Actions
- **数据验证**: 检查 posts 状态
- **服务角色**: 管理操作

### 3.2 脚本
- `fetch-36kr-v2.ts` - 36氪 RSS 抓取
- `test-crawl.ts` - 测试爬虫
- `check-posts.ts` - 检查 posts 状态

---

## 四、数据库状态

### 4.1 Supabase 真实数据
```
posts 表: 40 条记录 (全部 approved)
数据来源: 36kr (今日新闻)
最后更新: 2026-05-04T01:48:44+00:00
```

### 4.2 RLS 策略
- ✅ 帖子查询（已批准）
- ✅ 用户认证
- ⚠️ 需要完善 favorites/likes 写入策略

---

## 五、CI/CD

### 5.1 部署流程
| 平台 | 触发条件 | 状态 |
|------|----------|------|
| Netlify | push to main | ✅ |
| Vercel | - | 备选 |

### 5.2 GitLab CI
- 自动构建镜像
- 安全扫描 (Snyk)
- 部署到服务器

---

## 六、待完成事项

### 高优先级
- [ ] 完善用户认证流程（登录/注册）
- [ ] 收藏/点赞功能与后端同步
- [ ] 帖子详情页 (`/post/[id]`)
- [ ] AI 模型排行展示

### 中优先级
- [ ] 评论系统
- [ ] 关注功能
- [ ] 搜索结果页
- [ ] 通知推送

### 低优先级
- [ ] 深色模式
- [ ] PWA 支持
- [ ] App 端适配
- [ ] 国际化 (i18n)

---

## 七、测试验证

### 7.1 API 测试
```bash
# 数据库连接
✅ Supabase 匿名连接正常

# 数据查询
✅ posts 表查询正常 (40 条)
✅ status = approved 可过滤
```

### 7.2 前端测试
```bash
# React 验证
✅ useEffect 正常执行
✅ 状态更新正常
✅ 事件处理正常

# 浏览器测试
✅ Counter 每秒递增
✅ 页面渲染正常
```

### 7.3 Playwright 配置
⚠️ 测试配置需要调整（Vitest/Playwright 冲突）

---

## 八、文档

| 文档 | 内容 |
|------|------|
| README.md | 项目说明 |
| README_STARTUP.md | 启动指南 |
| ADMIN_SETUP_PROGRESS.md | 管理后台进度 |
| API_ENHANCEMENT_REPORT.md | API 改进报告 |
| CODE_REFACTOR_SUMMARY.md | 代码重构总结 |
| PROJECT_PROGRESS.md | 项目进度 |
| PROJECT_STATUS_UPDATE.md | 状态更新 |
| NIGHT_WORK_SUMMARY.md | 夜间工作总结 |

---

## 九、统计数据

| 指标 | 数值 |
|------|------|
| 总提交数 | 9f6787c |
| 代码变更 (最近 5 commits) | +7647 / -530 行 |
| 组件数 | 11 个 |
| Zustand Store | 4 个 |
| 爬虫数 | 6 个 |
| 数据库表 | 8+ 个 |
| posts 记录 | 40 条 |

---

## 十、下一步计划

1. **完善认证流程** - 登录/注册 UI + Supabase Auth
2. **帖子详情页** - 完整内容展示
3. **用户交互** - 点赞/收藏/评论
4. **AI 模型排行** - 数据展示 + 比较
5. **移动端适配** - 优化手机体验

---

*Report generated: 2026-05-04*
