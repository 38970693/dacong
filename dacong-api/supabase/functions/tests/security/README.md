# 安全测试

本目录包含 Dacong API 的安全测试脚本，用于验证输入验证和安全防护机制。

## 测试套件

### 1. SQL 注入防护测试 (`test_sql_injection.sh`)

测试 API 是否能够防御 SQL 注入攻击。

**测试场景**：
- UNION SELECT 注入
- DROP TABLE 注入
- 布尔盲注（OR 1=1）
- 注释符注入（--）
- 无效 UUID 格式
- 超长输入

### 2. XSS 防护测试 (`test_xss.sh`)

测试 API 是否能够防御跨站脚本攻击。

**测试场景**：
- 基本 `<script>` 标签
- IMG onerror 注入
- JavaScript 协议
- 事件处理器（onclick）
- SVG onload 注入
- iframe 注入
- data: 协议
- vbscript: 协议
- HTML 实体编码绕过
- 大小写混淆

## 运行测试

### 前置条件

1. 启动 Supabase 本地开发环境：
   ```bash
   cd dacong-api
   supabase start
   ```

2. 设置环境变量：
   ```bash
   export SUPABASE_ANON_KEY="your-anon-key"
   export API_BASE_URL="http://localhost:54321/functions/v1"
   ```

   获取 `SUPABASE_ANON_KEY`：
   ```bash
   supabase status | grep "anon key"
   ```

### 运行所有测试

```bash
cd supabase/functions/tests/security
chmod +x run_all_tests.sh
./run_all_tests.sh
```

### 运行单个测试

#### SQL 注入测试

```bash
chmod +x test_sql_injection.sh
./test_sql_injection.sh
```

#### XSS 测试

```bash
chmod +x test_xss.sh
./test_xss.sh
```

## 测试结果

### 成功示例

```
==========================================
SQL 注入防护测试
==========================================

测试 1: 搜索内容 - SQL 注入 (UNION SELECT)
✓ 通过 - API 正确拒绝了恶意输入 (HTTP 400)

测试 2: 搜索内容 - SQL 注入 (DROP TABLE)
✓ 通过 - API 正确拒绝了恶意输入 (HTTP 400)

...

==========================================
测试结果汇总
==========================================
总测试数: 10
通过: 10
失败: 0

✓ 所有 SQL 注入防护测试通过！
```

### 失败示例

如果测试失败，会显示详细的错误信息：

```
测试 3: 提交评论 - SQL 注入 (content_id)
✗ 失败 - API 未能拒绝恶意输入 (HTTP 200)
响应: {"success":true,"data":{...}}
```

## 持续集成

### GitHub Actions

在 `.github/workflows/security-tests.yml` 中添加：

```yaml
name: Security Tests

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main]

jobs:
  security-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1
        
      - name: Start Supabase
        run: supabase start
        
      - name: Run Security Tests
        env:
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        run: |
          cd supabase/functions/tests/security
          chmod +x run_all_tests.sh
          ./run_all_tests.sh
```

### GitLab CI

在 `.gitlab-ci.yml` 中添加：

```yaml
security-tests:
  stage: test
  image: supabase/cli:latest
  script:
    - supabase start
    - export SUPABASE_ANON_KEY=$(supabase status | grep "anon key" | cut -d: -f2 | xargs)
    - cd supabase/functions/tests/security
    - chmod +x run_all_tests.sh
    - ./run_all_tests.sh
```

## 扩展测试

### 添加新的测试场景

1. 编辑测试脚本（`test_sql_injection.sh` 或 `test_xss.sh`）
2. 使用 `test_sql_injection` 或 `test_xss_protection` 函数添加新测试
3. 运行测试验证

示例：

```bash
# 添加新的 SQL 注入测试
test_sql_injection \
  "新测试场景" \
  "endpoint-name" \
  '{"field": "malicious input"}'
```

### 创建新的测试套件

1. 创建新的测试脚本（例如 `test_csrf.sh`）
2. 在 `run_all_tests.sh` 中添加：
   ```bash
   run_test_suite "CSRF 防护测试" "$SCRIPT_DIR/test_csrf.sh"
   ```

## 故障排查

### 测试无法连接到 API

**问题**：`curl: (7) Failed to connect`

**解决方案**：
1. 确认 Supabase 已启动：`supabase status`
2. 检查 API_BASE_URL 是否正确
3. 确认 Edge Functions 已部署

### 所有测试都失败

**问题**：所有测试返回 HTTP 500

**解决方案**：
1. 检查 Edge Functions 日志：`supabase functions logs`
2. 确认数据库 schema 已迁移
3. 检查环境变量是否正确设置

### 认证相关测试失败

**问题**：测试返回 HTTP 401

**解决方案**：
1. 某些端点需要认证，设置 `AUTH_TOKEN` 环境变量
2. 获取有效的 JWT token：
   ```bash
   # 使用 Supabase CLI 登录并获取 token
   supabase auth login
   ```

## 相关文档

- [输入验证文档](../../docs/security/INPUT_VALIDATION.md)
- [API 文档](../../docs/API.md)
- [安全最佳实践](../../docs/security/BEST_PRACTICES.md)

## 贡献

发现安全问题或想要添加新的测试场景？请提交 Issue 或 Pull Request。

**注意**：请勿在 Issue 中公开披露安全漏洞，请通过私密渠道联系维护者。
