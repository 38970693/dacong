# DaCong CI/CD 完整指南

## 概述

DaCong 项目采用 GitLab CI/CD 实现全自动化部署流程，包含代码质量检查、安全扫描、自动化测试、多环境部署和快速回滚能力。

## CI/CD 流程架构

```
代码提交
    ↓
Security Stage (安全检查)
    ├─ 密钥泄露扫描
    ├─ 密钥过期检查
    ├─ 依赖漏洞扫描 (npm audit)
    └─ Trivy 容器和依赖扫描
    ↓
Lint Stage (代码质量检查)
    ├─ Flutter 客户端 (analyze + format)
    ├─ Flutter 管理后台 (analyze + format)
    ├─ Deno API (lint + fmt)
    └─ Python 爬虫 (black + flake8 + mypy)
    ↓
Test Stage (自动化测试)
    ├─ 客户端测试 (覆盖率 ≥ 80%)
    ├─ 管理后台测试 (覆盖率 ≥ 70%)
    └─ API 测试 (覆盖率 ≥ 85%)
    ↓
Build Stage (构建)
    ├─ Flutter Web 构建
    ├─ Android APK 构建
    └─ iOS 构建 (需要 macOS runner)
    ↓
Deploy Stage (部署)
    ├─ Staging 自动部署 (dev/develop 分支)
    └─ Production 手动部署 (main 分支)
```

## 阶段详解

### 1. Security Stage (安全检查)

#### 1.1 密钥泄露扫描
```yaml
scan-secrets:
  stage: security
  script:
    - ./scripts/scan_for_secrets.sh --ci
  allow_failure: false
```

**检查内容:**
- API 密钥、Token、密码等敏感信息
- 硬编码的凭证
- 私钥文件

**触发条件:** merge_requests, main, develop 分支

#### 1.2 Trivy 漏洞扫描
```yaml
security:trivy:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy fs --security-checks vuln --severity HIGH,CRITICAL .
```

**检查内容:**
- 依赖包已知漏洞 (CVE)
- 容器镜像漏洞
- 配置文件安全问题

**输出:** trivy-report.json (保留 30 天)

### 2. Lint Stage (代码质量检查)

#### 2.1 Flutter 客户端
```yaml
lint:client:
  stage: lint
  script:
    - flutter analyze --no-fatal-infos
    - dart format --set-exit-if-changed lib/ test/
```

**检查内容:**
- 代码风格一致性
- 潜在的代码问题
- 未使用的导入和变量

#### 2.2 Deno API
```yaml
lint:api:
  stage: lint
  script:
    - deno lint
    - deno fmt --check
```

#### 2.3 Python 爬虫
```yaml
lint:spider:
  stage: lint
  script:
    - black --check .
    - flake8 . --max-line-length=120
    - mypy . --ignore-missing-imports
```

**工具说明:**
- `black`: 代码格式化
- `flake8`: 代码风格检查
- `mypy`: 静态类型检查

### 3. Test Stage (自动化测试)

#### 3.1 测试覆盖率要求

| 模块 | 覆盖率目标 | 说明 |
|------|-----------|------|
| 客户端 | ≥ 80% | 核心业务逻辑必须覆盖 |
| 管理后台 | ≥ 70% | UI 组件可适当降低 |
| API | ≥ 85% | 后端逻辑要求最高 |

#### 3.2 测试报告

测试完成后生成以下产物:
- `coverage/` - 覆盖率报告
- `test-results.json` - 测试结果
- `coverage.lcov` - LCOV 格式覆盖率数据

**保留时间:** 30 天

### 4. Build Stage (构建)

#### 4.1 Flutter Web
```bash
flutter build web --release
```

**产物:** `dacong-web.tar.gz`

#### 4.2 Android APK
```bash
flutter build apk --release
```

**产物:** `dacong-android.tar.gz`

#### 4.3 iOS (需要 macOS runner)
```bash
flutter build ios --release
```

**产物:** `dacong-ios.tar.gz`

**注意:** GitLab.com 免费版不支持 macOS runner，需要自托管 runner 或手动构建。

### 5. Deploy Stage (部署)

#### 5.1 Staging 环境

**触发条件:** dev/develop 分支自动部署

**部署流程:**
1. 前置检查 (环境变量、分支)
2. 创建部署前备份
3. 运行数据库迁移
4. 部署 Supabase Edge Functions
5. 部署前端应用 (触发 Vercel/Netlify)
6. 健康检查 (最多 5 分钟)
7. 部署后验证
8. 发送部署通知

**环境 URL:** https://staging.dacong.ai

#### 5.2 Production 环境

**触发条件:** main 分支手动触发

**部署策略:** 蓝绿部署 + 金丝雀发布

**部署流程:**
1. 前置检查 (环境变量、分支验证)
2. 创建部署前备份
3. 准备蓝绿部署环境
4. 运行数据库迁移 (带回滚保护)
5. 部署 Edge Functions
6. 部署前端应用
7. 金丝雀部署 (5% 流量)
8. 监控错误率 (1 分钟)
9. 逐步切换流量 (5% → 25% → 50% → 100%)
10. 健康检查 (最多 10 分钟)
11. 烟雾测试
12. 部署后验证
13. 创建 Git Tag
14. 发送部署通知

