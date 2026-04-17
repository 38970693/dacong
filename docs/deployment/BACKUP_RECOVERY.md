# 备份和恢复指南

## 概述

本文档说明如何配置自动备份、执行手动备份以及在灾难情况下恢复数据。

---

## 1. 备份策略

### 1.1 备份范围

| 数据类型 | 备份频率 | 保留期限 | 优先级 |
|---------|---------|---------|--------|
| PostgreSQL 数据库 | 每日 | 30 天 | 高 |
| 用户上传文件 | 实时 | 永久 | 高 |
| 应用配置 | 每次变更 | 永久 | 中 |
| 日志文件 | 每周 | 90 天 | 低 |
| 代码仓库 | 实时 | 永久 | 高 |

### 1.2 备份目标

**3-2-1 备份原则**：
- **3** 份数据副本
- **2** 种不同的存储介质
- **1** 份异地备份

**实施方案**：
1. 主数据：Supabase 生产环境
2. 备份 1：Supabase 自动备份（同区域）
3. 备份 2：本地 VPS 备份（每日）
4. 备份 3：云存储异地备份（每周）

---

## 2. 数据库备份

### 2.1 Supabase 自动备份

**Free Plan**：
- 每日自动备份
- 保留 7 天
- 可通过 Dashboard 恢复

**Pro Plan**：
- 每日自动备份
- 保留 30 天
- 支持时间点恢复（PITR）

**查看备份**：
1. 访问 Supabase Dashboard > Database > Backups
2. 查看备份列表和状态

**恢复备份**：
1. 选择要恢复的备份
2. 点击 "Restore"
3. 确认恢复操作
4. 等待恢复完成（约 5-10 分钟）

### 2.2 手动数据库备份

#### 完整备份

```bash
#!/bin/bash
# /home/dacong/scripts/backup-database.sh

# 配置
BACKUP_DIR="/home/dacong/backups/database"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="dacong_backup_${DATE}.sql"
RETENTION_DAYS=30

# 创建备份目录
mkdir -p $BACKUP_DIR

# 执行备份
echo "开始备份数据库..."
pg_dump $DATABASE_URL > "${BACKUP_DIR}/${BACKUP_FILE}"

# 压缩备份
echo "压缩备份文件..."
gzip "${BACKUP_DIR}/${BACKUP_FILE}"

# 删除旧备份
echo "清理旧备份..."
find $BACKUP_DIR -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

# 验证备份
if [ -f "${BACKUP_DIR}/${BACKUP_FILE}.gz" ]; then
    SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}.gz" | cut -f1)
    echo "✅ 备份成功: ${BACKUP_FILE}.gz (${SIZE})"
    
    # 发送通知
    /usr/local/bin/telegram-alert.sh "✅ 数据库备份成功: ${SIZE}"
else
    echo "❌ 备份失败"
    /usr/local/bin/telegram-alert.sh "❌ 数据库备份失败"
    exit 1
fi
```

#### 增量备份（使用 WAL）

```bash
#!/bin/bash
# /home/dacong/scripts/backup-wal.sh

# 配置
WAL_DIR="/home/dacong/backups/wal"
DATE=$(date +%Y%m%d)

# 创建目录
mkdir -p "${WAL_DIR}/${DATE}"

# 归档 WAL 文件
pg_receivewal -D "${WAL_DIR}/${DATE}" --slot=backup_slot $DATABASE_URL
```

#### 仅备份数据（不含结构）

```bash
pg_dump $DATABASE_URL --data-only > data_backup.sql
```

#### 仅备份结构（不含数据）

```bash
pg_dump $DATABASE_URL --schema-only > schema_backup.sql
```

#### 备份特定表

```bash
pg_dump $DATABASE_URL -t published_content -t user_feedback > tables_backup.sql
```

### 2.3 自动化备份

**配置 Cron 任务**：
```bash
crontab -e

# 每天凌晨 2 点执行完整备份
0 2 * * * /home/dacong/scripts/backup-database.sh

# 每小时执行增量备份
0 * * * * /home/dacong/scripts/backup-wal.sh
```

**配置 Systemd Timer**（推荐）：
```ini
# /etc/systemd/system/dacong-backup.service
[Unit]
Description=DaCong Database Backup
After=network.target

[Service]
Type=oneshot
User=dacong
ExecStart=/home/dacong/scripts/backup-database.sh
```

