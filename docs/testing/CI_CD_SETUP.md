# CI/CD 自动化测试配置指南

## 概览

本项目已配置完整的 CI/CD 自动化测试流程，支持 GitLab CI 和 GitHub Actions 双平台。

## 覆盖率目标

| 模块 | 目标覆盖率 | 检查策略 |
|------|-----------|---------|
| 客户端 (dacong-client) | 80% | 低于目标时构建失败 |
| 管理后台 (dacong-admin) | 70% | 低于目标时构建失败 |
| 后端 API (dacong-api) | 85% | 低于目标时构建失败 |

## GitLab CI 配置

### 文件位置
`.gitlab-ci.yml`

### Pipeline 阶段

```
安全扫描 → 测试 → 构建 → 部署
```

### 测试任务

#### 1. 客户端测试 (test-client)

```yaml
test-client:
  stage: test
  image: cirrusci/flutter:3.24.0
  script:
    - cd dacong-client
    - flutter pub get
    - flutter test --coverage --reporter expanded
  coverage: '/测试覆盖率: (\d+\.\d+)%/'
  artifacts:
    paths:
      - dacong-client/coverage/
    expire_in: 30 days
```

**功能**：
- 运行所有客户端测试
- 生成覆盖率报告
- 自动提取覆盖率百分比
- 保存覆盖率报告 30 天

#### 2. 管理后台测试 (test-admin)

```yaml
test-admin:
  stage: test
  image: cirrusci/flutter:3.24.0
  script:
    - cd dacong-admin
    - flutter pub get
    - flutter test --coverage --reporter expanded
  coverage: '/测试覆盖率: (\d+\.\d+)%/'
```

#### 3. 后端 API 测试 (test-api)

```yaml
test-api:
  stage: test
  image: denoland/deno:alpine
  script:
    - cd dacong-api/supabase/functions
    - deno test --allow-all --coverage=coverage
    - deno coverage coverage --lcov > coverage.lcov
  coverage: '/测试覆盖率: (\d+\.\d+)%/'
```

### 触发条件

- **自动触发**：
  - 推送到 `main` 或 `develop` 分支
  - 创建或更新 Merge Request
  
- **手动触发**：
  - GitLab UI 中点击 "Run Pipeline"

### 查看结果

1. **Pipeline 页面**：
   - 进入项目 → CI/CD → Pipelines
   - 查看每个任务的状态和日志

2. **覆盖率报告**：
   - Pipeline 页面 → 点击任务 → Browse artifacts
   - 下载 `coverage/` 目录
   - 打开 `coverage/html/index.html` 查看详细报告

3. **覆盖率徽章**：
   - 项目首页自动显示覆盖率徽章
   - 格式：`Coverage: XX.XX%`

## GitHub Actions 配置

### 文件位置
`.github/workflows/test.yml`

### Workflow 任务

#### 1. 客户端测试 (test-client)

```yaml
test-client:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    - name: Run tests
      run: |
        cd dacong-client
        flutter pub get
        flutter test --coverage
    - name: Upload coverage
      uses: codecov/codecov-action@v4
      with:
        files: ./dacong-client/coverage/lcov.info
        flags: client
```

#### 2. 管理后台测试 (test-admin)

类似客户端测试，使用 `flags: admin`

#### 3. 后端 API 测试 (test-api)

```yaml
test-api:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: denoland/setup-deno@v1
      with:
        deno-version: v1.x
    - name: Run tests
      run: |
        cd dacong-api/supabase/functions
        deno test --allow-all --coverage=coverage
        deno coverage coverage --lcov > coverage.lcov
    - name: Upload coverage
      uses: codecov/codecov-action@v4
      with:
        files: ./dacong-api/supabase/functions/coverage.lcov
        flags: api
```

#### 4. 生成汇总报告 (generate-report)

```yaml
generate-report:
  needs: [test-client, test-admin, test-api]
  runs-on: ubuntu-latest
  steps:
    - name: Generate summary
      run: |
        echo "## 测试覆盖率汇总" >> $GITHUB_STEP_SUMMARY
        echo "| 模块 | 覆盖率 | 状态 |" >> $GITHUB_STEP_SUMMARY
        echo "|------|--------|------|" >> $GITHUB_STEP_SUMMARY
        # 添加各模块覆盖率数据
```

### 触发条件

- **自动触发**：
  - 推送到 `main` 或 `develop` 分支
  - 创建或更新 Pull Request
  - 每天凌晨 2 点定时运行

- **手动触发**：
  - Actions 页面 → 选择 workflow → Run workflow

### 查看结果

1. **Actions 页面**：
   - 进入项目 → Actions
   - 查看 workflow 运行状态

2. **Step Summary**：
   - 点击 workflow run
   - 查看自动生成的汇总报告

3. **Codecov 仪表板**：
   - 访问 https://codecov.io/gh/[username]/[repo]
   - 查看详细的覆盖率分析

4. **Artifacts**：
   - workflow run 页面 → Artifacts
   - 下载覆盖率报告（保存 30 天）

## 本地测试流程

### 客户端测试

