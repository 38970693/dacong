# 测试文档

本文档描述 DaCong 项目的测试策略、测试方法和测试覆盖率。

---

## 目录

1. [测试策略](#测试策略)
2. [测试类型](#测试类型)
3. [如何运行测试](#如何运行测试)
4. [测试覆盖率](#测试覆盖率)
5. [持续集成](#持续集成)
6. [测试最佳实践](#测试最佳实践)

---

## 测试策略

### 测试金字塔

我们遵循测试金字塔原则，确保测试的全面性和效率：

```
        /\
       /  \      E2E 测试 (10%)
      /____\     - 端到端集成测试
     /      \    - 关键用户流程
    /________\   
   /          \  集成测试 (30%)
  /____________\ - API 端点测试
 /              \- 模块间集成
/________________\
                  单元测试 (60%)
                  - 函数级测试
                  - 组件测试
```

### 测试目标

- **覆盖率目标**: ≥ 80%
- **关键路径覆盖**: 100%
- **性能基准**: API 响应时间 < 1秒
- **并发能力**: 支持 100+ 并发请求

---

## 测试类型

### 1. 单元测试

测试单个函数、类或组件的功能。

**爬虫模块** (`dacong-spider/tests/`)
```bash
# 运行所有单元测试
pytest tests/ -v

# 运行特定测试
pytest tests/test_spiders.py -v

# 查看覆盖率
pytest --cov=. --cov-report=html
```

**API 模块** (`dacong-api/supabase/functions/tests/`)
```bash
# 运行所有测试
./scripts/run-tests.sh

# 运行特定测试
deno test --allow-all supabase/functions/tests/Content.test.ts
```

**客户端模块** (`dacong-client/test/`)
```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/presentation/home_screen_test.dart

# 生成覆盖率
flutter test --coverage
```

### 2. 集成测试

测试模块间的交互和数据流。

**API 端点测试**
```bash
cd dacong-api
./scripts/test-api.sh
```

**数据流测试**
```bash
# 测试：爬虫 → 数据库 → API
./tests/integration/test_end_to_end.sh
```

### 3. 端到端测试

测试完整的用户场景。

```bash
# 运行完整的 E2E 测试
./tests/integration/test_end_to_end.sh
```

测试场景：
1. 爬虫采集数据
2. AI 生成内容
3. API 返回数据
4. 前端展示内容
5. 用户提交反馈

### 4. 性能测试

测试系统的性能和并发能力。

```bash
# 运行性能测试
./tests/performance/test_api_performance.sh
```

测试内容：
- 单请求响应时间
- 并发能力（10, 50, 100 并发）
- 压力测试
- 缓存效果

---

## 如何运行测试

### 快速开始

```bash
# 运行所有测试（推荐）
./scripts/run_all_tests.sh
```

这会自动运行：
- 爬虫单元测试和集成测试
- API 单元测试和端点测试
- 客户端单元测试和 Widget 测试
- 生成完整的测试报告

### 分模块测试

**1. 爬虫模块**
```bash
cd dacong-spider

# 运行测试
pytest tests/ -v --cov=. --cov-report=html

# 查看覆盖率报告
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

**2. API 模块**
```bash
cd dacong-api

# 运行单元测试
./scripts/run-tests.sh

# 运行 API 端点测试
./scripts/test-api.sh
```

**3. 客户端模块**
```bash
cd dacong-client

# 运行测试
flutter test --coverage

# 生成 HTML 报告
genhtml coverage/lcov.info -o coverage/html

# 查看报告
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### 健康检查

```bash
# 运行系统健康检查
./scripts/health_check.sh
```

检查内容：
- 环境配置
- 数据库连接
- API 端点状态
- 爬虫状态
- 数据完整性
- 磁盘空间

---

## 测试覆盖率

### 当前覆盖率

| 模块 | 覆盖率 | 目标 | 状态 |
|------|-------|------|------|
| 爬虫 (dacong-spider) | ~85% | ≥80% | ✅ |
| API (dacong-api) | ~90% | ≥80% | ✅ |
| 客户端 (dacong-client) | ~75% | ≥80% | ⚠️ |

### 查看覆盖率报告

**爬虫模块**
```bash
cd dacong-spider
pytest --cov=. --cov-report=html
open htmlcov/index.html
```

**API 模块**
```bash
cd dacong-api
./scripts/run-tests.sh
# 覆盖率信息会在测试输出中显示
```

**客户端模块**
```bash
cd dacong-client
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 提高覆盖率

1. **识别未覆盖的代码**
   - 查看覆盖率报告中的红色部分
   - 优先覆盖关键业务逻辑

2. **编写测试用例**
   - 正常场景
   - 边界条件
   - 错误处理

3. **重构代码**
   - 提取可测试的函数
   - 减少依赖
   - 使用依赖注入

---

## 持续集成

### GitHub Actions

项目配置了 GitHub Actions 自动运行测试。

**工作流文件**: `.github/workflows/test.yml`

触发条件：
- Push 到 `main` 或 `dev` 分支
- 创建 Pull Request
- 手动触发

测试流程：
1. 检出代码
2. 设置环境（Python, Deno, Flutter）
3. 安装依赖
4. 运行单元测试
5. 运行集成测试
6. 生成覆盖率报告
7. 上传测试结果

### GitLab CI

**配置文件**: `.gitlab-ci.yml`

Pipeline 阶段：
1. **test**: 运行所有测试
2. **coverage**: 生成覆盖率报告
3. **deploy**: 部署（仅 main 分支）

```yaml
stages:
  - test
  - coverage
  - deploy

test:spider:
  stage: test
  script:
    - cd dacong-spider
    - pytest tests/ -v --cov=.

test:api:
  stage: test
  script:
    - cd dacong-api
    - ./scripts/run-tests.sh

test:client:
  stage: test
  script:
    - cd dacong-client
    - flutter test --coverage
```

---

## 测试最佳实践

### 1. 编写可测试的代码

**使用依赖注入**
```python
# 不好：硬编码依赖
class Spider:
    def __init__(self):
        self.fetcher = HttpFetcher()  # 难以测试

# 好：依赖注入
class Spider:
    def __init__(self, fetcher: IFetcher):
        self.fetcher = fetcher  # 可以注入 Mock
```

**保持函数纯粹**
```python
# 不好：有副作用
def process_data(data):
    save_to_db(data)  # 副作用
    return transform(data)

# 好：纯函数
def process_data(data):
    return transform(data)  # 无副作用，易测试
```

### 2. 测试命名规范

```python
# 格式：test_<功能>_<场景>_<预期结果>

def test_fetch_github_trending_success():
    """测试成功获取 GitHub Trending"""
    pass

def test_fetch_github_trending_with_invalid_token_raises_error():
    """测试无效 Token 时抛出错误"""
    pass
```

### 3. 使用 Mock 和 Stub

```python
from unittest.mock import Mock, patch

def test_spider_with_mock_fetcher():
    # 创建 Mock
    mock_fetcher = Mock()
    mock_fetcher.fetch_json.return_value = {"data": "test"}

    # 使用 Mock
    spider = GitHubSpider(mock_fetcher)
    result = await spider.fetch()

    # 验证调用
    mock_fetcher.fetch_json.assert_called_once()
```

### 4. 测试边界条件

```python
def test_get_recommendations_with_zero_limit():
    """测试 limit=0 的边界情况"""
    pass

def test_get_recommendations_with_negative_limit():
    """测试 limit<0 的边界情况"""
    pass

def test_get_recommendations_with_large_limit():
    """测试 limit>1000 的边界情况"""
    pass
```

### 5. 测试错误处理

```python
def test_fetch_with_network_error():
    """测试网络错误时的处理"""
    pass

def test_fetch_with_timeout():
    """测试超时时的处理"""
    pass

def test_fetch_with_invalid_response():
    """测试无效响应时的处理"""
    pass
```

### 6. 保持测试独立

```python
# 不好：测试间有依赖
def test_create_user():
    user = create_user("test")
    assert user.id == 1

def test_get_user():
    user = get_user(1)  # 依赖上一个测试
    assert user.name == "test"

# 好：每个测试独立
def test_create_user():
    user = create_user("test")
    assert user.name == "test"

def test_get_user():
    user = create_user("test")  # 自己创建数据
    fetched = get_user(user.id)
    assert fetched.name == "test"
```

### 7. 使用测试夹具 (Fixtures)

```python
import pytest

@pytest.fixture
def sample_data():
    """提供测试数据"""
    return {
        "id": "test-id",
        "title": "Test Title",
        "content": "Test Content"
    }

def test_process_data(sample_data):
    result = process(sample_data)
    assert result["id"] == "test-id"
```

---

## 测试工具

### 爬虫模块
- **pytest**: 测试框架
- **pytest-cov**: 覆盖率
- **pytest-asyncio**: 异步测试
- **unittest.mock**: Mock 工具

### API 模块
- **Deno Test**: 内置测试框架
- **Supamock**: Supabase Mock

### 客户端模块
- **flutter_test**: Flutter 测试框架
- **mockito**: Mock 工具
- **integration_test**: 集成测试

### 性能测试
- **curl**: 单请求测试
- **Apache Bench (ab)**: 并发测试
- **wrk**: 压力测试

---

## 故障排查

### 测试失败

1. **查看详细日志**
   ```bash
   pytest tests/ -v -s  # -s 显示 print 输出
   ```

2. **运行单个测试**
   ```bash
   pytest tests/test_spiders.py::test_github_spider -v
   ```

3. **使用调试器**
   ```bash
   pytest tests/ --pdb  # 失败时进入调试器
   ```

### 覆盖率不准确

1. **清理缓存**
   ```bash
   rm -rf .pytest_cache __pycache__ .coverage
   ```

2. **重新运行**
   ```bash
   pytest --cov=. --cov-report=html --cov-report=term
   ```

### CI/CD 失败

1. **本地复现**
   ```bash
   # 使用相同的命令
   ./scripts/run_all_tests.sh
   ```

2. **检查环境变量**
   ```bash
   # 确保 CI 环境变量已配置
   echo $SUPABASE_URL
   echo $SUPABASE_SERVICE_ROLE_KEY
   ```

---

## 参考资源

- [pytest 文档](https://docs.pytest.org/)
- [Deno Testing](https://deno.land/manual/testing)
- [Flutter Testing](https://flutter.dev/docs/testing)
- [测试金字塔](https://martinfowler.com/articles/practical-test-pyramid.html)

---

*最后更新: 2026-04-17*
