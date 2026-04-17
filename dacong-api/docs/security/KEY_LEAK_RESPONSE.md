# 密钥泄露应急响应文档

## 概述

本文档定义了密钥泄露事件的应急响应流程。密钥泄露是严重的安全事件，需要快速、系统化的响应。

## 响应等级

### P0 - 关键（Critical）

**定义**: 数据库密钥、加密主密钥泄露

**影响**: 
- 数据库完全访问权限
- 所有加密数据可被解密
- 系统完全失控

**响应时间**: 立即（< 1 小时）

**涉及密钥**:
- `SUPABASE_SERVICE_ROLE_KEY`
- `ENCRYPTION_KEY`
- `DATABASE_URL`

### P1 - 高危（High）

**定义**: API 密钥、服务密钥泄露

**影响**:
- 功能受限
- 成本增加
- 数据部分泄露

**响应时间**: 24 小时内

**涉及密钥**:
- `SUPABASE_ANON_KEY`
- `GITHUB_TOKEN`
- `OPENROUTER_API_KEY`

### P2 - 中危（Medium）

**定义**: 监控、日志服务密钥泄露

**影响**:
- 监控失效
- 日志泄露

**响应时间**: 7 天内

**涉及密钥**:
- `SENTRY_DSN`
- `LOG_API_KEY`

## 应急响应流程

### 阶段 1: 发现与确认（0-15 分钟）

#### 1.1 发现途径

- 自动扫描工具告警
- GitHub Secret Scanning 通知
- 团队成员报告
- 异常访问日志
- 第三方安全研究员报告

#### 1.2 确认泄露

```bash
# 检查 Git 历史
git log -p --all -S 'SUPABASE_SERVICE_ROLE_KEY'

# 检查公开仓库
./scripts/scan_for_secrets.sh --report

# 检查访问日志
psql $DATABASE_URL -c "
SELECT * FROM key_access_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
  AND success = false
ORDER BY created_at DESC;
"
```

#### 1.3 记录事件

创建事件记录文件：

```bash
# 创建事件目录
mkdir -p incidents/$(date +%Y%m%d_%H%M%S)_key_leak

# 记录基本信息
cat > incidents/$(date +%Y%m%d_%H%M%S)_key_leak/incident.md << EOF
# 密钥泄露事件

## 基本信息
- 发现时间: $(date)
- 发现人: [姓名]
- 泄露密钥: [密钥名称]
- 泄露等级: [P0/P1/P2]
- 泄露途径: [Git/日志/其他]

## 时间线
- [时间] 发现泄露
- [时间] 确认泄露
- [时间] 启动应急响应

## 影响范围
- [描述]

## 响应措施
- [记录所有响应措施]
EOF
```

### 阶段 2: 遏制（15-30 分钟）

#### 2.1 立即撤销泄露的密钥

**Supabase 密钥**:

```bash
# 1. 登录 Supabase Dashboard
# https://supabase.com/dashboard/project/<your-project>/settings/api

# 2. 点击 "Reset" 按钮立即撤销旧密钥

# 3. 记录新密钥（临时存储在安全位置）
```

**GitHub Token**:

```bash
# 1. 访问 https://github.com/settings/tokens
# 2. 找到泄露的 token，点击 "Delete"
# 3. 立即生成新 token
```

**OpenRouter API Key**:

```bash
# 1. 访问 https://openrouter.ai/keys
# 2. 撤销泄露的密钥
# 3. 生成新密钥
```

#### 2.2 封锁可疑访问

```sql
-- 查看可疑 IP
SELECT DISTINCT ip_address, COUNT(*) as access_count
FROM key_access_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY ip_address
ORDER BY access_count DESC;

-- 创建 IP 黑名单（在防火墙/WAF 中配置）
```

#### 2.3 通知团队

```bash
# 发送紧急通知
# - Slack: #security-alerts
# - 邮件: security@dacong.com
# - 电话: 紧急联系人

# 通知内容模板
cat << EOF
【紧急】密钥泄露事件

密钥: [密钥名称]
等级: [P0/P1/P2]
状态: 已撤销
影响: [简要描述]

请所有相关人员待命，准备执行恢复流程。

事件负责人: [姓名]
EOF
```