```ini
# /etc/systemd/system/dacong-backup.timer
[Unit]
Description=DaCong Database Backup Timer

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

启用 Timer：
```bash
sudo systemctl enable dacong-backup.timer
sudo systemctl start dacong-backup.timer

# 查看状态
sudo systemctl list-timers
```

---

## 3. 文件备份

### 3.1 Supabase Storage 备份

Supabase Storage 自动提供多副本存储，无需额外配置。

**手动备份到本地**：
```bash
#!/bin/bash
# /home/dacong/scripts/backup-storage.sh

BACKUP_DIR="/home/dacong/backups/storage"
DATE=$(date +%Y%m%d)

mkdir -p "${BACKUP_DIR}/${DATE}"

# 使用 Supabase CLI 下载所有文件
supabase storage download --bucket avatars --destination "${BACKUP_DIR}/${DATE}/avatars"
supabase storage download --bucket content-images --destination "${BACKUP_DIR}/${DATE}/content-images"

# 压缩
tar -czf "${BACKUP_DIR}/storage_${DATE}.tar.gz" -C "${BACKUP_DIR}" "${DATE}"
rm -rf "${BACKUP_DIR}/${DATE}"

echo "✅ Storage 备份完成"
```

### 3.2 代码仓库备份

**Git 自动备份**：
```bash
#!/bin/bash
# /home/dacong/scripts/backup-repo.sh

BACKUP_DIR="/home/dacong/backups/repo"
DATE=$(date +%Y%m%d)

# 克隆仓库
git clone --mirror https://gitlab.com/your-org/dacong.git "${BACKUP_DIR}/dacong_${DATE}.git"

# 压缩
tar -czf "${BACKUP_DIR}/dacong_${DATE}.tar.gz" -C "${BACKUP_DIR}" "dacong_${DATE}.git"
rm -rf "${BACKUP_DIR}/dacong_${DATE}.git"

echo "✅ 代码仓库备份完成"
```

### 3.3 配置文件备份

```bash
#!/bin/bash
# /home/dacong/scripts/backup-config.sh

BACKUP_DIR="/home/dacong/backups/config"
DATE=$(date +%Y%m%d)

mkdir -p "${BACKUP_DIR}/${DATE}"

# 备份配置文件
cp /home/dacong/dacong/dacong-spider/.env "${BACKUP_DIR}/${DATE}/"
cp /etc/systemd/system/dacong-*.service "${BACKUP_DIR}/${DATE}/"
cp /etc/nginx/sites-available/dacong "${BACKUP_DIR}/${DATE}/"

# 压缩
tar -czf "${BACKUP_DIR}/config_${DATE}.tar.gz" -C "${BACKUP_DIR}" "${DATE}"
rm -rf "${BACKUP_DIR}/${DATE}"

echo "✅ 配置文件备份完成"
```

---

## 4. 异地备份

### 4.1 上传到云存储

#### AWS S3

```bash
#!/bin/bash
# /home/dacong/scripts/upload-to-s3.sh

BACKUP_DIR="/home/dacong/backups"
S3_BUCKET="s3://dacong-backups"

# 安装 AWS CLI
# sudo apt install awscli

# 配置 AWS 凭证
# aws configure

# 上传备份
aws s3 sync $BACKUP_DIR $S3_BUCKET --storage-class GLACIER

echo "✅ 备份已上传到 S3"
```

#### 阿里云 OSS

```bash
#!/bin/bash
# /home/dacong/scripts/upload-to-oss.sh

BACKUP_DIR="/home/dacong/backups"
OSS_BUCKET="oss://dacong-backups"

# 安装 ossutil
# wget http://gosspublic.alicdn.com/ossutil/1.7.15/ossutil64
# chmod +x ossutil64
# ./ossutil64 config

# 上传备份
./ossutil64 cp -r $BACKUP_DIR $OSS_BUCKET

echo "✅ 备份已上传到 OSS"
```

#### Backblaze B2（成本最低）

```bash
#!/bin/bash
# /home/dacong/scripts/upload-to-b2.sh

BACKUP_DIR="/home/dacong/backups"
B2_BUCKET="dacong-backups"

# 安装 B2 CLI
# pip install b2

# 配置 B2
# b2 authorize-account <application-key-id> <application-key>

