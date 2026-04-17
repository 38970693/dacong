# Week 3 Day 5-7 快速启动指南

## 🚀 快速开始

### 1. 安装依赖

```bash
# 进入管理后台目录
cd dacong-admin

# 安装 Flutter 依赖
flutter pub get

# 验证安装
flutter doctor
```

### 2. 配置环境变量

创建 `.env` 文件：

```bash
# Supabase 配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 3. 部署数据库索引

```bash
cd ../dacong-api

# 运行性能优化迁移
supabase db push

# 验证索引创建
supabase db remote commit
```

### 4. 部署 Edge Functions

```bash
# 部署实时统计 API
supabase functions deploy get-realtime-stats

# 部署趋势数据 API
supabase functions deploy get-trend-data

# 验证部署
supabase functions list
```

### 5. 运行测试

```bash
cd ../dacong-admin

# 运行所有测试
flutter test

# 生成覆盖率报告
flutter test --coverage
```

### 6. 启动应用

```bash
# Web 开发模式
flutter run -d chrome

# 或构建生产版本
flutter build web --release
```

## 📊 功能演示

### 访问数据看板

启动应用后，导航到数据看板页面：

1. **实时概览**：查看今日 DAU、PV、UV、新增用户
2. **趋势分析**：切换 7天/30天 查看趋势图表
3. **内容统计**：查看饼图展示的内容分布
4. **用户统计**：查看柱状图展示的用户概览
5. **热门内容**：查看 Top 10 热门内容列表
6. **搜索热词**：查看 Top 10 搜索关键词

### 测试数据导出

```dart
// 在代码中使用 ExportService
final exportService = ExportService();

// 导出用户数据
final csvPath = await exportService.exportUsersToCsv();

// 导出内容数据
final contentPath = await exportService.exportContentToCsv();

// 导出分析报告
final report = await exportService.generateAnalyticsJson(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);
```

### 测试通知系统

```dart
// 初始化通知服务
final notificationService = NotificationService();
await notificationService.initialize();

// 监听通知
notificationService.notificationStream.listen((notification) {
  print('New notification: ${notification.title}');
});

// 创建测试通知
await notificationService.createNotification(
  type: NotificationType.contentPendingReview,
  title: '新内容待审核',
  message: '有 3 条新内容等待审核',
  data: {'count': 3},
);
```

## 🔧 常见问题

### Q1: 图表不显示数据？

**A**: 检查以下几点：
1. Supabase 连接是否正常
2. Edge Functions 是否部署成功
3. 数据库中是否有数据
4. 浏览器控制台是否有错误

### Q2: API 响应慢？

**A**: 优化建议：
1. 检查数据库索引是否创建成功
2. 验证缓存是否生效
3. 检查网络连接
4. 查看 Supabase 日志

### Q3: 测试失败？

**A**: 排查步骤：
1. 运行 `flutter clean`
2. 重新安装依赖 `flutter pub get`
3. 检查 Flutter SDK 版本
4. 查看具体错误信息

### Q4: 通知不推送？

**A**: 检查清单：
1. Supabase Realtime 是否启用
2. 数据库表是否有 Realtime 权限
3. 浏览器通知权限是否授予
4. 网络连接是否稳定

## 📈 性能监控

### 查看 API 性能

```bash
# 使用 curl 测试响应时间
curl -w "@curl-format.txt" -o /dev/null -s \
  "https://your-project.supabase.co/functions/v1/get-realtime-stats" \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

### 查看数据库性能

```sql
-- 查看慢查询
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 10;

-- 查看索引使用情况
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### 查看前端性能

在浏览器开发者工具中：
1. Performance 标签：查看渲染性能
2. Network 标签：查看网络请求
3. Memory 标签：查看内存使用
4. Lighthouse：运行性能审计

## 🎯 下一步

### 立即可用
- ✅ 数据看板
- ✅ 图表展示
- ✅ 数据导出
- ✅ 通知系统

### 待完善（可选）
- [ ] Web Notification API 完整实现
- [ ] Excel 导出功能
- [ ] PDF 报告生成
- [ ] 自定义仪表盘

## 📚 相关文档

- [实现总结](./WEEK3_DAY5-7_IMPLEMENTATION.md)
- [部署清单](./docs/WEEK3_DEPLOYMENT_CHECKLIST.md)
- [交付报告](./WEEK3_DAY5-7_DELIVERY.md)

## 💡 提示

### 开发模式
```bash
# 启用热重载
flutter run -d chrome --web-renderer html

# 查看详细日志
flutter run -d chrome -v
```

### 生产构建
```bash
# Web 构建
flutter build web --release --web-renderer canvaskit

# 检查构建大小
du -sh build/web
```

### 调试技巧
```bash
# 分析代码
flutter analyze

# 格式化代码
flutter format .

# 运行特定测试
flutter test test/widgets/charts/line_chart_test.dart
```

## 🎉 开始使用

现在你已经准备好使用 Week 3 Day 5-7 的所有新功能了！

如有问题，请参考详细文档或联系开发团队。

---

**祝开发愉快！** 🚀