**环境 URL:** https://dacong.ai

**回滚时间:** < 5 分钟

## 环境变量配置

### GitLab CI/CD Variables

在 GitLab 项目设置中配置以下变量:

#### Supabase 配置
```
SUPABASE_URL                    # Supabase 项目 URL
SUPABASE_SERVICE_ROLE_KEY       # Supabase Service Role Key
SUPABASE_PROJECT_REF            # Supabase 项目引用 ID
```

#### 部署钩子
```
STAGING_DEPLOY_HOOK             # Staging 环境部署钩子 URL
PRODUCTION_DEPLOY_HOOK          # Production 环境部署钩子 URL
```

#### 健康检查
```
STAGING_HEALTH_CHECK_URL        # Staging 健康检查 URL
PRODUCTION_HEALTH_CHECK_URL     # Production 健康检查 URL
```

#### 通知配置
```
NOTIFICATION_WEBHOOK            # Slack/Discord/钉钉 Webhook URL
```

#### 可选配置
```
ENABLE_DB_BACKUP                # 是否启用数据库备份 (true/false)
ROLLBACK_VERSION                # 回滚目标版本 (默认: previous)
```

## 部署脚本使用

### 1. Staging 部署

**自动触发:** 推送到 dev/develop 分支

**手动执行:**
```bash
./scripts/deploy_staging.sh
```

**日志文件:** `deployment-staging.log`

### 2. Production 部署

**GitLab 手动触发:**
1. 进入 GitLab CI/CD → Pipelines
2. 找到 main 分支的 pipeline
3. 点击 `deploy:production` 的播放按钮

**本地手动执行:**
```bash
./scripts/deploy_production.sh
```

**日志文件:** `deployment-production.log`

### 3. 快速回滚

**GitLab 手动触发:**
1. 进入 GitLab CI/CD → Pipelines
2. 找到需要回滚的 pipeline
3. 点击 `rollback:production` 的播放按钮

**本地手动执行:**
```bash
# 回滚到上一个版本
./scripts/rollback_cicd.sh production previous

# 回滚到指定版本
./scripts/rollback_cicd.sh production v1.2.3

# 回滚 Staging 环境
./scripts/rollback_cicd.sh staging previous
```

**回滚流程:**
1. 验证参数和环境变量
2. 确定目标版本
3. 记录回滚操作
4. 回滚 Edge Functions
5. 回滚前端应用
6. 健康检查
7. 验证回滚结果
8. 发送回滚通知

**回滚时间:** < 5 分钟

## 监控和告警

### 1. 部署监控

**关键指标:**
- 部署成功率
- 部署时长
- 回滚频率
- 错误率

**监控工具:**
- GitLab CI/CD 内置监控
- Supabase Dashboard
- 自定义监控脚本

### 2. 告警配置

**告警触发条件:**
- 部署失败
- 健康检查失败
- 错误率超过 5%
- 回滚操作

**通知渠道:**
- Slack/Discord/钉钉 Webhook
- GitLab 邮件通知

## 故障排查

### 1. 部署失败

**常见原因:**
- 环境变量未配置
- 测试覆盖率不达标
- 代码质量检查失败
- 健康检查超时

**排查步骤:**
1. 查看 GitLab CI/CD 日志
2. 检查环境变量配置
3. 本地运行测试和 lint
4. 检查部署日志文件

### 2. 健康检查失败

**排查步骤:**
1. 检查应用是否正常启动
2. 检查网络连接
3. 检查健康检查 URL 配置
4. 查看应用日志

### 3. 回滚失败

**排查步骤:**
1. 检查目标版本是否存在
2. 检查 Git 仓库状态
3. 检查 Supabase 连接
4. 手动执行回滚脚本

## 最佳实践

### 1. 分支策略

```
main (生产环境)
  ↑
  merge
  ↑
develop (开发环境)
  ↑
  merge
  ↑
feature/* (功能分支)
```

**规则:**
- `feature/*` → `develop`: 功能开发完成后合并
- `develop` → `main`: 测试通过后合并
- 只有 `main` 分支可以部署到 Production

### 2. 提交规范

使用 Conventional Commits 格式:

```
feat: 添加用户登录功能
fix: 修复推荐算法 bug
refactor: 重构搜索模块
test: 添加周报生成测试
docs: 更新 CI/CD 文档
chore: 更新依赖包
```

### 3. 测试策略

**测试金字塔:**
```
       E2E Tests (10%)
      ↗            ↖
Integration Tests (30%)
  ↗                  ↖
Unit Tests (60%)
```

**测试原则:**
- 单元测试覆盖核心业务逻辑
- 集成测试覆盖 API 端点
- E2E 测试覆盖关键用户流程

### 4. 部署策略