# 上传备份
b2 sync --replaceNewer $BACKUP_DIR b2://$B2_BUCKET

echo "✅ 备份已上传到 B2"
```

### 4.2 自动化异地备份

```bash
crontab -e

# 每周日凌晨 3 点上传到云存储
0 3 * * 0 /home/dacong/scripts/upload-to-s3.sh
```

---

## 5. 数据恢复

### 5.1 从 Supabase 备份恢复

**通过 Dashboard 恢复**：
1. Supabase Dashboard > Database > Backups
2. 选择备份点
3. 点击 "Restore"
4. 确认操作

**注意**：恢复会覆盖当前数据，建议先创建快照。

### 5.2 从本地备份恢复

#### 完整恢复

```bash
#!/bin/bash
# /home/dacong/scripts/restore-database.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "用法: $0 <backup-file.sql.gz>"
    exit 1
fi

# 解压备份
echo "解压备份文件..."
gunzip -c $BACKUP_FILE > /tmp/restore.sql

# 确认恢复
read -p "⚠️  这将覆盖当前数据库，确认继续？(yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "取消恢复"
    exit 0
fi

# 创建恢复前快照
echo "创建恢复前快照..."
pg_dump $DATABASE_URL > "/tmp/pre_restore_$(date +%Y%m%d_%H%M%S).sql"

# 恢复数据库
echo "开始恢复数据库..."
psql $DATABASE_URL < /tmp/restore.sql

# 验证恢复
echo "验证数据..."
psql $DATABASE_URL -c "SELECT count(*) FROM published_content;"

echo "✅ 恢复完成"
```

#### 恢复特定表

```bash
# 从备份中提取特定表
pg_restore -t published_content backup.sql | psql $DATABASE_URL

# 或使用 grep
grep "INSERT INTO published_content" backup.sql | psql $DATABASE_URL
```

#### 时间点恢复（PITR）

```bash
# 使用 WAL 文件恢复到特定时间点
pg_basebackup -D /tmp/restore -Fp -Xs -P
# 配置 recovery.conf
cat > /tmp/restore/recovery.conf <<EOF
restore_command = 'cp /home/dacong/backups/wal/%f %p'
recovery_target_time = '2024-04-17 10:00:00'
EOF
# 启动恢复
pg_ctl -D /tmp/restore start
```

### 5.3 从云存储恢复

```bash
#!/bin/bash
# /home/dacong/scripts/restore-from-s3.sh

BACKUP_DATE=$1
S3_BUCKET="s3://dacong-backups"
LOCAL_DIR="/tmp/restore"

if [ -z "$BACKUP_DATE" ]; then
    echo "用法: $0 <YYYYMMDD>"
    exit 1
fi

# 下载备份
mkdir -p $LOCAL_DIR
aws s3 cp "${S3_BUCKET}/database/dacong_backup_${BACKUP_DATE}.sql.gz" $LOCAL_DIR/

# 恢复
/home/dacong/scripts/restore-database.sh "${LOCAL_DIR}/dacong_backup_${BACKUP_DATE}.sql.gz"
```

---

## 6. 灾难恢复计划

### 6.1 灾难场景

| 场景 | 影响 | RTO | RPO | 恢复步骤 |
|------|------|-----|-----|---------|
| 数据库误删除 | 高 | 1 小时 | 1 天 | 从最近备份恢复 |
| 服务器宕机 | 高 | 2 小时 | 0 | 切换到备用服务器 |
| 数据中心故障 | 极高 | 4 小时 | 1 天 | 从异地备份恢复 |
| 勒索软件攻击 | 极高 | 8 小时 | 1 周 | 从离线备份恢复 |

**RTO (Recovery Time Objective)**：恢复时间目标
**RPO (Recovery Point Objective)**：恢复点目标

### 6.2 灾难恢复流程

#### 场景 1: 数据库误删除

```bash
# 1. 立即停止应用，防止进一步损坏
sudo systemctl stop dacong-spider

# 2. 创建当前状态快照
pg_dump $DATABASE_URL > /tmp/damaged_state.sql

# 3. 从最近备份恢复
/home/dacong/scripts/restore-database.sh /home/dacong/backups/database/latest.sql.gz

# 4. 验证数据完整性
psql $DATABASE_URL -c "SELECT count(*) FROM published_content;"

# 5. 重启应用
sudo systemctl start dacong-spider

