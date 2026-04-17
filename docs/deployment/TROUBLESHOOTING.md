# 故障排查指南

## 概述

本文档提供常见问题的诊断和解决方案，帮助快速定位和修复生产环境问题。

---

## 1. 故障排查流程

```
问题报告
    ↓
收集信息（日志、指标、用户反馈）
    ↓
定位问题（应用层、数据库层、基础设施层）
    ↓
制定解决方案
    ↓
执行修复
    ↓
验证修复
    ↓
记录问题和解决方案
```

---

## 2. 数据库问题

### 2.1 连接失败

**症状**：
- 应用无法连接到数据库
- 错误信息：`connection refused` 或 `timeout`

**诊断**：
```bash
# 测试数据库连接
psql $DATABASE_URL -c "SELECT 1;"

# 检查 Supabase 服务状态
curl -I https://your-project.supabase.co

# 检查网络连接
ping db.your-project.supabase.co
```

**解决方案**：
1. 检查 `DATABASE_URL` 是否正确
2. 检查 Supabase 服务状态（访问 status.supabase.com）
3. 检查防火墙规则
4. 检查连接池配置
5. 重启应用服务

### 2.2 查询慢

**症状**：
- API 响应时间 > 2 秒
- 数据库 CPU 使用率高

**诊断**：
```sql
-- 查看当前运行的查询
SELECT 
    pid,
    now() - query_start as duration,
    state,
    query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

-- 查看慢查询
SELECT 
    query,
    calls,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 20;

-- 查看表统计信息
SELECT 
    schemaname,
    tablename,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
```

**解决方案**：
1. 添加缺失的索引：
```sql
-- 查找缺失索引的建议
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats
WHERE schemaname = 'public'
    AND n_distinct > 100
    AND correlation < 0.1;

-- 创建索引
CREATE INDEX CONCURRENTLY idx_published_content_status 
ON published_content(status);
```

2. 优化查询：
```sql
-- 使用 EXPLAIN ANALYZE 分析查询
EXPLAIN ANALYZE
SELECT * FROM published_content 
WHERE status = 'published' 
ORDER BY created_at DESC 
LIMIT 20;
```

3. 清理死元组：
```sql
VACUUM ANALYZE published_content;
```

4. 更新统计信息：
```sql
ANALYZE published_content;
```

### 2.3 连接池耗尽

**症状**：
- 错误信息：`too many connections`
- 新请求无法建立连接

**诊断**：
```sql
-- 查看当前连接数
SELECT count(*) FROM pg_stat_activity;

-- 查看最大连接数
SHOW max_connections;

-- 查看各状态的连接数
SELECT state, count(*) 
FROM pg_stat_activity 
GROUP BY state;
```

**解决方案**：
1. 终止空闲连接：
```sql
-- 终止空闲超过 5 分钟的连接
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
    AND state_change < now() - interval '5 minutes';
```

2. 优化连接池配置：
```env
# .env
DB_POOL_SIZE=15
DB_POOL_TIMEOUT=30
DB_POOL_IDLE_TIMEOUT=300
```

3. 使用连接池（PgBouncer）：
```bash
# 安装 PgBouncer
sudo apt install pgbouncer

# 配置 /etc/pgbouncer/pgbouncer.ini
[databases]
dacong = host=db.your-project.supabase.co port=5432 dbname=postgres

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = md5
pool_mode = transaction
max_client_conn = 100
default_pool_size = 20
```

### 2.4 数据不一致

**症状**：
- 数据丢失或重复
- 外键约束错误

**诊断**：
```sql
-- 检查孤立记录
SELECT gc.id, gc.raw_data_id
FROM generated_content gc
LEFT JOIN raw_data rd ON gc.raw_data_id = rd.id
WHERE rd.id IS NULL;

-- 检查重复记录
SELECT content_id, count(*)
FROM user_feedback
GROUP BY content_id
HAVING count(*) > 1;

-- 检查约束违规
SELECT conname, conrelid::regclass, confrelid::regclass
FROM pg_constraint
WHERE contype = 'f';
```