### 阶段 3: 根除（30-60 分钟）

#### 3.1 清理泄露源

**从 Git 历史中删除**:

```bash
# 使用 BFG Repo-Cleaner
java -jar bfg.jar --replace-text passwords.txt .git

# 或使用 git filter-branch
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# 强制推送（警告：会重写历史）
git push origin --force --all
git push origin --force --tags
```

**从日志中删除**:

```bash
# 查找包含密钥的日志文件
grep -r "SUPABASE_SERVICE_ROLE_KEY" /var/log/

# 删除或脱敏日志
sed -i 's/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[^"]*/**REDACTED**/g' /var/log/app.log
```

#### 3.2 轮换所有相关密钥

```bash
# 轮换泄露的密钥
./scripts/rotate_keys.sh --service supabase --verify

# 如果是加密密钥泄露，需要重新加密所有数据
psql $DATABASE_URL -c "
SELECT * FROM rotate_encryption_key(
  'old-leaked-key',
  'new-secure-key',
  2
);
"
```

#### 3.3 更新所有服务

```bash
# 更新生产环境
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<new-key>

# 更新 CI/CD
# 在 GitLab CI/CD Variables 中更新

# 重启所有服务
kubectl rollout restart deployment/dacong-api
```

### 阶段 4: 恢复（1-2 小时）

#### 4.1 验证服务正常

```bash
# 健康检查
curl https://api.dacong.com/health

# 验证数据库连接
psql $DATABASE_URL -c "SELECT 1;"

# 验证加密/解密
node -e "
const { encryptData, decryptData } = require('./_shared/utils/encryption');
const test = 'test-data';
const encrypted = encryptData(test);
const decrypted = decryptData(encrypted);
console.log(decrypted === test ? '✓ 加密正常' : '✗ 加密失败');
"
```

#### 4.2 监控异常

```bash
# 监控错误率
curl https://api.dacong.com/metrics | grep error_rate

# 检查 Sentry 错误
# 访问 Sentry Dashboard

# 查看访问日志
tail -f /var/log/app.log | grep ERROR
```

#### 4.3 通知用户（如需要）

如果泄露影响用户数据，需要通知用户：

```markdown
# 用户通知模板

尊敬的用户：

我们在 [日期] 发现了一起安全事件，可能影响您的账户安全。

**发生了什么**:
[简要描述，不泄露技术细节]

**我们的措施**:
- 已立即撤销泄露的密钥
- 已加强安全监控
- 已修复安全漏洞

**您需要做什么**:
- 重新登录您的账户
- 修改密码（如果使用相同密码）
- 检查账户活动记录

如有疑问，请联系 support@dacong.com

大聪团队
[日期]
```

### 阶段 5: 事后分析（2-7 天）

#### 5.1 根因分析

使用 5 Whys 方法：

```markdown
# 根因分析

## 问题
密钥泄露到 Git 仓库

## 5 Whys
1. 为什么密钥泄露到 Git？
   - 开发者将 .env 文件提交到 Git

2. 为什么开发者提交了 .env 文件？
   - .gitignore 未正确配置

3. 为什么 .gitignore 未正确配置？
   - 项目初始化时遗漏

4. 为什么项目初始化时遗漏？
   - 缺少项目模板和检查清单

5. 为什么缺少项目模板？
   - 团队未建立标准化流程

## 根本原因
缺少标准化的项目初始化流程和自动化检查
```

#### 5.2 改进措施

```markdown
# 改进措施

## 短期（1 周内）
- [ ] 为所有仓库添加 pre-commit hook
- [ ] 启用 GitHub Secret Scanning
- [ ] 更新 .gitignore 模板

## 中期（1 个月内）
- [ ] 建立密钥管理培训计划
- [ ] 实施自动化密钥轮换
- [ ] 部署密钥管理服务（如 HashiCorp Vault）

## 长期（3 个月内）
- [ ] 建立安全文化
- [ ] 定期安全审计
- [ ] 实施零信任架构
```

#### 5.3 事件报告

