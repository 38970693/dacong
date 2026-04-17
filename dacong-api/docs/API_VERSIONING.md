# API 版本管理文档

## 概述

大聪 API 采用语义化版本管理策略，确保向后兼容性和平滑的版本迁移。本文档详细说明了版本管理的规则、策略和最佳实践。

## 版本命名规则

### 版本格式

API 版本采用 `v{major}` 格式，例如：
- `v1` - 第一个主版本
- `v2` - 第二个主版本
- `v3` - 第三个主版本

### 版本号含义

- **主版本号（Major）**：包含破坏性变更，不向后兼容
- 次版本号和补丁版本号在 API 层面不体现，通过部署管理

## 版本指定方式

客户端可以通过两种方式指定 API 版本：

### 1. URL 路径（推荐）

```
GET https://api.dacong.ai/v1/get-recommendations?scenario=morning
GET https://api.dacong.ai/v2/get-recommendations?scenario=morning
```

**优点**：
- 清晰明确
- 易于缓存
- 便于路由和负载均衡

### 2. HTTP Header

```http
GET /get-recommendations?scenario=morning HTTP/1.1
Host: api.dacong.ai
API-Version: v1
```

**优点**：
- URL 保持简洁
- 便于版本协商

### 优先级

当同时指定时，优先级为：**URL 路径 > HTTP Header > 默认版本**

## 版本兼容策略

### 向后兼容的变更

以下变更不需要升级主版本号：

✅ **允许的变更**：
- 添加新的 API 端点
- 添加新的可选请求参数
- 添加新的响应字段
- 修复 bug
- 性能优化
- 改进错误消息

### 破坏性变更

以下变更需要升级主版本号：

❌ **破坏性变更**：
- 删除或重命名 API 端点
- 删除或重命名请求/响应字段
- 修改字段类型
- 修改必需参数
- 修改默认行为
- 修改错误码

## 版本生命周期

### 1. 开发阶段（Development）

- 版本处于开发中
- API 可能频繁变更
- 不建议在生产环境使用

### 2. 稳定阶段（Stable）

- 版本已发布并稳定
- 完全支持和维护
- 推荐在生产环境使用

### 3. 弃用阶段（Deprecated）

- 版本标记为已弃用
- 仍然可用但不推荐使用
- 响应头包含弃用警告
- 至少维护 6 个月

### 4. 停用阶段（Sunset）

- 版本停止服务
- 请求将返回 410 Gone
- 必须迁移到新版本

## 弃用策略

### 弃用通知

当版本被标记为弃用时，API 响应将包含以下 HTTP 头：

```http
HTTP/1.1 200 OK
API-Version: v1
Deprecation: true
Sunset: Wed, 31 Dec 2026 23:59:59 GMT
Link: <https://docs.dacong.ai/api/migration/v2>; rel="deprecation"
Warning: 299 - "API version v1 is deprecated. Please migrate to the latest version."
```

### 弃用时间线

```
发布新版本 → 6个月后标记旧版本为弃用 → 6个月后停用旧版本
```

**示例**：
- 2026-01-01: v2 发布
- 2026-07-01: v1 标记为弃用
- 2027-01-01: v1 停用

### 提前通知

- 弃用前 **3 个月**：通过邮件、文档、博客通知
- 弃用前 **1 个月**：在响应中添加弃用警告
- 停用前 **2 周**：最后通知

## 版本迁移指南

### 从 v1 迁移到 v2

#### 主要变更

1. **统一响应格式**
   ```typescript
   // v1 响应
   {
     "success": true,
     "data": [...],
     "meta": {...}
   }

   // v2 响应（保持一致，但增强了错误处理）
   {
     "success": true,
     "data": [...],
     "meta": {...},
     "version": "v2"
   }
   ```

2. **改进的错误处理**
   ```typescript
   // v1 错误响应
   {
     "success": false,
     "error": "Validation error"
   }

   // v2 错误响应
   {
     "success": false,
     "error": {
       "code": "VALIDATION_ERROR",
       "message": "Validation error",
       "details": [...]
     }
   }
   ```

3. **新增功能**
   - 批量操作支持
   - 更细粒度的权限控制
   - 改进的分页机制

#### 迁移步骤

1. **评估影响**
   - 审查当前使用的 API 端点
   - 识别需要修改的代码

2. **更新客户端代码**
   ```typescript
   // 旧代码
   const response = await fetch('https://api.dacong.ai/v1/get-recommendations');
   
   // 新代码
   const response = await fetch('https://api.dacong.ai/v2/get-recommendations');
   ```

3. **测试**
   - 在测试环境验证所有功能
   - 确保错误处理正确

4. **逐步部署**
   - 使用金丝雀发布
   - 监控错误率和性能

5. **完全迁移**
   - 所有客户端切换到 v2
   - 停止使用 v1

## 客户端实现

### Dart/Flutter 示例

