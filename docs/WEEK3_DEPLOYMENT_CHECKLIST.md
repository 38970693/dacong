# Week 3 部署清单

## 数据库 Migrations 检查

### 1. 运行所有迁移
```bash
cd dacong-api
supabase db push
```

### 2. 验证索引创建
```sql
-- 检查索引是否创建成功
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

### 3. 验证表结构
```sql
-- 检查所有表
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- 检查关键表的列
\d users
\d contents
\d comments
\d analytics_daily
\d admin_notifications
```

### 4. 数据完整性检查
```sql
-- 检查是否有孤立数据
SELECT COUNT(*) FROM comments WHERE content_id NOT IN (SELECT id FROM contents);
SELECT COUNT(*) FROM likes WHERE content_id NOT IN (SELECT id FROM contents);
SELECT COUNT(*) FROM favorites WHERE content_id NOT IN (SELECT id FROM contents);
```

## API 部署检查

### 1. Edge Functions 部署
```bash
cd dacong-api

# 部署实时统计 API
supabase functions deploy get-realtime-stats

# 部署趋势数据 API
supabase functions deploy get-trend-data

# 验证部署
supabase functions list
```

### 2. API 测试
```bash
# 测试实时统计
curl -X GET "https://your-project.supabase.co/functions/v1/get-realtime-stats" \
  -H "Authorization: Bearer YOUR_ANON_KEY"

# 测试趋势数据
curl -X GET "https://your-project.supabase.co/functions/v1/get-trend-data?days=7" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

### 3. 性能测试
```bash
# 使用 Apache Bench 测试并发
ab -n 100 -c 10 "https://your-project.supabase.co/functions/v1/get-realtime-stats"

# 检查响应时间
curl -w "@curl-format.txt" -o /dev/null -s "https://your-project.supabase.co/functions/v1/get-realtime-stats"
```

## 前端构建检查

### 1. Flutter Admin 构建
```bash
cd dacong-admin

# 安装依赖
flutter pub get

# 运行代码分析
flutter analyze

# 运行测试
flutter test

# Web 构建
flutter build web --release

# 检查构建产物大小
du -sh build/web
```

### 2. Flutter Client 构建
```bash
cd dacong-client

# 安装依赖
flutter pub get

# 运行代码分析
flutter analyze

# 运行测试
flutter test

# Android 构建
flutter build apk --release

# iOS 构建（需要 macOS）
flutter build ios --release
```

### 3. 构建优化验证
- [ ] 检查 bundle 大小（Web < 5MB）
- [ ] 检查 APK 大小（< 20MB）
- [ ] 验证代码分割是否生效
- [ ] 检查图片是否压缩
- [ ] 验证字体文件是否优化

## 环境变量配置

### 1. Supabase 环境变量
```bash
# .env.production
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 2. Flutter 环境配置
```dart
// lib/config/env.dart
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );
}
```

### 3. 验证环境变量
- [ ] 生产环境 URL 正确
- [ ] API Keys 有效
- [ ] 权限配置正确
- [ ] CORS 设置正确

## 测试验证

### 1. 单元测试
```bash
# 运行所有单元测试
flutter test

# 运行特定测试
flutter test test/services/dashboard_service_test.dart

# 生成覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 2. 集成测试
```bash
# 运行集成测试
flutter test integration_test/

# 在真机上运行
flutter drive --target=integration_test/app_test.dart
```

### 3. 覆盖率验证
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] 关键服务覆盖率 ≥ 90%
- [ ] 所有 API 调用有测试
- [ ] 所有组件有测试

## 性能验证

### 1. 数据库性能
```sql
-- 检查慢查询
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 10;

-- 检查索引使用率
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY schemaname, tablename;

-- 检查表膨胀
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 2. API 性能
- [ ] 实时统计 API 响应时间 < 200ms
- [ ] 趋势数据 API 响应时间 < 500ms
- [ ] 缓存命中率 > 80%
- [ ] 并发支持 100+ 请求/秒

### 3. 前端性能
- [ ] 首屏加载时间 < 1.5s
- [ ] 图表渲染流畅（60fps）
- [ ] 虚拟滚动正常工作
- [ ] 图片懒加载生效
- [ ] 内存使用稳定

## 安全检查

### 1. 数据库安全
```sql
-- 检查 RLS 策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public';