# 6. 通知团队
/usr/local/bin/telegram-alert.sh "✅ 数据库已从备份恢复"
```

#### 场景 2: 服务器宕机

```bash
# 1. 准备新服务器
# 2. 安装必要软件
sudo apt update && sudo apt install -y postgresql-client python3 python3-venv

# 3. 从云存储下载最新备份
aws s3 sync s3://dacong-backups /tmp/restore

# 4. 恢复数据库
gunzip -c /tmp/restore/database/latest.sql.gz | psql $NEW_DATABASE_URL

# 5. 恢复配置文件
tar -xzf /tmp/restore/config/latest.tar.gz -C /etc/

# 6. 部署应用代码
git clone https://gitlab.com/your-org/dacong.git
cd dacong/dacong-spider
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 7. 启动服务
sudo systemctl start dacong-spider

# 8. 更新 DNS 指向新服务器
# 在 Cloudflare Dashboard 更新 A 记录
```

#### 场景 3: 数据中心故障

```bash
# 1. 激活灾难恢复计划
# 2. 在新区域创建 Supabase 项目
# 3. 从异地备份恢复数据
# 4. 更新 DNS 指向新区域
# 5. 通知用户服务恢复
```

### 6.3 恢复演练

**每季度执行一次恢复演练**：

```bash
#!/bin/bash
# /home/dacong/scripts/disaster-recovery-drill.sh

echo "=== 灾难恢复演练 ==="
echo "开始时间: $(date)"

# 1. 创建测试数据库
echo "1. 创建测试数据库..."
createdb test_restore