**解决方案**：
1. 修复孤立记录：
```sql
-- 删除孤立记录
DELETE FROM generated_content
WHERE raw_data_id NOT IN (SELECT id FROM raw_data);

-- 或添加缺失的父记录
INSERT INTO raw_data (id, ...) 
SELECT DISTINCT raw_data_id, ... 
FROM generated_content 
WHERE raw_data_id NOT IN (SELECT id FROM raw_data);
```

2. 修复重复记录：
```sql
-- 保留最新的记录，删除旧的
DELETE FROM user_feedback a
USING user_feedback b
WHERE a.id < b.id
    AND a.content_id = b.content_id
    AND a.user_id = b.user_id;
```

---

## 3. API 问题

### 3.1 API 响应慢

**症状**：
- API 响应时间 > 2 秒
- 用户体验差

**诊断**：
```bash
# 测试 API 响应时间
time curl https://api.dacong.com/v1/content

# 查看 Supabase API 日志
supabase logs api --follow

# 使用 curl 查看详细时间
curl -w "@curl-format.txt" -o /dev/null -s https://api.dacong.com/v1/content

# curl-format.txt 内容：
# time_namelookup:  %{time_namelookup}\n
# time_connect:  %{time_connect}\n
# time_appconnect:  %{time_appconnect}\n
# time_pretransfer:  %{time_pretransfer}\n
# time_redirect:  %{time_redirect}\n
# time_starttransfer:  %{time_starttransfer}\n
# time_total:  %{time_total}\n
```

**解决方案**：
1. 启用查询缓存
2. 优化数据库查询
3. 添加 CDN 缓存
4. 使用分页减少数据量
5. 启用 gzip 压缩

### 3.2 API 返回 500 错误

**症状**：
- API 返回 Internal Server Error
- 错误日志中有异常堆栈

**诊断**：
```bash
# 查看 Edge Functions 日志
supabase functions logs rank-calc --follow

# 查看错误详情
supabase functions logs rank-calc | grep ERROR

# 测试 Edge Function
curl -X POST \
  https://your-project.supabase.co/functions/v1/rank-calc \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content_id": "test"}' \
  -v
```

**解决方案**：
1. 检查错误日志定位问题
2. 验证输入参数
3. 检查环境变量配置
4. 添加错误处理和日志
5. 重新部署函数

### 3.3 CORS 错误

**症状**：
- 浏览器控制台显示 CORS 错误
- 前端无法调用 API

**诊断**：
```bash
# 测试 CORS 配置
curl -H "Origin: https://app.dacong.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -X OPTIONS \
  https://api.dacong.com/v1/content \
  -v
```

**解决方案**：
1. 在 Supabase Dashboard 配置 CORS：
   - Settings > API > CORS
   - 添加允许的域名：`https://app.dacong.com`

2. 在 Edge Functions 中添加 CORS 头：
```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  // 处理 OPTIONS 请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // 业务逻辑
  const result = await handleRequest(req);
  
  return new Response(JSON.stringify(result), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
```

---

## 4. 爬虫问题

### 4.1 爬虫服务停止

**症状**：
- 爬虫服务未运行
- 没有新数据入库

**诊断**：
```bash
# 检查服务状态
sudo systemctl status dacong-spider

# 查看日志
sudo journalctl -u dacong-spider -n 100

# 查看错误日志
sudo journalctl -u dacong-spider -p err -n 50

# 检查进程
ps aux | grep python | grep spider
```

**解决方案**：
```bash
# 重启服务
sudo systemctl restart dacong-spider

# 如果重启失败，查看详细错误
sudo systemctl status dacong-spider -l

# 手动运行测试
cd /home/dacong/dacong/dacong-spider
source venv/bin/activate
python -m schedulers.jobs

# 检查配置文件
cat .env | grep -v "^#" | grep -v "^$"
```