```markdown
# 密钥泄露事件报告

## 执行摘要
[一段话总结事件]

## 事件详情
- 发现时间: [时间]
- 泄露密钥: [密钥名称]
- 泄露途径: [途径]
- 影响范围: [范围]

## 时间线
| 时间 | 事件 | 负责人 |
|------|------|--------|
| 10:00 | 发现泄露 | 张三 |
| 10:15 | 确认泄露 | 李四 |
| 10:20 | 撤销密钥 | 王五 |
| 10:45 | 轮换完成 | 王五 |
| 11:00 | 服务恢复 | 赵六 |

## 影响评估
- 数据泄露: 无
- 服务中断: 15 分钟
- 财务损失: 无
- 用户影响: 无

## 响应措施
1. 立即撤销泄露的密钥
2. 轮换所有相关密钥
3. 清理 Git 历史
4. 加强监控

## 根因分析
[详细分析]

## 改进措施
[详细措施]

## 经验教训
1. [教训 1]
2. [教训 2]
3. [教训 3]

## 附录
- 访问日志: [链接]
- 监控数据: [链接]
- 通知记录: [链接]
```

## 应急联系人

| 角色 | 姓名 | 电话 | 邮箱 |
|------|------|------|------|
| 安全负责人 | [姓名] | [电话] | security@dacong.com |
| 技术负责人 | [姓名] | [电话] | tech@dacong.com |
| 运维负责人 | [姓名] | [电话] | ops@dacong.com |
| CEO | [姓名] | [电话] | ceo@dacong.com |

## 应急工具箱

### 快速命令

```bash
# 1. 快速撤销 Supabase 密钥
# 访问: https://supabase.com/dashboard/project/<your-project>/settings/api

# 2. 快速轮换密钥
./scripts/rotate_keys.sh --service <service> --verify

# 3. 快速检查访问日志
psql $DATABASE_URL -c "
SELECT * FROM key_access_logs
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 100;
"

# 4. 快速生成新密钥
openssl rand -base64 32

# 5. 快速清理 Git 历史
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all
```

### 检查清单

```markdown
## 密钥泄露响应检查清单

### 发现与确认
- [ ] 确认泄露的密钥
- [ ] 确认泄露途径
- [ ] 确认泄露时间
- [ ] 评估影响范围
- [ ] 创建事件记录

### 遏制
- [ ] 撤销泄露的密钥
- [ ] 封锁可疑 IP
- [ ] 通知团队
- [ ] 启动应急响应

### 根除
- [ ] 清理泄露源（Git/日志）
- [ ] 轮换所有相关密钥
- [ ] 更新所有服务
- [ ] 验证清理完成

### 恢复
- [ ] 验证服务正常
- [ ] 监控异常
- [ ] 通知用户（如需要）
- [ ] 恢复正常运营

### 事后分析
- [ ] 根因分析
- [ ] 制定改进措施
- [ ] 编写事件报告
- [ ] 团队复盘
- [ ] 更新流程文档
```

## 预防措施

### 技术措施

1. **Pre-commit Hook**:
   ```bash
   # .git/hooks/pre-commit
   #!/bin/bash
   ./scripts/scan_for_secrets.sh --ci
   ```

2. **GitHub Secret Scanning**:
   - 在仓库设置中启用
   - 配置自定义模式

3. **环境变量管理**:
   - 使用 Supabase Secrets
   - 使用 HashiCorp Vault
   - 使用 AWS Secrets Manager

4. **访问审计**:
   - 记录所有密钥访问
   - 实时异常检测
   - 定期审查日志

### 流程措施

1. **密钥管理培训**:
   - 新员工入职培训
   - 定期安全意识培训
   - 模拟演练

2. **代码审查**:
   - 所有 PR 必须经过审查
   - 重点检查配置文件
   - 使用自动化工具

3. **定期审计**:
   - 每季度密钥审计
   - 每月访问日志审查
   - 每年渗透测试

## 相关文档

- [密钥管理文档](./KEY_MANAGEMENT.md)
- [安全审计指南](./SECURITY_AUDIT.md)
- [事件响应流程](./INCIDENT_RESPONSE.md)

## 版本历史

| 版本 | 日期 | 修改内容 | 作者 |
|------|------|----------|------|
| 1.0 | 2026-04-18 | 初始版本 | 安全团队 |
