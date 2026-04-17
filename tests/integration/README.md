# 集成测试

本目录包含系统的端到端集成测试。

## 测试文件

### test_end_to_end.sh

完整的端到端集成测试，测试数据流：爬虫 → AI生成 → API → 前端

**运行方式**:
```bash
./tests/integration/test_end_to_end.sh
```

**测试阶段**:
1. 环境配置检查
2. 数据库连接测试
3. 爬虫数据采集测试
4. AI 内容生成测试
5. API 端点测试
6. 数据一致性验证
7. 前端构建测试

**输出**:
- 控制台输出测试进度
- 生成测试报告: `tests/integration/e2e_test_report.md`

## 测试报告

测试完成后会生成详细的 Markdown 报告，包括：
- 每个测试阶段的结果
- 测试摘要（通过/失败数量、成功率）
- 测试耗时
- 失败原因分析

## 前置条件

1. **环境配置**
   - 已配置 `dacong-api/.env`
   - 已配置 `dacong-spider/.env`
   - 已配置 `dacong-client/.env`

2. **依赖安装**
   - Python 3.11+
   - Deno
   - Flutter
   - Supabase CLI

3. **数据库**
   - Supabase 数据库已初始化
   - 所有 migrations 已运行

## 故障排查

### 测试失败

1. 查看详细日志
   ```bash
   ./tests/integration/test_end_to_end.sh 2>&1 | tee test.log
   ```

2. 查看生成的报告
   ```bash
   cat tests/integration/e2e_test_report.md
   ```

3. 单独运行失败的阶段
   ```bash
   # 例如：单独测试 API
   cd dacong-api
   ./scripts/test-api.sh
   ```

### 常见问题

**Q: 数据库连接失败**
A: 检查 `.env` 文件中的 `SUPABASE_URL` 和 `SUPABASE_SERVICE_ROLE_KEY`

**Q: 爬虫测试失败**
A: 确保爬虫配置正确，网络连接正常

**Q: API 测试超时**
A: 检查 Supabase Edge Functions 是否已部署

**Q: Flutter 测试失败**
A: 运行 `flutter pub get` 确保依赖已安装

## 持续集成

集成测试可以在 CI/CD 中自动运行：

**GitHub Actions**:
```yaml
- name: Run Integration Tests
  run: ./tests/integration/test_end_to_end.sh
```

**GitLab CI**:
```yaml
integration_test:
  script:
    - ./tests/integration/test_end_to_end.sh
```

## 最佳实践

1. **定期运行**: 每次重大更改后运行完整测试
2. **监控报告**: 关注测试成功率和耗时趋势
3. **快速反馈**: 测试失败时立即修复
4. **保持更新**: 随着功能增加更新测试用例
