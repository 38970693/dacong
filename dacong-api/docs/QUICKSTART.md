# 推荐 API 快速开始

## 前置条件

- Deno 1.37+ (Edge Functions 运行时)
- Supabase CLI
- curl 或 Postman (API 测试)

## 安装 Deno

### Windows
```powershell
irm https://deno.land/install.ps1 | iex
```

### Linux/macOS
```bash
curl -fsSL https://deno.land/install.sh | sh
```

验证安装：
```bash
deno --version
```

## 本地开发

### 1. 启动 Supabase 本地环境

```bash
cd dacong-api
supabase start
```

### 2. 运行单元测试

```bash
# 运行所有测试
./scripts/run-tests.sh

# 或单独运行某个测试
cd supabase/functions
deno test --allow-all tests/RecommendationService.test.ts
deno test --allow-all tests/Cache.test.ts
```

### 3. 本地测试 Edge Function

```bash
# 启动本地 Edge Functions
supabase functions serve get-recommendations

# 在另一个终端测试
curl "http://localhost:54321/functions/v1/get-recommendations?scenario=coding&language=zh&limit=10"
```

### 4. 运行 API 集成测试

```bash
# 设置本地 API URL
export API_BASE_URL="http://localhost:54321/functions/v1"

# 运行测试
./scripts/test-api.sh
```

## 部署到生产环境

### 1. 登录 Supabase

```bash
supabase login
```

### 2. 链接项目

```bash
supabase link --project-ref your-project-ref
```

### 3. 部署 Edge Function

```bash
supabase functions deploy get-recommendations
```

### 4. 验证部署

```bash
# 测试生产环境
export API_BASE_URL="https://your-project.supabase.co/functions/v1"
./scripts/test-api.sh
```

## API 使用示例

### cURL

```bash
# 获取 coding 场景推荐
curl "https://your-project.supabase.co/functions/v1/get-recommendations?scenario=coding&language=zh&limit=10"

# 获取 video 场景推荐（英文）
curl "https://your-project.supabase.co/functions/v1/get-recommendations?scenario=video&language=en&limit=5"
```

### JavaScript

```javascript
const response = await fetch(
  'https://your-project.supabase.co/functions/v1/get-recommendations?scenario=coding&language=zh&limit=10'
);

const result = await response.json();
console.log(result);
```

### Flutter/Dart

```dart
final response = await http.get(
  Uri.parse('https://your-project.supabase.co/functions/v1/get-recommendations')
    .replace(queryParameters: {
      'scenario': 'coding',
      'language': 'zh',
      'limit': '10',
    }),
);

final result = jsonDecode(response.body);
print(result);
```

## 监控

### 查看日志

```bash
# 实时日志
supabase functions logs get-recommendations --tail

# 错误日志
supabase functions logs get-recommendations --level error
```

### 性能监控

在 Supabase Dashboard 中查看：
- 请求数量
- 响应时间
- 错误率

## 故障排查

### 测试失败

```bash
# 检查 Deno 版本
deno --version

# 重新运行测试
cd supabase/functions
deno test --allow-all tests/
```

### API 返回错误

```bash
# 查看详细日志
supabase functions logs get-recommendations --tail

# 检查环境变量
supabase secrets list
```

### 性能问题

1. 检查缓存是否生效
2. 查看数据库查询性能
3. 检查数据库索引

## 下一步

- 阅读 [完整 API 文档](./RECOMMENDATION_API.md)
- 查看 [实现总结](./IMPLEMENTATION_SUMMARY.md)
- 了解 [系统架构设计](../../dacong-docs/03-系统架构设计.md)

## 支持

如有问题，请查看：
- [Supabase 文档](https://supabase.com/docs)
- [Deno 文档](https://deno.land/manual)
- 项目 Issue 跟踪
