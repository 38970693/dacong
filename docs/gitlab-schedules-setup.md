# GitLab CI/CD Schedules 配置指南

## 概述

本文档说明如何在 GitLab 中配置定时任务，用于自动化安全扫描和爬虫调度。

## 前置条件

- GitLab 项目已启用 CI/CD
- 已配置 GitLab Runner（使用 docker executor）
- 已设置必要的环境变量

## 定时任务配置

### 1. 安全扫描定时任务（每日）

**用途**: 每日自动运行安全漏洞扫描

**配置步骤**:
1. 进入 GitLab 项目 → **CI/CD** → **Schedules**
2. 点击 **New schedule**
3. 填写以下信息：
   - **Description**: `Daily Security Scan`
   - **Interval Pattern**: `0 2 * * *` (每天凌晨 2 点)
   - **Cron timezone**: `Asia/Shanghai` (或您的时区)
   - **Target Branch**: `main`
   - **Variables**:
     - Key: `SCHEDULE_TYPE`, Value: `security`
   - **Activated**: ✅ 勾选

**触发的 Jobs**:
- `check-key-expiry` - 密钥过期检查
- `security:flutter-client` - Flutter 客户端依赖扫描
- `security:flutter-admin` - Flutter 管理后台依赖扫描
- `security:python` - Python 爬虫依赖扫描
- `security:npm` - Next.js 控制台依赖扫描
- `security:trivy` - 容器和依赖漏洞扫描

### 2. 爬虫调度定时任务（每小时）

**用途**: 每小时运行一次爬虫任务

**配置步骤**:
1. 进入 GitLab 项目 → **CI/CD** → **Schedules**
2. 点击 **New schedule**
3. 填写以下信息：
   - **Description**: `Spider Scheduler - Hourly`
   - **Interval Pattern**: `0 * * * *` (每小时整点)
   - **Cron timezone**: `Asia/Shanghai`
   - **Target Branch**: `main`
   - **Variables**:
     - Key: `SCHEDULE_TYPE`, Value: `spider`
   - **Activated**: ✅ 勾选

**触发的 Jobs**:
- `spider-scheduler` - 爬虫任务调度

### 3. 周度全面安全审计（每周）

**用途**: 每周进行全面的安全审计和报告

**配置步骤**:
1. 进入 GitLab 项目 → **CI/CD** → **Schedules**
2. 点击 **New schedule**
3. 填写以下信息：
   - **Description**: `Weekly Security Audit`
   - **Interval Pattern**: `0 3 * * 1` (每周一凌晨 3 点)
   - **Cron timezone**: `Asia/Shanghai`
   - **Target Branch**: `main`
   - **Variables**:
     - Key: `SCHEDULE_TYPE`, Value: `security`
     - Key: `AUDIT_LEVEL`, Value: `full`
   - **Activated**: ✅ 勾选

## 环境变量配置

在 GitLab 项目中配置以下环境变量（**Settings** → **CI/CD** → **Variables**）:

### 必需变量

| 变量名 | 说明 | 保护 | 掩码 |
|--------|------|------|------|
| `SUPABASE_URL` | Supabase 项目 URL | ✅ | ❌ |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase 服务密钥 | ✅ | ✅ |
| `SUPABASE_ANON_KEY` | Supabase 匿名密钥 | ✅ | ✅ |

### 可选变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `SPIDER_LOG_LEVEL` | 爬虫日志级别 | `INFO` |
| `FLUTTER_VERSION` | Flutter 版本 | `3.24.0` |

## 手动触发定时任务

如需立即运行定时任务而不等待下次调度：

1. 进入 **CI/CD** → **Schedules**
2. 找到对应的定时任务
3. 点击 **Play** 按钮 ▶️

## 查看执行结果

### 查看 Pipeline 状态
1. 进入 **CI/CD** → **Pipelines**
2. 查找带有 `scheduled` 标签的 pipeline
3. 点击查看详细日志

### 下载安全报告
1. 进入对应的 Pipeline
2. 在右侧 **Job artifacts** 中下载报告：
   - `key-expiry-report` - 密钥过期报告
   - `flutter-client-dependency-report` - Flutter 客户端依赖报告
   - `python-dependency-report` - Python 依赖报告
   - `trivy-security-report` - Trivy 安全扫描报告

## Cron 表达式参考

```
┌───────────── 分钟 (0 - 59)
│ ┌───────────── 小时 (0 - 23)
│ │ ┌───────────── 日期 (1 - 31)
│ │ │ ┌───────────── 月份 (1 - 12)
│ │ │ │ ┌───────────── 星期 (0 - 6) (0 = 周日)
│ │ │ │ │
* * * * *
```

**常用示例**:
- `0 * * * *` - 每小时整点
- `0 2 * * *` - 每天凌晨 2 点
- `0 3 * * 1` - 每周一凌晨 3 点
- `*/30 * * * *` - 每 30 分钟
- `0 0 1 * *` - 每月 1 号凌晨

## 通知配置

### 配置失败通知

1. 进入 **Settings** → **Integrations**
2. 选择通知方式：
   - **Slack notifications** - Slack 通知
   - **Microsoft Teams notifications** - Teams 通知
   - **Emails on push** - 邮件通知

3. 配置触发条件：
   - ✅ Pipeline events
   - ✅ Failed pipelines only

## 故障排查

### 定时任务未执行

**检查项**:
1. 定时任务是否已激活（Activated）
2. Cron 表达式是否正确
3. 目标分支是否存在
4. GitLab Runner 是否在线

**查看日志**:
```bash
# 在 GitLab UI 中查看
CI/CD → Schedules → [任务名] → 查看最近的 pipeline
```

### 安全扫描失败

**常见原因**:
1. 依赖文件缺失（`requirements.txt`, `pubspec.yaml`）
2. 网络问题导致无法下载扫描工具
3. Runner 资源不足

**解决方案**:
```bash
# 本地测试安全扫描
cd dacong-spider
pip install pip-audit safety
pip-audit --requirement requirements.txt
safety check --file requirements.txt
```

### 爬虫任务超时

**调整超时时间**:

在 `.gitlab-ci.yml` 中修改：
```yaml
spider-scheduler:
  timeout: 55m  # 调整为合适的时间
```

## 最佳实践

1. **错峰调度**: 避免多个定时任务同时运行
2. **合理超时**: 根据任务实际运行时间设置 timeout
3. **保留日志**: 设置合理的 artifacts 过期时间
4. **监控告警**: 配置失败通知，及时发现问题
5. **定期审查**: 每月检查定时任务执行情况和报告

## 相关文档

- [GitLab CI/CD Schedules 官方文档](https://docs.gitlab.com/ee/ci/pipelines/schedules.html)
- [Cron 表达式生成器](https://crontab.guru/)
- [项目安全扫描配置](./.gitlab-ci.yml)
