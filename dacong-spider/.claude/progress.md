# AI 排行榜爬虫项目进展

**更新时间**: 2026-05-04

## 已完成

### 数据源爬虫
| 数据源 | 状态 | 记录数 | 文件位置 |
|--------|------|--------|----------|
| LMArena (HuggingFace) | ✅ 完成 | 20,029 条 | `data/lmarena_rankings.json` |
| Artificial Analysis | ✅ 完成 | 857 个模型 | `data/artificial_analysis_rankings.json` |
| AI Ping | ❌ 移除 (用户弃用) | - | - |

### 核心功能
- [x] Supabase 数据库连接
- [x] 数据表 migration
- [x] 聚合运行脚本 `run_all_rankings.py`
- [x] 移除 AI Ping 相关代码

## 现有问题

1. **数据存储未集成** - 爬取的数据只保存到 JSON 文件，未写入 Supabase
2. **增量更新** - 每次运行都重新抓取全量数据，无增量逻辑
3. **定时任务** - 未配置自动调度

## 下一步计划

### 优先级 1: 数据写入 Supabase
```
1. 复用现有 Storage 类 (core/storage.py)
2. 在 run_all_rankings.py 中添加写入逻辑
3. 去重检查 (基于 content_hash)
4. 测试批量写入
```

### 优先级 2: 增量更新机制
```
1. 记录上次抓取时间
2. 对比 content_hash 判断更新
3. 只写入有变化的数据
```

### 优先级 3: 定时调度
```
1. 添加 --cron 选项支持定时运行
2. 或使用 Windows Task Scheduler
3. 配置日志轮转
```

## 目录结构
```
dacong-spider/
├── spiders/
│   ├── huggingface_leaderboard.py  # LMArena
│   └── artificial_analysis_spider.py  # AA
├── core/
│   └── storage.py  # Supabase 存储
├── data/
│   ├── lmarena_rankings.json
│   ├── artificial_analysis_rankings.json
│   └── fetch_summary.json
└── run_all_rankings.py  # 主入口
```