### 4.2 爬虫频繁失败

**症状**：
- 爬虫日志中大量错误
- 数据质量差

**诊断**：
```bash
# 查看失败日志
sudo journalctl -u dacong-spider | grep "FAILED"

# 统计失败率
sudo journalctl -u dacong-spider --since "1 hour ago" | grep -c "FAILED"
sudo journalctl -u dacong-spider --since "1 hour ago" | grep -c "SUCCESS"

# 查看数据库中的失败记录
psql $DATABASE_URL -c "
SELECT 
    source,
    status,
    count(*),
    max(created_at) as last_attempt
FROM spider_logs
WHERE status = 'failed'
    AND created_at > now() - interval '1 day'
GROUP BY source, status;
"
```

**解决方案**：
1. 检查网络连接
2. 检查 API 限流
3. 增加重试次数和延迟
4. 更新爬虫规则
5. 添加错误处理

### 4.3 爬虫内存泄漏

**症状**：
- 内存使用持续增长
- 服务器内存不足

**诊断**：
```bash
# 查看进程内存使用
ps aux | grep python | grep spider

# 实时监控内存
top -p $(pgrep -f "python.*spider")

# 查看系统内存
free -h

# 使用 memory_profiler
pip install memory_profiler
python -m memory_profiler schedulers/jobs.py
```

**解决方案**：
1. 定期重启服务：
```bash
# 配置 systemd 自动重启
sudo nano /etc/systemd/system/dacong-spider.service

# 添加
[Service]
RuntimeMaxSec=86400  # 24 小时后自动重启
```

2. 优化代码，释放资源：
```python
# 使用上下文管理器
with requests.Session() as session:
    response = session.get(url)
    # 处理响应
    
# 显式删除大对象
del large_data
gc.collect()
```

---

## 5. 前端问题

### 5.1 页面加载慢

**症状**：
- 首屏加载时间 > 3 秒
- 用户体验差

**诊断**：
```bash
# 使用 Lighthouse 分析
# Chrome DevTools > Lighthouse > Generate report

# 检查资源大小
curl -I https://app.dacong.com

# 检查 CDN 缓存
curl -I https://app.dacong.com | grep -i cache
```

**解决方案**：
1. 启用代码分割
2. 压缩图片资源
3. 启用 CDN 缓存
4. 使用懒加载
5. 优化字体加载

### 5.2 白屏问题

**症状**：
- 页面显示空白
- 控制台有 JavaScript 错误

**诊断**：
```javascript
// 打开浏览器控制台查看错误
// Chrome DevTools > Console

// 检查网络请求
// Chrome DevTools > Network

// 查看 Sentry 错误报告
```

**解决方案**：
1. 检查 JavaScript 错误
2. 验证 API 端点
3. 检查环境变量配置
4. 清除浏览器缓存
5. 回滚到上一个稳定版本

### 5.3 认证失败

**症状**：
- 用户无法登录
- Token 过期错误

**诊断**：
```dart
// 检查 Supabase 配置
print(supabase.auth.currentSession);

// 测试登录
final response = await supabase.auth.signInWithPassword(
  email: 'test@example.com',
  password: 'password',
);
print(response);
```

**解决方案**：
1. 检查 `SUPABASE_URL` 和 `SUPABASE_ANON_KEY`
2. 验证用户邮箱
3. 重置密码
4. 检查 JWT 过期时间
5. 清除本地存储

---

## 6. 性能问题

### 6.1 CPU 使用率高

**症状**：
- 服务器 CPU 使用率 > 80%
- 应用响应慢

**诊断**：
```bash
# 查看 CPU 使用率
top

# 查看进程 CPU 使用
ps aux --sort=-%cpu | head -10

# 查看 CPU 历史
sar -u 1 10
```