# 2. 从最新备份恢复
echo "2. 从备份恢复..."
LATEST_BACKUP=$(ls -t /home/dacong/backups/database/*.sql.gz | head -1)
gunzip -c $LATEST_BACKUP | psql test_restore

# 3. 验证数据完整性
echo "3. 验证数据..."
CONTENT_COUNT=$(psql test_restore -t -c "SELECT count(*) FROM published_content;")
USER_COUNT=$(psql test_restore -t -c "SELECT count(*) FROM auth.users;")

echo "   - 内容数量: $CONTENT_COUNT"
echo "   - 用户数量: $USER_COUNT"

# 4. 清理测试数据库
echo "4. 清理测试环境..."
dropdb test_restore

echo "✅ 演练完成"
echo "结束时间: $(date)"
```

---

## 7. 备份验证

### 7.1 自动验证脚本

```bash
#!/bin/bash
# /home/dacong/scripts/verify-backup.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "用法: $0 <backup-file.sql.gz>"
    exit 1
fi

echo "验证备份: $BACKUP_FILE"

# 1. 检查文件完整性
echo "1. 检查文件完整性..."
if gunzip -t $BACKUP_FILE 2>/dev/null; then
    echo "   ✅ 文件完整"
else
    echo "   ❌ 文件损坏"
    exit 1
fi

# 2. 检查文件大小
echo "2. 检查文件大小..."
SIZE=$(stat -f%z $BACKUP_FILE 2>/dev/null || stat -c%s $BACKUP_FILE)
MIN_SIZE=1048576  # 1MB
if [ $SIZE -gt $MIN_SIZE ]; then
    echo "   ✅ 文件大小正常: $(numfmt --to=iec $SIZE)"
else
    echo "   ⚠️  文件过小: $(numfmt --to=iec $SIZE)"
fi

# 3. 检查备份内容
echo "3. 检查备份内容..."
if gunzip -c $BACKUP_FILE | head -100 | grep -q "PostgreSQL database dump"; then
    echo "   ✅ 备份格式正确"
else
    echo "   ❌ 备份格式错误"
    exit 1
fi

# 4. 测试恢复（可选）
read -p "是否执行恢复测试？(yes/no): " test_restore
if [ "$test_restore" = "yes" ]; then
    echo "4. 测试恢复..."
    createdb test_verify
    gunzip -c $BACKUP_FILE | psql test_verify > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ 恢复测试成功"
    else
        echo "   ❌ 恢复测试失败"
    fi
    dropdb test_verify
fi

echo "✅ 验证完成"
```

### 7.2 定期验证

```bash
crontab -e

# 每周一凌晨 4 点验证最新备份
0 4 * * 1 /home/dacong/scripts/verify-backup.sh $(ls -t /home/dacong/backups/database/*.sql.gz | head -1)
```

---

## 8. 备份监控

### 8.1 备份状态检查

```bash
#!/bin/bash
# /home/dacong/scripts/check-backup-status.sh

BACKUP_DIR="/home/dacong/backups/database"
MAX_AGE_HOURS=26  # 备份不应超过 26 小时

# 查找最新备份
LATEST_BACKUP=$(ls -t $BACKUP_DIR/*.sql.gz 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ 未找到备份文件"
    /usr/local/bin/telegram-alert.sh "❌ 未找到数据库备份"
    exit 1
fi

# 检查备份年龄
BACKUP_TIME=$(stat -f%m $LATEST_BACKUP 2>/dev/null || stat -c%Y $LATEST_BACKUP)
CURRENT_TIME=$(date +%s)
AGE_HOURS=$(( ($CURRENT_TIME - $BACKUP_TIME) / 3600 ))

if [ $AGE_HOURS -gt $MAX_AGE_HOURS ]; then
    echo "⚠️  备份过旧: ${AGE_HOURS} 小时"
    /usr/local/bin/telegram-alert.sh "⚠️ 数据库备份过旧: ${AGE_HOURS} 小时"
    exit 1
else
    echo "✅ 备份正常: ${AGE_HOURS} 小时前"
fi

# 检查备份大小
SIZE=$(stat -f%z $LATEST_BACKUP 2>/dev/null || stat -c%s $LATEST_BACKUP)
echo "备份大小: $(numfmt --to=iec $SIZE)"
```

### 8.2 备份告警

```bash
crontab -e

# 每天早上 9 点检查备份状态
0 9 * * * /home/dacong/scripts/check-backup-status.sh
```

---

## 9. 备份最佳实践

### 9.1 安全性

- [ ] 备份文件加密存储
- [ ] 限制备份文件访问权限
- [ ] 定期轮换加密密钥
- [ ] 异地备份使用不同的凭证

**加密备份**：
```bash
# 加密备份
gpg --symmetric --cipher-algo AES256 backup.sql.gz

# 解密备份
gpg --decrypt backup.sql.gz.gpg > backup.sql.gz
```

### 9.2 性能优化

- [ ] 在低峰时段执行备份
- [ ] 使用并行备份加速
- [ ] 增量备份减少数据传输
- [ ] 压缩备份节省空间

**并行备份**：
```bash
pg_dump $DATABASE_URL -Fd -j 4 -f backup_dir/
```

### 9.3 监控和告警

- [ ] 备份成功/失败通知
- [ ] 备份大小异常告警
- [ ] 备份年龄告警
- [ ] 存储空间告警

---

## 10. 备份检查清单

### 日常检查
- [ ] 自动备份任务正常运行
- [ ] 最新备份在 24 小时内
- [ ] 备份文件大小正常
- [ ] 备份文件完整性验证通过

### 周检查
- [ ] 执行恢复测试
- [ ] 验证异地备份
- [ ] 检查存储空间
- [ ] 清理过期备份

### 月检查
- [ ] 执行完整恢复演练
- [ ] 审查备份策略
- [ ] 更新灾难恢复文档
- [ ] 测试告警通知

### 季度检查
- [ ] 灾难恢复演练
- [ ] 备份策略审计
- [ ] 更新恢复流程
- [ ] 培训团队成员

---

## 常见问题

### 备份失败

**原因**：
- 磁盘空间不足
- 数据库连接失败
- 权限不足

**解决方案**：
```bash
# 检查磁盘空间
df -h

# 检查数据库连接
psql $DATABASE_URL -c "SELECT 1;"

# 检查文件权限
ls -la /home/dacong/backups/
```

### 恢复失败

**原因**：
- 备份文件损坏
- 版本不兼容
- 权限不足

**解决方案**：
```bash
# 验证备份文件
gunzip -t backup.sql.gz

# 检查 PostgreSQL 版本
psql $DATABASE_URL -c "SELECT version();"

# 使用 --no-owner --no-acl 选项
psql $DATABASE_URL --no-owner --no-acl < backup.sql
```

---

## 下一步

1. 完成部署检查清单：[DEPLOYMENT_CHECKLIST_PRODUCTION.md](./DEPLOYMENT_CHECKLIST_PRODUCTION.md)
2. 阅读故障排查指南：[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