```bash
# 进入客户端目录
cd dacong-client

# 安装依赖
flutter pub get

# 运行所有测试
flutter test

# 运行测试并生成覆盖率
flutter test --coverage

# 生成 HTML 报告
genhtml coverage/lcov.info -o coverage/html

# 查看报告
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

### 管理后台测试

```bash
cd dacong-admin
flutter pub get
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 后端 API 测试

```bash
cd dacong-api/supabase/functions
deno test --allow-all --coverage=coverage
deno coverage coverage --lcov > coverage.lcov

# 生成 HTML 报告
genhtml coverage.lcov -o coverage/html
```

### 运行特定测试

```bash
# 只运行数据层测试
flutter test test/data/

# 只运行 Widget 测试
flutter test test/presentation/widgets/

# 运行单个测试文件
flutter test test/data/models/comment_model_test.dart

# 运行测试并显示详细输出
flutter test --reporter expanded
```

## 覆盖率检查脚本

### 自动计算覆盖率

项目包含 Python 脚本自动计算覆盖率：

```bash
# 客户端
cd dacong-client
flutter test --coverage
python ../scripts/calculate_coverage.py coverage/lcov.info

# 输出示例：
# 测试覆盖率: 38.57%
# 已覆盖行数: 314
# 总代码行数: 771
```

### 覆盖率阈值检查

CI/CD 中自动检查覆盖率是否达标：

```bash
# 提取覆盖率百分比
COVERAGE=$(python calculate_coverage.py coverage/lcov.info | grep "测试覆盖率" | grep -oP '\d+\.\d+')

# 检查是否达到目标
if (( $(echo "$COVERAGE < 80" | bc -l) )); then
  echo "❌ 覆盖率 $COVERAGE% 低于目标 80%"
  exit 1
else
  echo "✅ 覆盖率 $COVERAGE% 达到目标"
fi
```

## 故障排查

### 测试失败

**问题**：某些测试在 CI 中失败，但本地通过

**解决方案**：
1. 检查 Flutter/Deno 版本是否一致
2. 确保所有依赖已正确安装
3. 检查环境变量配置
4. 查看 CI 日志中的详细错误信息

```bash
# 本地复现 CI 环境
docker run --rm -v $(pwd):/app -w /app cirrusci/flutter:3.24.0 \
  sh -c "cd dacong-client && flutter pub get && flutter test"
```

### 覆盖率不达标

**问题**：覆盖率低于目标值

**解决方案**：
1. 查看覆盖率报告，找出未覆盖的代码
2. 补充缺失的测试用例
3. 参考 `TEST_COVERAGE_REPORT.md` 中的待补充测试列表

```bash
# 生成详细的覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# 查看未覆盖的文件
lcov --list coverage/lcov.info | grep -v "100.0%"
```

### Artifacts 下载失败

**问题**：无法下载覆盖率报告

**解决方案**：
1. 检查 artifacts 是否已过期（默认 30 天）
2. 确保有足够的权限访问 artifacts
3. 尝试重新运行 pipeline

### Codecov 上传失败

**问题**：GitHub Actions 中 Codecov 上传失败

**解决方案**：
1. 检查 `CODECOV_TOKEN` 是否正确配置
2. 确保覆盖率文件路径正确
3. 查看 Codecov action 的日志

```yaml
# 添加调试信息
- name: Upload coverage
  uses: codecov/codecov-action@v4
  with:
    files: ./dacong-client/coverage/lcov.info
    flags: client
    verbose: true  # 启用详细日志
```

## 最佳实践

### 1. 提交前本地测试

```bash
# 运行所有测试
flutter test

# 确保没有失败的测试
# 确保覆盖率达标
```

### 2. 小步提交

- 每次提交包含相关的测试
- 避免大量代码一次性提交
- 保持 CI 快速反馈

### 3. 监控覆盖率趋势

- 定期查看覆盖率报告
- 关注覆盖率变化趋势
- 及时补充缺失的测试

### 4. 修复失败的测试

- 优先修复失败的测试
- 不要跳过失败的测试
- 确保测试稳定可靠

### 5. 代码审查

- 审查时检查是否包含测试
- 确保新功能有对应的测试
- 验证测试覆盖关键路径

## 配置文件参考

### .gitlab-ci.yml

完整配置文件位于项目根目录。

**关键配置**：
- `image`: 指定 Docker 镜像
- `script`: 测试命令
- `coverage`: 覆盖率提取正则表达式
- `artifacts`: 保存测试报告

### .github/workflows/test.yml

完整配置文件位于 `.github/workflows/` 目录。

**关键配置**：
- `on`: 触发条件
- `jobs`: 测试任务
- `uses`: 使用的 Actions
- `with`: Action 参数

## 相关文档

- [测试覆盖率报告](./TEST_COVERAGE_REPORT.md)
- [测试快速开始指南](../../TESTING_QUICKSTART.md)
- [GitLab CI 文档](https://docs.gitlab.com/ee/ci/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Codecov 文档](https://docs.codecov.com/)

## 更新日志

### 2026-04-17
- 初始化 CI/CD 配置
- 配置 GitLab CI 测试流程
- 配置 GitHub Actions 测试流程
- 添加覆盖率自动检查
- 集成 Codecov 覆盖率报告
