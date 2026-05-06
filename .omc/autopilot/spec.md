# DaCong 全量功能规范

> 基于 `docs/TODO_FEATURES.md` 的综合实施规范
> 生成日期：2026-05-05

---

## 📋 项目概述

DaCong 是一个现代化的新闻/内容平台，已完成基础功能包括：
- 首页新闻列表、收藏功能、个人资料页面
- 第三方登录 (Google/Facebook OAuth)
- 反馈建议功能

---

## 🎯 第一阶段功能（用户体验优先）

### P1-1: 主题切换 (16h)

**实现要点**：
- 创建 `stores/themeStore.ts` 管理主题状态
- 三种模式：light / dark / system
- CSS 变量支持主题切换
- localStorage 持久化
- @media (prefers-color-scheme) 跟随系统

**影响文件**：
- `dacong-console/src/stores/themeStore.ts` (新建)
- `dacong-console/src/app/web/layout.tsx` (更新)
- `dacong-console/src/components/theme/ThemeSwitcher.tsx` (新建)

### P1-2: 空状态设计 (8h)

**实现要点**：
- `EmptyState` 组件，支持场景：无新闻、无收藏、无通知、无搜索结果、无评论
- 引导操作按钮
- 友好文案

**影响文件**：
- `dacong-console/src/components/ui/EmptyState.tsx` (新建)
- `dacong-console/src/app/web/saved/page.tsx` (更新)
- `dacong-console/src/app/web/search/page.tsx` (更新)

### P1-3: 统一错误处理 (12h)

**实现要点**：
- `ErrorBoundary` 组件
- `ErrorToast` 全局提示
- API 拦截器统一错误处理
- 离线状态检测
- 指数退避重试机制

**影响文件**：
- `dacong-console/src/components/ui/ErrorBoundary.tsx` (新建)
- `dacong-console/src/components/ui/ErrorToast.tsx` (新建)
- `dacong-console/src/lib/api/client.ts` (更新)

---

## 🔄 实施策略

**并行任务分配**：
1. Agent A: 主题切换 (P1-1) - 16h
2. Agent B: 空状态设计 (P1-2) - 8h  
3. Agent C: 统一错误处理 (P1-3) - 12h

**后续阶段**：
- 第二阶段: 操作日志、通知功能、CI/CD完善
- 第三阶段: Docker配置、无障碍支持、图片优化、ServiceWorker、虚拟滚动
- 第四阶段: 评论回复、评论排序
- 第五阶段: 部署文档、错误监控、CSRF、测试覆盖率、日志聚合、性能监控

---

## ✅ 验收标准

- [ ] 主题切换三种模式正常工作
- [ ] 空状态组件覆盖所有列表页
- [ ] 错误边界正确捕获异常
- [ ] CI/CD 流水线正常运行
- [ ] 测试覆盖率达到 80%+
