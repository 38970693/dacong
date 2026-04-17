# 测试快速开始指南

## 快速运行测试

### 1. 运行所有测试（推荐）

```bash
./scripts/run_all_tests.sh
```

这会运行：
- 爬虫单元测试和集成测试
- API 单元测试和端点测试
- 客户端单元测试和 Widget 测试
- 生成完整的测试报告: `TEST_REPORT.md`

### 2. 运行端到端集成测试

```bash
./tests/integration/test_end_to_end.sh
```

测试完整数据流：爬虫 → AI生成 → API → 前端

生成报告: `tests/integration/e2e_test_report.md`

### 3. 运行性能测试

```bash
./tests/performance/test_api_performance.sh
```

测试 API 响应时间和并发能力。

生成报告: `tests/performance/performance_report.md`

### 4. 运行健康检查

```bash
./scripts/health_check.sh
```

检查系统健康状态（数据库、API、爬虫等）。

---

## 前置条件

### 1. 环境配置

确保以下配置文件存在并正确配置：

```bash
# API 配置
dacong-api/.env

# 爬虫配置
dacong-spider/.env

# 客户端配置
dacong-client/.env
```

### 2. 依赖安装

**爬虫模块**:
```bash
cd dacong-spider
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

**API 模块**:
```bash
cd dacong-api
# Deno 会自动下载依赖
```

**客户端模块**:
```bash
cd dacong-client
flutter pub get
```

### 3. 数据库初始化

```bash
cd dacong-api
./scripts/init-db.sh
```

---

## 测试文件结构

```
dacong/
├── tests/
│   ├── integration/
│   │   ├── test_end_to_end.sh          # 端到端集成测试 ⭐
│   │   ├── README.md                    # 集成测试说明
│   │   └── e2e_test_report.md          # 测试报告（自动生成）
│   └── performance/
│       ├── test_api_performance.sh      # API 性能测试 ⭐
│       ├── README.md                    # 性能测试说明
│       └── performance_report.md        # 性能报告（自动生成）
├── scripts/
│   ├── health_check.sh                  # 系统健康检查 ⭐
│   └── run_all_tests.sh                 # 运行所有测试 ⭐
├── docs/
│   └── TESTING.md                       # 完整测试文档 ⭐
└── TEST_REPORT.md                       # 测试摘要（自动生成）
```

⭐ = 可执行脚本

---

## 查看测试报告

### 测试摘要

```bash
cat TEST_REPORT.md
```

包含所有模块的测试统计和覆盖率。

### 集成测试报告

```bash
cat tests/integration/e2e_test_report.md
```

包含端到端测试的详细结果。

### 性能测试报告

```bash
cat tests/performance/performance_report.md
```

包含 API 响应时间和并发测试结果。

---

## 常见问题

### Q: 脚本没有执行权限

```bash
chmod +x tests/integration/test_end_to_end.sh
chmod +x tests/performance/test_api_performance.sh
chmod +x scripts/health_check.sh
chmod +x scripts/run_all_tests.sh
```

### Q: 测试失败怎么办？

1. 查看详细日志
2. 检查配置文件
3. 确保依赖已安装
4. 查看生成的测试报告

### Q: 如何在 CI/CD 中运行？

**GitHub Actions**:
```yaml
- name: Run All Tests
  run: ./scripts/run_all_tests.sh

- name: Health Check
  run: ./scripts/health_check.sh
```

**GitLab CI**:
```yaml
test:
  script:
    - ./scripts/run_all_tests.sh
    - ./scripts/health_check.sh
```

---

## 下一步

1. 阅读完整的测试文档: `docs/TESTING.md`
2. 查看各模块的测试说明
3. 集成到 CI/CD 流程
4. 设置定期健康检查

---

*快速开始指南 - 2026-04-17*
