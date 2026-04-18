# DaCong 项目文档

## 文档结构

```
docs/
├── README.md                    # 本文件 - 文档导航
├── features/                    # 功能实现文档
│   ├── recommendation/          # 推荐功能
│   ├── search/                  # 搜索功能
│   ├── user/                    # 用户功能
│   └── ...
├── infrastructure/              # 基础设施文档
│   ├── docker/                  # Docker 相关
│   ├── logging/                 # 日志系统
│   ├── monitoring/              # 监控系统
│   ├── cache/                   # 缓存系统
│   └── security/                # 安全相关
├── deployment/                  # 部署文档
│   ├── gitlab-ci/               # GitLab CI/CD
│   ├── github-actions/          # GitHub Actions
│   └── ...
├── quickstart/                  # 快速开始指南
│   ├── auth/                    # 认证快速开始
│   ├── features/                # 功能快速开始
│   └── ...
└── reports/                     # 交付报告
    ├── acceptance/              # 验收报告
    ├── completion/              # 完成报告
    └── delivery/                # 交付报告

```

## 快速导航

### 🚀 快速开始
- [认证功能快速开始](quickstart/auth/QUICKSTART_AUTH.md)
- [用户功能快速开始](quickstart/features/QUICKSTART_USER_FEATURES.md)
- [依赖扫描快速开始](quickstart/security/QUICKSTART_DEPENDENCY_SCANNING.md)
- [性能监控快速开始](quickstart/monitoring/PERFORMANCE_QUICKSTART.md)
- [日志系统快速开始](quickstart/logging/LOGGING_QUICKSTART.md)

### 📦 功能实现
- [推荐功能实现](features/recommendation/RECOMMENDATION_IMPLEMENTATION.md)
- [搜索功能实现](features/search/SEARCH_IMPLEMENTATION.md)
- [用户认证和收藏功能](features/user/USER_AUTH_FAVORITES_IMPLEMENTATION.md)
- [评论增强功能](features/comment/COMMENT_ENHANCEMENTS_SUMMARY.md)

### 🏗️ 基础设施
- [Docker 配置](infrastructure/docker/DOCKER_SETUP.md)
- [Redis 缓存](infrastructure/cache/REDIS_CACHE_COMPLETE.md)
- [日志聚合](infrastructure/logging/LOG_AGGREGATION_SUMMARY.md)
- [性能监控](infrastructure/monitoring/PERFORMANCE_MONITORING_COMPLETE.md)
- [密钥管理](infrastructure/security/KEY_MANAGEMENT_IMPLEMENTATION.md)

### 🚢 部署文档
- [GitLab CI/CD 配置](deployment/gitlab-ci/GITLAB_CICD_SETUP_COMPLETE.md)
- [GitHub 迁移指南](deployment/github-actions/GITHUB_MIGRATION_READY.md)
- [部署总结](deployment/DEPLOYMENT_SUMMARY.txt)

### 📊 交付报告
- [P1 用户认证实现](reports/delivery/P1_USER_AUTH_IMPLEMENTATION.md)
- [P2 依赖扫描完成](reports/completion/P2_DEPENDENCY_SCANNING_COMPLETE.md)
- [Docker 完成报告](reports/completion/DOCKER_COMPLETION_REPORT.md)
- [测试完成报告](reports/completion/TEST_COMPLETION_REPORT.md)
- [日志交付报告](reports/delivery/LOGGING_DELIVERY.md)
- [交付总结](reports/delivery/DELIVERY_SUMMARY.md)

### ✅ 验收清单
- [P1 验收清单](reports/acceptance/P1_ACCEPTANCE_CHECKLIST.md)
- [日志聚合验收](reports/acceptance/LOG_AGGREGATION_ACCEPTANCE.md)

## 主要文档

### 项目概览
- [README.md](../README.md) - 项目主文档
- [工作流.md](../工作流.md) - 开发工作流

### 产品文档
- [产品需求文档 PRD](../dacong-docs/01-产品需求文档PRD.md)
- [技术方案设计](../dacong-docs/02-技术方案设计.md)
- [数据库设计](../dacong-docs/03-数据库设计.md)
- [API 接口文档](../dacong-docs/04-API接口文档.md)

## 文档维护

### 添加新文档
1. 确定文档类型（功能/基础设施/部署/快速开始/报告）
2. 放入对应的子目录
3. 更新本 README.md 的导航链接

### 文档命名规范
- 功能实现：`{FEATURE}_IMPLEMENTATION.md`
- 快速开始：`QUICKSTART_{FEATURE}.md`
- 完成报告：`{FEATURE}_COMPLETE.md`
- 交付报告：`{FEATURE}_DELIVERY.md`
- 验收清单：`{FEATURE}_ACCEPTANCE.md`

### 文档模板
参考 `docs/templates/` 目录中的模板文件。
