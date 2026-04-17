# 密钥管理文档

## 概述

本文档描述了大聪项目的密钥管理策略、流程和最佳实践。密钥管理是安全工程的核心，直接影响系统的整体安全性。

## 密钥管理原则

### 1. 最小权限原则

- 每个服务只能访问其必需的密钥
- 使用服务账号而非个人账号
- 定期审查和撤销不必要的权限

### 2. 纵深防御

- 密钥分级管理（P0/P1/P2）
- 多层加密保护
- 访问审计和监控

### 3. 密钥轮换

- 定期轮换所有密钥
- 支持零停机轮换
- 保留旧密钥用于解密历史数据

### 4. 安全存储

- 永不硬编码密钥
- 使用环境变量或密钥管理服务
- 加密存储敏感配置

## 密钥分级

### P0 级密钥（关键）

**影响范围**: 数据泄露、系统瘫痪

**密钥列表**:
- `SUPABASE_SERVICE_ROLE_KEY` - 数据库完全访问权限
- `ENCRYPTION_KEY` - 数据加密主密钥
- `DATABASE_URL` - 数据库连接字符串

**轮换周期**: 90 天  
**过期提醒**: 提前 14 天  
**泄露响应**: 立即轮换（< 1 小时）

### P1 级密钥（重要）

**影响范围**: 功能受限、成本增加

**密钥列表**:
- `SUPABASE_ANON_KEY` - 客户端 API 访问
- `GITHUB_TOKEN` - GitHub API 访问
- `OPENROUTER_API_KEY` - AI 服务访问

**轮换周期**: 180 天  
**过期提醒**: 提前 14 天  
**泄露响应**: 24 小时内轮换

### P2 级密钥（一般）

**影响范围**: 开发体验、监控告警

**密钥列表**:
- `SENTRY_DSN` - 错误监控
- `LOG_API_KEY` - 日志服务

**轮换周期**: 365 天  
**过期提醒**: 提前 30 天  
**泄露响应**: 7 天内轮换

## 密钥存储规范

### 开发环境

```bash
# .env.local（不提交到 Git）
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
ENCRYPTION_KEY=<生成的随机密钥>
```

### 生产环境

**使用 Supabase Secrets**:

```bash
# 设置密钥
supabase secrets set ENCRYPTION_KEY=<value>

# 查看密钥列表
supabase secrets list

# 删除密钥
supabase secrets unset ENCRYPTION_KEY
```

### CI/CD 环境

**使用 GitLab CI/CD Variables**:

1. 进入项目 Settings > CI/CD > Variables
2. 添加变量，勾选 "Masked" 和 "Protected"
3. 限制变量只在特定分支可用

## 密钥轮换流程

### 自动轮换（推荐）

```bash
# 1. 轮换单个服务的密钥
./scripts/rotate_keys.sh --service supabase --verify

# 2. 轮换所有密钥
./scripts/rotate_keys.sh --all --verify

# 3. 指定备份目录
./scripts/rotate_keys.sh --service github --backup-dir /secure/backups
```

### 手动轮换步骤

#### 1. Supabase 密钥轮换

```bash
# 步骤 1: 访问 Supabase Dashboard
# https://supabase.com/dashboard/project/<your-project>/settings/api

# 步骤 2: 点击 "Reset" 按钮重新生成密钥

# 步骤 3: 更新环境变量
supabase secrets set SUPABASE_ANON_KEY=<new-key>
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<new-key>

# 步骤 4: 重启服务
supabase functions deploy --no-verify-jwt

# 步骤 5: 验证
curl -H "apikey: <new-key>" https://xxxxx.supabase.co/rest/v1/
```

#### 2. 加密密钥轮换

```bash
# 步骤 1: 生成新密钥
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"

# 步骤 2: 执行数据库密钥轮换
psql $DATABASE_URL -c "SELECT * FROM rotate_encryption_key('old-key', 'new-key', 2);"

# 步骤 3: 更新环境变量
supabase secrets set ENCRYPTION_KEY=<new-key>

# 步骤 4: 重启服务并验证
```

#### 3. JWT 密钥轮换

```bash
# 步骤 1: 生成新密钥
./scripts/rotate_keys.sh --service jwt

# 步骤 2: 通知用户重新登录
# 发送邮件/推送通知

# 步骤 3: 监控错误率
# 检查 Sentry 是否有大量 401 错误
```

## 密钥访问控制

### 访问审计

所有密钥访问都会被记录到 `key_access_logs` 表：

```sql
-- 查看最近的密钥访问
SELECT * FROM recent_key_accesses LIMIT 100;

-- 查看密钥使用统计
SELECT * FROM key_usage_overview;

-- 查看失败的访问尝试
SELECT * FROM key_access_logs
WHERE success = false
ORDER BY created_at DESC;
```

### 异常检测

系统会自动检测以下异常行为：

1. **频繁失败访问**: 5 分钟内超过 10 次失败
2. **可疑 IP**: 短时间内访问多个不同密钥
3. **高频访问**: 1 分钟内超过 100 次访问

```sql
-- 手动触发异常检测
SELECT auto_detect_and_alert();

-- 查看未解决的告警
SELECT * FROM unresolved_alerts;
```

### 告警响应

收到告警后的处理流程：

1. **确认告警**: 检查是否为误报
2. **调查原因**: 查看访问日志和 IP 地址
3. **采取行动**: 
   - 封禁可疑 IP
   - 轮换受影响的密钥
   - 通知相关人员