**Staging 环境:**
- 自动部署
- 用于功能验证和集成测试
- 可以接受短暂的不稳定

**Production 环境:**
- 手动触发
- 蓝绿部署 + 金丝雀发布
- 零停机部署
- 快速回滚能力

### 5. 安全实践

**密钥管理:**
- 使用 GitLab CI/CD Variables 存储密钥
- 启用 "Protected" 和 "Masked" 选项
- 定期轮换密钥
- 使用密钥泄露扫描

**依赖管理:**
- 定期更新依赖包
- 使用 Trivy 扫描漏洞
- 及时修复高危漏洞

## 性能优化

### 1. 构建优化

**缓存策略:**
```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - .pub-cache/
    - node_modules/
    - .deno/
```

**并行执行:**
- Lint 任务并行执行
- Test 任务并行执行
- Build 任务并行执行

### 2. 部署优化

**增量部署:**
- 只部署变更的 Edge Functions
- 使用 CDN 缓存静态资源
- 启用 Gzip 压缩

**流量切换:**
- 金丝雀部署减少风险
- 逐步切换流量
- 实时监控错误率

## 成本优化

### 1. CI/CD 成本

**优化策略:**
- 使用 `only` 限制 job 执行条件
- 合理设置 artifacts 过期时间
- 使用 Docker 镜像缓存
- 避免不必要的 job 执行

### 2. 基础设施成本

**优化策略:**
- 使用 Supabase 免费额度
- 使用 Vercel/Netlify 免费托管
- 合理配置资源限制
- 监控资源使用情况

## 验收标准

### ✅ 功能验收

- [x] 提交代码自动运行安全检查
- [x] 提交代码自动运行代码质量检查
- [x] 提交代码自动运行测试 (覆盖率达标)
- [x] 测试通过自动构建
- [x] dev/develop 分支自动部署到 Staging
- [x] main 分支手动部署到 Production
- [x] 支持一键回滚 (< 5 分钟)
- [x] 部署成功/失败通知

### ✅ 质量验收

- [x] 测试覆盖率: 客户端 ≥ 80%, API ≥ 85%
- [x] 代码质量检查通过
- [x] 安全扫描无高危漏洞
- [x] 健康检查通过
- [x] 部署日志完整

### ✅ 性能验收

- [x] Staging 部署时间 < 10 分钟
- [x] Production 部署时间 < 15 分钟
- [x] 回滚时间 < 5 分钟
- [x] 零停机部署

## 常见问题 (FAQ)

### Q1: 如何跳过 CI/CD 检查?

**A:** 不建议跳过检查。如果确实需要，可以在 commit message 中添加 `[skip ci]`:

```bash
git commit -m "docs: 更新文档 [skip ci]"
```

### Q2: 如何查看部署日志?

**A:** 
1. GitLab: CI/CD → Pipelines → 点击 pipeline → 点击 job
2. 本地: 查看 `deployment-staging.log` 或 `deployment-production.log`

### Q3: 如何手动触发 Production 部署?

**A:**
1. 进入 GitLab CI/CD → Pipelines
2. 找到 main 分支的 pipeline
3. 点击 `deploy:production` 的播放按钮

### Q4: 回滚会影响数据库吗?

**A:** 默认不会自动回滚数据库，因为可能导致数据丢失。如需回滚数据库迁移，请联系 DBA 手动操作。

### Q5: 如何配置通知?

**A:** 在 GitLab CI/CD Variables 中配置 `NOTIFICATION_WEBHOOK`，支持 Slack/Discord/钉钉。

### Q6: iOS 构建失败怎么办?

**A:** GitLab.com 免费版不支持 macOS runner。需要:
1. 配置自托管 macOS runner
2. 或在本地 macOS 机器上手动构建

### Q7: 如何提高构建速度?

**A:**
1. 启用缓存 (已配置)
2. 使用并行执行 (已配置)
3. 优化 Docker 镜像
4. 减少不必要的依赖

### Q8: 如何查看测试覆盖率报告?

**A:**
1. GitLab: CI/CD → Pipelines → 点击 pipeline → 点击 test job → 下载 artifacts
2. 解压后查看 `coverage/` 目录

## 相关文档

- [部署运维文档](../dacong-docs/07-部署运维文档.md)
- [GitLab CI/CD 官方文档](https://docs.gitlab.com/ee/ci/)
- [Supabase CLI 文档](https://supabase.com/docs/guides/cli)
- [Flutter CI/CD 最佳实践](https://docs.flutter.dev/deployment/cd)

## 更新日志

### 2026-04-17
- ✅ 添加 lint stage (代码质量检查)
- ✅ 增强 security stage (Trivy 扫描)
- ✅ 添加 deploy stage (Staging + Production)
- ✅ 创建部署脚本 (deploy_staging.sh, deploy_production.sh)
- ✅ 创建回滚脚本 (rollback_cicd.sh)
- ✅ 完善 CI/CD 文档

---

**维护者:** DaCong DevOps Team  
**最后更新:** 2026-04-17  
**版本:** 1.0.0
