# CI/CD 测试快速参考

## 快速开始

### 本地运行测试

```bash
# 客户端
cd dacong-client && flutter test --coverage

# 管理后台
cd dacong-admin && flutter test --coverage

# 后端 API
cd dacong-api/supabase/functions && deno test --allow-all --coverage=coverage
```

### 查看覆盖率报告

```bash
# 生成 HTML 报告
genhtml coverage/lcov.info -o coverage/html

# 打开报告
open coverage/html/index.html  # macOS
start coverage/html/index.html # Windows
```

## 覆盖率目标

| 模块 | 目标 | 当前 | 状态 |
|------|------|------|------|
| 客户端 | 80% | 38.57% | 🔴 |
| 管理后台 | 70% | - | 🔴 |
| 后端 API | 85% | - | 🔴 |

## CI/CD 触发

### GitLab CI
- ✅ Merge Request 创建/更新
- ✅ 推送到 main/develop
- ✅ 手动触发 Pipeline

### GitHub Actions
- ✅ Pull Request 创建/更新
- ✅ 推送到 main/develop
- ✅ 每天凌晨 2 点自动运行

## 查看结果

### GitLab
1. 项目 → CI/CD → Pipelines
2. 点击 Pipeline → 查看任务
3. 下载 artifacts 查看报告

### GitHub
1. 项目 → Actions
2. 点击 Workflow run
3. 查看 Step Summary
4. 访问 Codecov 查看详细分析

## 常见问题

### 测试失败
```bash
# 本地复现
flutter test --reporter expanded

# 查看详细错误
flutter test test/path/to/failing_test.dart
```

### 覆盖率不达标
```bash
# 查看未覆盖的代码
lcov --list coverage/lcov.info | grep -v "100.0%"

# 生成 HTML 报告查看详情
genhtml coverage/lcov.info -o coverage/html
```

### CI 构建失败
1. 查看 CI 日志
2. 本地复现问题
3. 修复后重新提交

## 相关文档

- [测试覆盖率报告](./TEST_COVERAGE_REPORT.md)
- [CI/CD 配置指南](./CI_CD_SETUP.md)
- [测试进度总结](./TEST_PROGRESS_SUMMARY.md)
- [CI/CD 完成报告](./CI_CD_COMPLETION_REPORT.md)

## 联系方式

遇到问题请查看详细文档或联系开发团队。