4. **标记解决**: 更新告警状态

```sql
-- 解决告警
UPDATE key_access_alerts
SET is_resolved = true,
    resolved_at = NOW(),
    resolved_by = 'admin@example.com'
WHERE id = '<alert-id>';
```

## 密钥过期管理

### 自动检查

```bash
# 检查所有密钥的过期状态
./scripts/check_key_expiry.sh

# 生成详细报告
./scripts/check_key_expiry.sh --report

# 发送通知
./scripts/check_key_expiry.sh --notify
```

### 初始化密钥元数据

首次使用时需要初始化：

```bash
./scripts/check_key_expiry.sh --init
```

这会创建 `.env.key_metadata.json` 文件，记录每个密钥的创建时间和轮换历史。

### 配置过期提醒

在 `.gitlab-ci.yml` 中添加定时任务：

```yaml
check-key-expiry:
  stage: security
  script:
    - ./scripts/check_key_expiry.sh --notify
  only:
    - schedules
  # 每周一早上 9 点运行
```

## 密钥泄露检测

### 代码扫描

```bash
# 扫描代码库中的硬编码密钥
./scripts/scan_for_secrets.sh

# 生成详细报告
./scripts/scan_for_secrets.sh --report

# CI 模式（发现问题返回非零退出码）
./scripts/scan_for_secrets.sh --ci
```

### Git 提交前检查

在 `.git/hooks/pre-commit` 中添加：

```bash
#!/bin/bash
./scripts/scan_for_secrets.sh --ci
if [ $? -ne 0 ]; then
    echo "发现密钥泄露，提交被阻止"
    exit 1
fi
```

### .gitignore 配置

确保以下文件不被提交：

```gitignore
# 环境变量
.env
.env.local
.env.*.local

# 密钥文件
*.pem
*.key
*.p12
*.pfx

# 密钥备份
.env.backups/
.env.key_metadata.json
```

## 加密数据管理

### 加密敏感字段

```typescript
import { encryptData, decryptData } from './_shared/utils/encryption';

// 加密邮箱
const encryptedEmail = encryptData('user@example.com');

// 解密邮箱
const email = decryptData(encryptedEmail);
```

### 数据库加密

```sql
-- 加密现有数据
SELECT migrate_profiles_email_to_encrypted('your-encryption-key');

-- 查询加密数据（在应用层解密）
SELECT id, email_encrypted FROM profiles WHERE id = 'xxx';
```

### 密钥版本管理

系统支持多版本密钥，用于平滑轮换：

```sql
-- 查看当前密钥版本
SELECT * FROM encryption_keys WHERE is_active = true;

-- 查看所有密钥版本
SELECT * FROM encryption_keys ORDER BY key_version DESC;
```

## 应急响应

如果发现密钥泄露，请立即执行以下步骤：

1. **立即撤销**: 在服务提供商处撤销泄露的密钥
2. **生成新密钥**: 使用 `rotate_keys.sh` 生成新密钥
3. **更新服务**: 更新所有使用该密钥的服务
4. **审计日志**: 检查泄露期间的访问日志
5. **通知相关方**: 通知团队和受影响的用户
6. **事后分析**: 分析泄露原因，改进流程

详细流程请参考 [密钥泄露应急响应文档](./KEY_LEAK_RESPONSE.md)。

## 最佳实践

### DO ✓

- 使用环境变量存储密钥
- 定期轮换密钥
- 启用访问审计
- 使用强密钥（至少 32 字符）
- 加密敏感数据
- 限制密钥访问权限
- 监控异常访问

### DON'T ✗

- 硬编码密钥到代码中
- 提交 `.env` 文件到 Git
- 在日志中打印密钥
- 通过邮件/聊天工具传输密钥
- 使用弱密钥（如 "password123"）
- 共享个人密钥
- 忽略过期提醒

## 工具和脚本

| 脚本 | 用途 | 使用频率 |
|------|------|----------|
| `rotate_keys.sh` | 密钥轮换 | 每 90 天 |
| `check_key_expiry.sh` | 过期检查 | 每周 |
| `scan_for_secrets.sh` | 泄露扫描 | 每次提交 |

## 合规性

### GDPR 要求

- 用户邮箱必须加密存储
- 支持数据导出和删除
- 记录所有数据访问

### SOC 2 要求

- 密钥访问审计
- 定期密钥轮换
- 访问权限最小化

## 常见问题

### Q: 密钥轮换会导致服务中断吗？

A: 不会。我们的轮换流程支持零停机，旧密钥在轮换后仍可用于解密历史数据。

### Q: 如何在本地开发时使用密钥？

A: 复制 `.env.example` 为 `.env.local`，填入开发环境的密钥。永远不要提交 `.env.local` 到 Git。

### Q: 密钥泄露后多久需要轮换？

A: 取决于密钥级别：
- P0 级：立即（< 1 小时）
- P1 级：24 小时内
- P2 级：7 天内

### Q: 如何生成强密钥？

A: 使用以下命令：

```bash
# 生成 32 字节随机密钥
openssl rand -base64 32

# 或使用 Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

## 相关文档

- [密钥泄露应急响应](./KEY_LEAK_RESPONSE.md)
- [加密实现文档](../_shared/utils/encryption.ts)
- [安全审计指南](./SECURITY_AUDIT.md)

## 联系方式

如有安全问题，请联系：
- 安全团队邮箱: security@dacong.com
- 紧急热线: +86-xxx-xxxx-xxxx
