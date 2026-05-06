# DaCong 待做功能清单

> 生成日期：2026-05-05
> 更新日期：2026-05-05

---

## ✅ 已完成功能

| 功能 | 完成日期 | 说明 |
|------|---------|------|
| 首页新闻列表 | 2026-05-05 | postsStore + web/page.tsx |
| 个人资料页面 | 2026-05-05 | web/profile/page.tsx，含帮助与反馈 |
| 反馈建议功能 | 2026-05-05 | FeedbackModal + /api/feedback |
| 第三方登录 | 2026-05-05 | Google/Facebook OAuth |
| 收藏功能 | 2026-05-05 | favoritesStore + web/saved |
| 登录/注册页面 | 2026-05-05 | OAuth 按钮已集成 |
| **主题切换** | 2026-05-06 | themeStore + ThemeSwitcher |
| **空状态设计** | 2026-05-06 | EmptyState 组件 |
| **统一错误处理** | 2026-05-06 | ErrorBoundary + Toast |
| **操作日志** | 2026-05-06 | auditLogStore + 审计页面 |
| **通知功能** | 2026-05-06 | notificationStore + NotificationBell |
| **CI/CD 完善** | 2026-05-06 | E2E + Code Quality workflows |
| **图片优化** | 2026-05-06 | next/image + WebP/AVIF 配置 |
| **无障碍支持** | 2026-05-06 | WCAG 2.1 AA 完整实现 |
| **Service Worker** | 2026-05-06 | 离线缓存 + PWA 支持 |

---

## 📋 待做功能

### P1 - 重要功能

| 优先级 | 功能 | 预计工时 | 状态 |
|--------|------|---------|------|
| ✅ | 主题切换 | 16h | 已完成 |
| ✅ | 空状态设计 | 8h | 已完成 |
| ✅ | 统一错误处理 | 12h | 已完成 |
| ✅ | 操作日志 | 12h | 已完成 |
| ✅ | 通知功能 | 20h | 已完成 |
| ✅ | CI/CD 完善 | 16h | 已完成 |
| ✅ | 图片优化 | 8h | 已完成 |
| ✅ | 无障碍支持 | 20h | 已完成 |
| ✅ | Service Worker | 12h | 已完成 |

### P2 - 优化功能

| 优先级 | 功能 | 预计工时 | 状态 |
|--------|------|---------|------|
| ✅ | 图片优化 | 8h | 已完成 |
| ✅ | Service Worker | 12h | 已完成 |
| 🟡 中 | 虚拟滚动 | 8h | 待完成 |
| 🟢 低 | 评论回复 | 16h | 待完成 |
| 🟢 低 | 评论排序 | 6h | 待完成 |

### P0 - 基础设施（参考 docs/TODO.md）

| 优先级 | 功能 | 预计工时 |
|--------|------|---------|
| 🔴 最高 | 部署文档 | 16h |
| 🔴 最高 | 错误监控集成 | 16h |
| 🔴 最高 | CSRF 防护 | 12h |
| 🔴 最高 | 输入验证完善 | 20h |
| 🔴 最高 | 测试覆盖率提升 | 40h |
| 🔴 最高 | 日志聚合 | 20h |
| 🔴 最高 | 性能监控 | 24h |

---

## 🎯 推荐执行顺序

### 第二阶段（基础设施）- ✅ 已完成
4. 📝 操作日志（12h）- ✅ 已完成
5. 🔔 通知功能（20h）- ✅ 已完成
6. 🔧 CI/CD 完善（16h）- ✅ 已完成

### 第三阶段（优化与扩展）- ✅ 已完成
7. 🐳 Docker 配置（12h）- ✅ 已完成
8. ♿ 无障碍支持（20h）- ✅ 已完成
9. 🖼️ 图片优化（8h）- ✅ 已完成
10. 🔄 Service Worker（12h）- ✅ 已完成

### 第四阶段（社交功能）
11. 💬 评论回复（16h）
12. 📊 评论排序（6h）
13. 📜 虚拟滚动（8h）

---

## 📊 工时统计

| 类别 | 数量 | 总工时 |
|------|------|--------|
| P1 重要功能 | 8 | ~136h |
| P2 优化功能 | 5 | ~50h |
| P0 基础设施 | 7 | ~160h |
| **合计** | **20** | **~346h** |

---

## 📝 更新日志

```
2026-05-05:
  - 创建待做功能清单
  - 标记已完成功能
  - 整理 P1/P2/P0 优先级

2026-05-06:
  - 第二阶段功能全部完成
  - 操作日志：auditLogStore + /web/admin/audit-logs 页面
  - 通知功能：notificationStore + NotificationBell 组件
  - CI/CD 完善：E2E tests workflow + Code Quality workflow
  - Docker 配置：Console Dockerfile + docker-compose 更新

2026-05-06 (第三阶段):
  - 图片优化：next/image + WebP/AVIF 配置
  - 无障碍支持：WCAG 2.1 AA 完整实现
    * SkipLink, LiveRegion, FocusTrap 组件
    * NotificationBell, WebHeader, PostCard, ThemeSwitcher ARIA 更新
    * 减弱动效支持
    * 焦点可见样式
  - Service Worker：离线缓存 + PWA 支持
    * sw.js 缓存策略
    * manifest.json Web App 配置
```