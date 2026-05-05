# DaCong 大聪明 - 项目进度

## 当前状态: 🔄 排行榜功能开发中

**访问地址**: https://dacong.netlify.app/

## 已完成

- [x] Next.js 16 静态导出配置
- [x] Supabase 直连认证 (匿名登录)
- [x] GitHub Actions 自动化部署流程
- [x] Netlify CDN 托管
- [x] 排行榜数据抓取 (LMArena 19,925 条)

## 排行榜数据 (2026-05-04)

| 数据源 | 数量 | 状态 |
|--------|------|------|
| LMArena | 19,925 | ✅ |
| Artificial Analysis | 348 | ⚠️ 部分 |

## 下一步优化

- [ ] 排行榜前端页面
- [ ] 修复 Artificial Analysis 抓取
- [ ] 自定义域名绑定
- [ ] 用户收藏功能

## 关键文件

- 爬虫入口: `dacong-spider/run_rankings.py`
- 排行榜页: `dacong-console/src/app/web/ranking/`
- 数据存储: Supabase `raw_data` 表

---
更新于: 2026-05-04