```dart
class ApiClient {
  final String baseUrl;
  final String apiVersion;

  ApiClient({
    required this.baseUrl,
    this.apiVersion = 'v1',
  });

  String getEndpoint(String path) {
    return '$baseUrl/$apiVersion/$path';
  }

  Future<Response> get(String path, {Map<String, String>? headers}) async {
    final url = getEndpoint(path);
    final response = await http.get(
      Uri.parse(url),
      headers: {
        ...?headers,
        'API-Version': apiVersion,
      },
    );

    // 检查弃用警告
    if (response.headers['deprecation'] == 'true') {
      final sunsetDate = response.headers['sunset'];
      final migrationGuide = response.headers['link'];
      
      print('Warning: API version $apiVersion is deprecated.');
      print('Sunset date: $sunsetDate');
      print('Migration guide: $migrationGuide');
    }

    return response;
  }
}

// 使用示例
final client = ApiClient(
  baseUrl: 'https://api.dacong.ai',
  apiVersion: 'v1',
);

final response = await client.get('get-recommendations?scenario=morning');
```

### TypeScript/JavaScript 示例

```typescript
interface ApiClientConfig {
  baseUrl: string;
  apiVersion?: string;
}

class ApiClient {
  private baseUrl: string;
  private apiVersion: string;

  constructor(config: ApiClientConfig) {
    this.baseUrl = config.baseUrl;
    this.apiVersion = config.apiVersion || 'v1';
  }

  private getEndpoint(path: string): string {
    return `${this.baseUrl}/${this.apiVersion}/${path}`;
  }

  async get<T>(path: string, headers?: Record<string, string>): Promise<T> {
    const url = this.getEndpoint(path);
    const response = await fetch(url, {
      headers: {
        ...headers,
        'API-Version': this.apiVersion,
      },
    });

    // 检查弃用警告
    if (response.headers.get('deprecation') === 'true') {
      const sunsetDate = response.headers.get('sunset');
      const migrationGuide = response.headers.get('link');
      
      console.warn(`API version ${this.apiVersion} is deprecated.`);
      console.warn(`Sunset date: ${sunsetDate}`);
      console.warn(`Migration guide: ${migrationGuide}`);
    }

    return response.json();
  }
}

// 使用示例
const client = new ApiClient({
  baseUrl: 'https://api.dacong.ai',
  apiVersion: 'v1',
});

const data = await client.get('get-recommendations?scenario=morning');
```

## 版本检测和自动升级

### 自动版本检测

```dart
class ApiVersionManager {
  static const String currentVersion = 'v1';
  static const String latestVersion = 'v2';

  Future<String> detectOptimalVersion() async {
    try {
      // 尝试使用最新版本
      final response = await http.get(
        Uri.parse('https://api.dacong.ai/$latestVersion/health'),
      );

      if (response.statusCode == 200) {
        return latestVersion;
      }
    } catch (e) {
      // 最新版本不可用，回退到当前版本
    }

    return currentVersion;
  }

  bool shouldUpgrade(String currentVersion, String latestVersion) {
    final current = int.parse(currentVersion.replaceAll('v', ''));
    final latest = int.parse(latestVersion.replaceAll('v', ''));
    return latest > current;
  }
}
```

## 监控和分析

### 版本使用统计

跟踪以下指标：
- 各版本的请求量
- 弃用版本的使用率
- 迁移进度
- 错误率对比

### 告警规则

设置以下告警：
- 弃用版本使用率 > 10%（停用前 1 个月）
- 新版本错误率 > 旧版本 2 倍
- 版本迁移进度低于预期

## 最佳实践

### 对于 API 提供方

1. **保持向后兼容**
   - 尽可能避免破坏性变更
   - 使用可选参数而非必需参数

2. **提前通知**
   - 至少提前 6 个月通知弃用
   - 提供详细的迁移指南

3. **渐进式发布**
   - 使用金丝雀发布测试新版本
   - 监控错误率和性能

4. **文档完善**
   - 维护详细的变更日志
   - 提供代码示例和迁移工具

### 对于 API 使用方

1. **版本固定**
   - 明确指定 API 版本
   - 不要依赖默认版本

2. **监控弃用警告**
   - 检查响应头中的弃用信息
   - 及时规划迁移

3. **测试充分**
   - 在测试环境验证新版本
   - 准备回滚方案

4. **逐步迁移**
   - 使用特性开关控制迁移
   - 监控迁移后的表现

## 常见问题

### Q: 如果不指定版本会怎样？

A: 系统会使用默认版本（当前为 v1）。但强烈建议明确指定版本，避免默认版本变更导致的问题。

### Q: 可以同时使用多个版本吗？

A: 可以。不同的 API 调用可以使用不同的版本，便于渐进式迁移。

### Q: 版本弃用后还能使用吗？

A: 可以，但会收到弃用警告。建议尽快迁移到新版本。

### Q: 如何知道当前使用的版本？

A: 检查响应头中的 `API-Version` 字段。

### Q: 迁移需要多长时间？

A: 取决于使用的 API 数量和复杂度。通常简单应用需要 1-2 周，复杂应用需要 1-2 个月。

## 相关资源

- [API 文档](https://docs.dacong.ai/api)
- [变更日志](https://docs.dacong.ai/changelog)
- [迁移工具](https://github.com/dacong/api-migration-tools)
- [技术支持](mailto:support@dacong.ai)

## 版本历史

| 版本 | 发布日期 | 状态 | 停用日期 |
|------|----------|------|----------|
| v1   | 2026-01-01 | 稳定 | - |
| v2   | TBD | 开发中 | - |

---

**最后更新**: 2026-04-17  
**文档版本**: 1.0.0