**解决方案**：
1. 优化代码逻辑
2. 增加服务器资源
3. 使用缓存减少计算
4. 异步处理耗时任务
5. 负载均衡

### 6.2 内存不足

**症状**：
- 内存使用率 > 90%
- OOM Killer 杀死进程

**诊断**：
```bash
# 查看内存使用
free -h

# 查看进程内存使用
ps aux --sort=-%mem | head -10

# 查看 OOM 日志
dmesg | grep -i "out of memory"
sudo journalctl -k | grep -i "killed process"
```

**解决方案**：
1. 增加服务器内存
2. 优化内存使用
3. 启用 swap
4. 限制进程内存使用
5. 定期重启服务

### 6.3 磁盘空间不足

**症状**：
- 磁盘使用率 > 90%
- 无法写入文件

**诊断**：
```bash
# 查看磁盘使用
df -h

# 查找大文件
du -h / | sort -rh | head -20

# 查找大目录
du -sh /* | sort -rh | head -10
```

**解决方案**：
```bash
# 清理日志文件
sudo journalctl --vacuum-time=7d
sudo find /var/log -name "*.log" -mtime +30 -delete

# 清理旧备份
find /home/dacong/backups -name "*.sql.gz" -mtime +30 -delete

# 清理 Docker（如果使用）
docker system prune -a

# 清理 APT 缓存
sudo apt clean
sudo apt autoclean
```

---

## 7. 网络问题

### 7.1 DNS 解析失败

**症状**：
- 域名无法访问
- DNS 查询超时

**诊断**：
```bash
# 测试 DNS 解析
dig dacong.com
nslookup dacong.com

# 测试不同 DNS 服务器
dig @8.8.8.8 dacong.com
dig @1.1.1.1 dacong.com

# 检查 DNS 传播
# 访问 https://www.whatsmydns.net/
```

**解决方案**：
1. 检查 DNS 记录配置
2. 等待 DNS 传播（最多 24 小时）
3. 清除本地 DNS 缓存
4. 更换 DNS 服务器
5. 联系域名注册商

### 7.2 SSL 证书错误

**症状**：
- 浏览器显示"不安全"
- SSL 证书过期或无效

**诊断**：
```bash
# 检查证书有效期
openssl s_client -connect dacong.com:443 -servername dacong.com < /dev/null 2>/dev/null | openssl x509 -noout -dates

# 检查证书链
openssl s_client -connect dacong.com:443 -servername dacong.com < /dev/null 2>/dev/null | openssl x509 -noout -text

# 测试 SSL 配置
# 访问 https://www.ssllabs.com/ssltest/
```

**解决方案**：
1. 续期 SSL 证书
2. 检查证书链完整性
3. 更新 Nginx 配置
4. 重启 Nginx
5. 清除浏览器缓存

### 7.3 CDN 缓存问题

**症状**：
- 用户看到旧内容
- 更新未生效

**诊断**：
```bash
# 检查缓存状态
curl -I https://dacong.com | grep -i cache

# 检查 Cloudflare 缓存
curl -I https://dacong.com | grep -i cf-cache-status
```

**解决方案**：
1. 清除 CDN 缓存：
   - Cloudflare Dashboard > Caching > Purge Everything
2. 设置正确的缓存头
3. 使用版本号或哈希值
4. 配置缓存规则

---

## 8. 安全问题

### 8.1 疑似攻击

**症状**：
- 异常流量激增
- 大量失败的登录尝试

**诊断**：
```bash
# 查看访问日志
sudo tail -f /var/log/nginx/access.log

# 统计 IP 访问次数
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -20

# 查看失败的登录尝试
sudo journalctl -u dacong-spider | grep "authentication failed"

# 检查 Cloudflare 安全事件
# Cloudflare Dashboard > Security > Events
```

**解决方案**：
1. 启用 Cloudflare 防火墙规则
2. 限制 API 请求频率
3. 封禁恶意 IP
4. 启用验证码
5. 通知安全团队