-- 验证权限设置
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'public';
```

### 2. API 安全
- [ ] 所有 API 需要认证
- [ ] JWT 验证正确
- [ ] 速率限制配置
- [ ] CORS 白名单设置
- [ ] SQL 注入防护
- [ ] XSS 防护

### 3. 前端安全
- [ ] 敏感数据加密
- [ ] 本地存储安全
- [ ] API Key 不暴露
- [ ] 输入验证完整
- [ ] 错误信息不泄露

## 监控配置

### 1. Supabase 监控
- [ ] 启用数据库监控
- [ ] 配置告警规则
- [ ] 设置日志保留期
- [ ] 配置备份策略

### 2. 应用监控
- [ ] 集成错误追踪（Sentry）
- [ ] 配置性能监控
- [ ] 设置用户行为分析
- [ ] 配置日志收集

### 3. 告警设置
- [ ] 数据库连接数告警
- [ ] API 错误率告警
- [ ] 响应时间告警
- [ ] 磁盘空间告警

## 文档更新

### 1. API 文档
- [ ] 更新 OpenAPI 规范
- [ ] 添加新接口文档
- [ ] 更新示例代码
- [ ] 添加错误码说明

### 2. 部署文档
- [ ] 更新部署步骤
- [ ] 添加环境配置说明
- [ ] 更新故障排查指南
- [ ] 添加回滚步骤

### 3. 用户文档
- [ ] 更新功能说明
- [ ] 添加使用教程
- [ ] 更新 FAQ
- [ ] 添加截图和视频

## 发布流程

### 1. 预发布检查
- [ ] 所有测试通过
- [ ] 代码审查完成
- [ ] 性能测试通过
- [ ] 安全扫描通过
- [ ] 文档更新完成

### 2. 发布步骤
```bash
# 1. 创建发布分支
git checkout -b release/week3
git push origin release/week3

# 2. 部署数据库
cd dacong-api
supabase db push

# 3. 部署 API
supabase functions deploy get-realtime-stats
supabase functions deploy get-trend-data

# 4. 构建前端
cd ../dacong-admin
flutter build web --release

cd ../dacong-client
flutter build apk --release

# 5. 部署前端
# 根据实际部署方式进行

# 6. 验证部署
# 运行冒烟测试

# 7. 合并到主分支
git checkout main
git merge release/week3
git tag v1.3.0
git push origin main --tags
```

### 3. 发布后验证
- [ ] 生产环境访问正常
- [ ] 关键功能可用
- [ ] 数据统计正确
- [ ] 通知系统工作
- [ ] 导出功能正常

## 回滚计划

### 1. 数据库回滚
```bash
# 回滚到上一个版本
supabase db reset --version previous
```

### 2. API 回滚
```bash
# 重新部署旧版本
git checkout v1.2.0
supabase functions deploy get-realtime-stats
supabase functions deploy get-trend-data
```

### 3. 前端回滚
```bash
# 重新部署旧版本
git checkout v1.2.0
flutter build web --release
# 部署到服务器
```

## 验收标准

- [x] 图表组件正常工作
- [x] 数据看板完整展示
- [x] 实时统计正常
- [x] 数据导出功能正常
- [x] 性能优化完成
- [x] 通知系统正常
- [ ] 测试通过（覆盖率 80%+）
- [ ] 部署成功
- [ ] 生产环境验证通过

## 联系人

- **开发负责人**: [姓名]
- **运维负责人**: [姓名]
- **测试负责人**: [姓名]
- **产品负责人**: [姓名]

## 紧急联系方式

- **技术支持**: [电话/邮箱]
- **运维值班**: [电话/邮箱]
- **产品经理**: [电话/邮箱]
