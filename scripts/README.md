# 部署脚本使用说明

## 快速开始

### 一键部署到测试环境

```bash
# 1. 配置环境变量
cp .env.test .env.test.local
# 编辑 .env.test.local，填写实际值

# 2. 运行部署脚本
./scripts/deploy_test.sh
```

## 脚本说明

### 主部署脚本

#### `deploy_test.sh`
一键部署整个系统到测试环境。

**功能**：
- 环境检查
- 数据库部署
- API 部署
- 前端构建
- 健康检查
- 冒烟测试
- 生成部署报告

**使用**：
```bash
./scripts/deploy_test.sh
```

### 组件部署脚本

#### `deploy_database.sh`
部署数据库 schema 和 migrations。

**功能**：
- 链接 Supabase 项目
- 运行数据库迁移
- 验证表结构
- 可选：初始化测试数据

**使用**：
```bash
./scripts/deploy_database.sh

# 初始化测试数据
INIT_TEST_DATA=true ./scripts/deploy_database.sh
```

#### `deploy_api.sh`
部署所有 Supabase Edge Functions。

**功能**：
- 扫描所有 Functions
- 逐个部署
- 设置环境变量
- 验证部署状态

**使用**：
```bash
./scripts/deploy_api.sh
```

#### `build_frontend.sh`
构建 Flutter Web 应用。

**功能**：
- 清理旧构建
- 获取依赖
- 运行代码生成
- 构建 Release 版本
- 生成构建清单

**使用**：
```bash
./scripts/build_frontend.sh

# 构建后启动预览服务器
START_SERVER=true ./scripts/build_frontend.sh
```

### 验证脚本

#### `verify_deployment.sh`
验证部署是否成功。

**功能**：
- 数据库连接测试
- API 端点测试
- 前端构建验证
- 性能测试
- 安全测试
- 生成验证报告

**使用**：
```bash
./scripts/verify_deployment.sh
```

### 冒烟测试脚本

#### `test_api_smoke.sh`
API 冒烟测试。

**测试内容**：
- 推荐接口（多场景）
- 搜索接口
- 内容详情接口
- 周报接口
- 评论接口
- 实时统计接口

**使用**：
```bash
./tests/smoke/test_api_smoke.sh
```

#### `test_frontend_smoke.sh`
前端冒烟测试。

**测试内容**：
- 构建文件检查
- HTML 内容检查
- 资源文件检查
- 文件大小检查
- 可选：本地服务器测试

**使用**：
```bash
./tests/smoke/test_frontend_smoke.sh

# 启动服务器测试
START_SERVER=true ./tests/smoke/test_frontend_smoke.sh
```

#### `test_e2e_smoke.sh`
端到端冒烟测试。

**测试场景**：
1. 用户获取推荐内容
2. 用户查看内容详情
3. 用户搜索内容
4. 用户查看评论
5. 用户查看周报
6. 完整用户旅程

**使用**：
```bash
./tests/smoke/test_e2e_smoke.sh
```

## 环境变量

### 必需变量

```bash
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
DATABASE_URL=postgresql://...

# API
ANTHROPIC_API_KEY=sk-ant-your-key
```

### 可选变量

```bash
# 测试数据
INIT_TEST_DATA=true          # 是否初始化测试数据

# 前端
START_SERVER=true            # 构建后是否启动服务器
FLUTTER_WEB_URL=http://localhost:8080

# 日志
LOG_LEVEL=debug
VERBOSE_LOGGING=true
```

## 输出文件

### 部署报告

```
deployment_report_YYYYMMDD_HHMMSS.txt
```

包含：
- 部署时间
- 环境信息
- 部署组件
- 验证结果
- 下一步操作
- 回滚方案

### 验证报告

```
tests/smoke/results/verification_YYYYMMDD_HHMMSS.txt
```

包含：
- 数据库测试结果
- API 测试结果
- 前端测试结果
- 性能测试结果
- 安全测试结果
- 测试总结

### 构建清单

```
dacong-client/build/web/build_manifest.json
```

包含：
- 构建时间
- Flutter 版本
- 构建模式
- 构建大小
- Git 信息

## 故障排查

### 脚本执行失败

```bash
# 检查脚本权限
ls -l scripts/*.sh

# 添加执行权限
chmod +x scripts/*.sh

# 查看详细错误
bash -x scripts/deploy_test.sh
```

### 环境变量未加载

```bash
# 手动加载
source .env.test.local

# 验证
echo $SUPABASE_URL
```

### 数据库连接失败

```bash
# 测试连接
psql $DATABASE_URL -c "SELECT 1"

# 检查 Supabase 项目状态
supabase projects list
```

### API 部署失败

```bash
# 查看日志
supabase functions logs <function-name>

# 手动部署单个 Function
cd dacong-api/supabase/functions
supabase functions deploy <function-name>
```

### 前端构建失败

```bash
# 清理缓存
cd dacong-client
flutter clean
flutter pub get

# 检查 Flutter 版本
flutter doctor -v
```

## 最佳实践

### 1. 部署前检查

```bash
# 运行所有测试
npm test

# 检查代码质量
npm run lint

# 验证环境配置
cat .env.test.local
```

### 2. 分步部署

对于大型更新，建议分步部署：

```bash
# 1. 先部署数据库
./scripts/deploy_database.sh

# 2. 验证数据库
psql $DATABASE_URL -c "\dt"

# 3. 部署 API
./scripts/deploy_api.sh

# 4. 验证 API
./tests/smoke/test_api_smoke.sh

# 5. 构建前端
./scripts/build_frontend.sh

# 6. 验证前端
./tests/smoke/test_frontend_smoke.sh
```

### 3. 监控部署

```bash
# 实时查看 API 日志
supabase functions logs --tail

# 监控数据库性能
# 在 Supabase Dashboard 查看
```

### 4. 回滚准备

```bash
# 记录当前版本
git rev-parse HEAD > .last_deployed_commit

# 如需回滚
git checkout $(cat .last_deployed_commit)
./scripts/deploy_test.sh
```

## 常见问题

### Q: 如何只部署某个 Function？

```bash
cd dacong-api/supabase/functions
supabase functions deploy <function-name>
```

### Q: 如何查看部署历史？

```bash
# Git 历史
git log --oneline --grep="deploy"

# 部署报告
ls -lt deployment_report_*.txt
```

### Q: 如何测试单个 API 端点？

```bash
curl "$SUPABASE_URL/functions/v1/<function-name>" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"key":"value"}'
```

### Q: 如何清理旧的构建文件？

```bash
cd dacong-client
flutter clean
rm -rf build/
```

## 相关文档

- [部署文档](../docs/DEPLOYMENT.md)
- [API 文档](../dacong-api/docs/API.md)
- [测试指南](../dacong-api/docs/TESTING.md)