### 8.2 数据泄露

**症状**：
- 敏感数据暴露
- API 密钥泄露

**诊断**：
```bash
# 检查代码中的密钥
grep -r "SUPABASE_SERVICE_ROLE_KEY" .

# 检查 Git 历史
git log -p | grep -i "password\|secret\|key"

# 扫描 GitHub
# 使用 GitHub Secret Scanning
```

**解决方案**：
1. 立即轮换泄露的密钥
2. 从代码中移除敏感信息
3. 使用环境变量
4. 审查访问日志
5. 通知受影响用户

---

## 9. 监控告警

### 9.1 配置告警规则

```bash
#!/bin/bash
# /home/dacong/scripts/alert-rules.sh

# CPU 使用率告警
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    /usr/local/bin/telegram-alert.sh "⚠️ CPU 使用率: ${CPU_USAGE}%"
fi

# 内存使用率告警
MEM_USAGE=$(free | awk 'NR==2 {printf "%.0f", $3/$2 * 100}')
if [ $MEM_USAGE -gt 90 ]; then
    /usr/local/bin/telegram-alert.sh "⚠️ 内存使用率: ${MEM_USAGE}%"
fi

# 磁盘使用率告警
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    /usr/local/bin/telegram-alert.sh "⚠️ 磁盘使用率: ${DISK_USAGE}%"
fi

# API 可用性告警
if ! curl -sf https://api.dacong.com/health > /dev/null; then
    /usr/local/bin/telegram-alert.sh "❌ API 不可用"
fi

# 数据库连接告警
if ! psql $DATABASE_URL -c "SELECT 1;" > /dev/null 2>&1; then
    /usr/local/bin/telegram-alert.sh "❌ 数据库连接失败"
fi
```

### 9.2 定期健康检查

```bash
crontab -e

# 每 5 分钟执行健康检查
*/5 * * * * /home/dacong/scripts/alert-rules.sh
```

---

## 10. 故障排查检查清单

### 初步诊断
- [ ] 收集错误信息和日志
- [ ] 确定问题范围（全局/局部）
- [ ] 检查最近的变更
- [ ] 查看监控指标

### 数据库层
- [ ] 检查数据库连接
- [ ] 查看慢查询
- [ ] 检查连接池状态
- [ ] 验证数据完整性

### 应用层
- [ ] 检查服务状态
- [ ] 查看应用日志
- [ ] 验证配置文件
- [ ] 测试 API 端点

### 基础设施层
- [ ] 检查服务器资源（CPU、内存、磁盘）
- [ ] 验证网络连接
- [ ] 检查 DNS 解析
- [ ] 验证 SSL 证书

### 修复后验证
- [ ] 问题已解决
- [ ] 监控指标正常
- [ ] 用户反馈正常
- [ ] 记录问题和解决方案

---

## 常用命令速查

```bash
# 服务管理
sudo systemctl status dacong-spider
sudo systemctl restart dacong-spider
sudo journalctl -u dacong-spider -f

# 数据库
psql $DATABASE_URL
psql $DATABASE_URL -c "SELECT version();"

# 日志查看
sudo tail -f /var/log/dacong-spider.log
sudo journalctl -u dacong-spider -n 100

# 资源监控
top
htop
free -h
df -h

# 网络诊断
ping dacong.com
dig dacong.com
curl -I https://dacong.com

# 进程管理
ps aux | grep python
kill -9 <pid>
```

---

## 下一步

1. 完成部署检查清单：[DEPLOYMENT_CHECKLIST_PRODUCTION.md](./DEPLOYMENT_CHECKLIST_PRODUCTION.md)
2. 配置监控告警：[MONITORING_SETUP.md](./MONITORING_SETUP.md)
3. 配置备份策略：[BACKUP_RECOVERY.md](./BACKUP_RECOVERY.md)
