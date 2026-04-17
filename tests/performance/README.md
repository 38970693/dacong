# 性能测试

本目录包含系统的性能测试脚本和报告。

## 测试文件

### test_api_performance.sh

API 性能测试脚本，测试响应时间和并发能力。

**运行方式**:
```bash
./tests/performance/test_api_performance.sh
```

**测试内容**:
1. 单请求响应时间测试
2. 并发测试（10, 50, 100 并发）
3. 压力测试（使用 wrk）
4. 缓存效果测试

**输出**:
- 控制台输出测试进度
- 生成性能报告: `tests/performance/performance_report.md`

## 性能指标

### 响应时间

| API 端点 | 目标 | 当前 |
|---------|------|------|
| get-recommendations | < 1s | ~0.15s |
| search-content | < 1s | ~0.20s |
| get-content-detail | < 0.5s | ~0.10s |
| get-weekly-report | < 1s | ~0.25s |

### 并发能力

| 并发数 | 目标成功率 | 目标吞吐量 |
|-------|-----------|-----------|
| 10 | > 99% | > 50 req/s |
| 50 | > 95% | > 200 req/s |
| 100 | > 90% | > 300 req/s |

### 缓存效果

- **冷缓存**: 首次请求，需要查询数据库
- **热缓存**: 5分钟内的重复请求，直接返回缓存
- **目标提升**: > 80%

## 测试工具

### 1. curl

用于单请求测试，测量响应时间。

```bash
curl -w "%{time_total}\n" -o /dev/null -s \
  -H "Authorization: Bearer $API_KEY" \
  "$API_URL"
```

### 2. Apache Bench (ab)

用于并发测试。

**安装**:
```bash
# Ubuntu/Debian
sudo apt-get install apache2-utils

# macOS
brew install httpd
```

**使用**:
```bash
ab -n 1000 -c 100 -H "Authorization: Bearer $API_KEY" "$API_URL"
```

参数说明:
- `-n`: 总请求数
- `-c`: 并发数
- `-H`: 自定义请求头

### 3. wrk

用于压力测试，支持 Lua 脚本。

**安装**:
```bash
# Ubuntu/Debian
sudo apt-get install wrk

# macOS
brew install wrk
```

**使用**:
```bash
wrk -t10 -c100 -d30s -H "Authorization: Bearer $API_KEY" "$API_URL"
```

参数说明:
- `-t`: 线程数
- `-c`: 连接数
- `-d`: 测试持续时间

## 性能优化建议

### 1. 数据库优化

- **索引**: 在常用查询字段上建立索引
  ```sql
  CREATE INDEX idx_scenario ON published_content(scenario);
  CREATE INDEX idx_published_at ON published_content(published_at);
  ```

- **查询优化**: 避免 N+1 查询，使用 JOIN
  ```typescript
  // 不好：N+1 查询
  for (const content of contents) {
    const feedback = await getFeedback(content.id);
  }

  // 好：一次查询
  const contents = await getContentsWithFeedback();
  ```

### 2. 缓存策略

- **内存缓存**: 5分钟 TTL，适合热点数据
- **Redis 缓存**: 跨进程共享，适合分布式部署
- **CDN 缓存**: 静态资源和不常变化的 API

### 3. API 优化

- **分页**: 限制单次返回数据量
- **字段选择**: 只返回需要的字段
- **压缩**: 启用 gzip 压缩

### 4. 并发控制

- **连接池**: 复用数据库连接
- **限流**: 防止过载
- **熔断**: 快速失败，保护系统

## 性能监控

### 实时监控

使用 Supabase Dashboard 监控：
- API 请求量
- 响应时间
- 错误率
- 数据库查询性能

### 告警设置

建议设置以下告警：
- 响应时间 > 2秒
- 错误率 > 5%
- 数据库连接数 > 80%
- CPU 使用率 > 80%

## 性能测试最佳实践

### 1. 测试环境

- 使用生产级别的硬件配置
- 模拟真实的网络延迟
- 使用真实的数据量

### 2. 测试数据

- 准备足够的测试数据（> 10000 条）
- 数据分布符合生产环境
- 包含各种边界情况

### 3. 测试场景

- 正常负载测试
- 峰值负载测试
- 压力测试（超过预期负载）
- 持久性测试（长时间运行）

### 4. 结果分析

- 关注平均值、中位数、P95、P99
- 识别性能瓶颈
- 对比历史数据，发现趋势

## 故障排查

### 响应时间慢

1. **检查数据库查询**
   ```sql
   -- 查看慢查询
   SELECT * FROM pg_stat_statements 
   ORDER BY mean_exec_time DESC 
   LIMIT 10;
   ```

2. **检查缓存命中率**
   - 查看缓存日志
   - 调整缓存策略

3. **检查网络延迟**
   ```bash
   ping your-api-domain.com
   traceroute your-api-domain.com
   ```

### 并发能力不足

1. **增加连接池大小**
2. **优化数据库查询**
3. **使用 CDN 分流**
4. **水平扩展（增加实例）**

### 内存泄漏

1. **监控内存使用**
   ```bash
   # 查看进程内存
   ps aux | grep deno
   ```

2. **检查缓存清理**
   - 确保缓存有过期时间
   - 定期清理过期缓存

## 参考资源

- [Apache Bench 文档](https://httpd.apache.org/docs/2.4/programs/ab.html)
- [wrk 文档](https://github.com/wg/wrk)
- [性能测试最佳实践](https://www.nginx.com/blog/performance-testing-best-practices/)

---

*最后更新: 2026-04-17*
