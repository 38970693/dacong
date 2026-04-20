# 生产就绪工程 - 详细执行计划

> 工期：12周 | 工时：480小时 | 优先级：P0（必须完成）

---

## 📋 工程概览

### 目标
将DaCong项目从开发状态提升到生产就绪状态，解决所有P0安全问题，建立完整的监控和部署体系。

### 核心价值
- ✅ 可部署到生产环境
- ✅ 通过安全审计
- ✅ 支持商业化运营
- ✅ 具备完整的监控和告警能力

---

## 🏗️ 总体架构

### 1. 安全架构

```
┌─────────────────────────────────────────────────┐
│              用户请求                            │
└──────────────────┬──────────────────────────────┘
                   │
         ┌─────────▼─────────┐
         │   CDN + WAF       │ ← DDoS防护、IP黑名单
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  CSRF Token验证   │ ← 状态变更请求验证
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  输入验证(Zod)    │ ← SQL注入、XSS防护
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  业务逻辑层       │
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  数据加密存储     │ ← 敏感数据加密
         └───────────────────┘
```

### 2. 监控架构

```
┌──────────────────────────────────────────────────┐
│                应用层                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ 客户端   │  │ 管理后台 │  │ 爬虫系统 │      │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘      │
│       │             │             │              │
│       └─────────────┼─────────────┘              │
│                     │                            │
└─────────────────────┼────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
   │ Sentry  │  │ Grafana │  │  Loki   │
   │ 错误监控│  │ 性能监控│  │ 日志聚合│
   └─────────┘  └─────────┘  └─────────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
              ┌───────▼───────┐
              │  告警系统     │
              │ (Email/Slack) │
              └───────────────┘
```

### 3. 部署架构

```
┌─────────────────────────────────────────────────┐
│              GitLab CI/CD                        │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐       │
│  │ Test │→ │ Lint │→ │Security│→│Deploy│       │
│  └──────┘  └──────┘  └──────┘  └──────┘       │
└──────────────────┬──────────────────────────────┘
                   │
         ┌─────────▼─────────┐
         │   Docker Registry │
         └─────────┬─────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
┌───▼───┐    ┌────▼────┐    ┌───▼───┐
│客户端 │    │管理后台 │    │爬虫   │
│Docker │    │Docker   │    │Docker │
└───────┘    └─────────┘    └───────┘
    │              │              │
    └──────────────┼──────────────┘
                   │
         ┌─────────▼─────────┐
         │   Supabase        │
         │ (PostgreSQL+Auth) │
         └───────────────────┘
```

---

## 📅 详细任务清单

## Week 1: 文档 + 监控 + CSRF

### 任务1.1: 编写生产环境部署指南
**工时**: 16小时  
**负责人**: DevOps工程师

**技术方案**:
1. 创建 `docs/deployment/production-deployment-guide.md`
2. 包含内容:
   - 服务器要求（CPU/内存/存储）
   - 域名配置（DNS记录）
   - SSL证书申请和配置
   - 环境变量配置清单
   - 数据库迁移步骤
   - 服务启动顺序
   - 健康检查配置
   - 回滚流程

**验收标准**:
- [ ] 文档完整，可按步骤完成部署
- [ ] 包含常见问题解答
- [ ] 经过至少1次实际部署验证

---

### 任务1.2: 集成Sentry错误监控
**工时**: 16小时  
**负责人**: 全栈工程师

**技术方案**:

**客户端集成** (Flutter):
```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_DSN';
      options.environment = const String.fromEnvironment('ENV', defaultValue: 'development');
      options.tracesSampleRate = 0.1; // 10%采样
      options.beforeSend = (event, hint) {
        // 过滤敏感信息
        return event;
      };
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

**后端集成** (Supabase Edge Functions):
```typescript
// supabase/functions/_shared/sentry.ts
import * as Sentry from '@sentry/deno';

Sentry.init({
  dsn: Deno.env.get('SENTRY_DSN'),
  environment: Deno.env.get('ENV') || 'development',
  tracesSampleRate: 0.1,
});

export function captureError(error: Error, context?: Record<string, any>) {
  Sentry.captureException(error, { extra: context });
}
```

**爬虫集成** (Python):
```python
# dacong-spider/main.py
import sentry_sdk

sentry_sdk.init(
    dsn=os.getenv('SENTRY_DSN'),
    environment=os.getenv('ENV', 'development'),
    traces_sample_rate=0.1,
)
```

**验收标准**:
- [ ] 所有子系统集成Sentry
- [ ] 错误自动上报
- [ ] 告警规则配置完成
- [ ] 测试错误上报流程

---

### 任务1.3: 实现CSRF防护
**工时**: 12小时  
**负责人**: 后端工程师

**技术方案**:

**后端实现**:
```typescript
// supabase/functions/_shared/csrf.ts
import { createHash } from 'crypto';

export function generateCSRFToken(sessionId: string): string {
  const secret = Deno.env.get('CSRF_SECRET')!;
  const timestamp = Date.now();
  const token = createHash('sha256')
    .update(`${sessionId}:${timestamp}:${secret}`)
    .digest('hex');
  return `${token}:${timestamp}`;
}

export function validateCSRFToken(
  token: string,
  sessionId: string,
  maxAge: number = 3600000 // 1小时
): boolean {
  const [hash, timestamp] = token.split(':');
  const age = Date.now() - parseInt(timestamp);
  
  if (age > maxAge) return false;
  
  const expected = generateCSRFToken(sessionId).split(':')[0];
  return hash === expected;
}

// 中间件
export function csrfMiddleware(req: Request): Response | null {
  if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(req.method)) {
    const token = req.headers.get('X-CSRF-Token');
    const sessionId = req.headers.get('X-Session-ID');
    
    if (!token || !sessionId || !validateCSRFToken(token, sessionId)) {
      return new Response('CSRF token invalid', { status: 403 });
    }
  }
  return null;
}
```

**前端集成**:
```dart
// lib/services/api_service.dart
class ApiService {
  String? _csrfToken;
  
  Future<void> refreshCSRFToken() async {
    final response = await http.get('/api/csrf-token');
    _csrfToken = response.data['token'];
  }
  
  Future<Response> post(String url, dynamic data) async {
    if (_csrfToken == null) await refreshCSRFToken();
    
    return http.post(url, data, headers: {
      'X-CSRF-Token': _csrfToken!,
      'X-Session-ID': sessionId,
    });
  }
}
```

**验收标准**:
- [ ] 所有状态变更API启用CSRF防护
- [ ] 通过安全测试（OWASP ZAP）
- [ ] Token自动刷新机制正常工作

---

## Week 2: 输入验证 + 密钥管理

### 任务2.1: 使用Zod定义API输入schema
**工时**: 24小时  
**负责人**: 后端工程师

**技术方案**:
```typescript
// supabase/functions/_shared/schemas.ts
import { z } from 'zod';

export const LoginSchema = z.object({
  email: z.string().email().max(255),
  password: z.string().min(8).max(128),
});

export const RegisterSchema = z.object({
  email: z.string().email().max(255),
  password: z.string().min(8).max(128).regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/),
  username: z.string().min(3).max(50).regex(/^[a-zA-Z0-9_]+$/),
});

export const CreateCommentSchema = z.object({
  content_id: z.string().uuid(),
  content: z.string().min(1).max(5000),
  parent_id: z.string().uuid().optional(),
});

// 统一验证中间件
export function validateRequest<T>(schema: z.ZodSchema<T>) {
  return async (req: Request): Promise<T | Response> {
    try {
      const body = await req.json();
      return schema.parse(body);
    } catch (error) {
      if (error instanceof z.ZodError) {
        return new Response(JSON.stringify({
          error: 'Validation failed',
          details: error.errors,
        }), { status: 400 });
      }
      throw error;
    }
  };
}
```

**验收标准**:
- [ ] 所有API定义输入schema
- [ ] 通过SQL注入测试
- [ ] 通过XSS测试
- [ ] 错误信息友好且不泄露敏感信息

---

### 任务2.2: 密钥管理完善
**工时**: 12小时  
**负责人**: DevOps工程师

**技术方案**:

**密钥轮换脚本**:
```bash
#!/bin/bash
# scripts/rotate-secrets.sh

# 生成新密钥
NEW_JWT_SECRET=$(openssl rand -hex 32)
NEW_CSRF_SECRET=$(openssl rand -hex 32)

# 更新Supabase secrets
supabase secrets set JWT_SECRET="$NEW_JWT_SECRET"
supabase secrets set CSRF_SECRET="$NEW_CSRF_SECRET"

# 记录轮换日志
echo "$(date): Rotated JWT_SECRET and CSRF_SECRET" >> logs/secret-rotation.log

# 发送通知
curl -X POST "$SLACK_WEBHOOK" -d "{\"text\":\"Secrets rotated successfully\"}"
```

**密钥过期提醒**:
```yaml
# .gitlab-ci.yml
secret-expiry-check:
  stage: security
  script:
    - python scripts/check-secret-expiry.py
  only:
    - schedules
  when: always
```

**验收标准**:
- [ ] 密钥可定期轮换
- [ ] 敏感数据加密存储
- [ ] 密钥过期提前7天告警

---

## Week 3: 日志聚合 + 性能监控

### 任务3.1: 日志聚合实现
**工时**: 20小时  
**负责人**: DevOps工程师

**技术方案**: 使用Grafana Loki

**Docker Compose配置**:
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yaml:/etc/loki/local-config.yaml
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log
      - ./promtail-config.yaml:/etc/promtail/config.yml
    command: -config.file=/etc/promtail/config.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  loki-data:
  grafana-data:
```

**验收标准**:
- [ ] 所有日志集中管理
- [ ] 支持日志查询和分析
- [ ] 告警规则配置完成

---

### 任务3.2: 性能监控实现
**工时**: 24小时  
**负责人**: 全栈工程师

**技术方案**:

**后端APM** (Supabase Edge Functions):
```typescript
// supabase/functions/_shared/apm.ts
import * as Sentry from '@sentry/deno';

export function trackPerformance(name: string) {
  const transaction = Sentry.startTransaction({ name });
  
  return {
    span: (operation: string) => transaction.startChild({ op: operation }),
    finish: () => transaction.finish(),
  };
}

// 使用示例
const perf = trackPerformance('api-get-models');
const dbSpan = perf.span('database-query');
// ... 数据库查询
dbSpan.finish();
perf.finish();
```

**前端性能监控** (Flutter):
```dart
// lib/services/performance_service.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  static Future<T> trace<T>(String name, Future<T> Function() operation) async {
    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.start();
    try {
      return await operation();
    } finally {
      await trace.stop();
    }
  }
}
```

**验收标准**:
- [ ] 所有子系统集成性能监控
- [ ] 性能指标可视化
- [ ] P95响应时间<500ms告警配置

---

## Week 4-6: 质量提升

### 任务4.1: 测试覆盖率提升 - 客户端
**工时**: 40小时  
**负责人**: 测试工程师 + 前端工程师

**技术方案**:

**Widget测试**:
```dart
// test/widgets/model_card_test.dart
void main() {
  testWidgets('ModelCard displays model info correctly', (tester) async {
    final model = Model(
      id: '1',
      name: 'GPT-4',
      score: 95.5,
    );
    
    await tester.pumpWidget(MaterialApp(
      home: ModelCard(model: model),
    ));
    
    expect(find.text('GPT-4'), findsOneWidget);
    expect(find.text('95.5'), findsOneWidget);
  });
}
```

**集成测试**:
```dart
// integration_test/login_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('User can login successfully', (tester) async {
    await tester.pumpWidget(MyApp());
    
    await tester.enterText(find.byKey(Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password')), 'password123');
    await tester.tap(find.byKey(Key('login-button')));
    await tester.pumpAndSettle();
    
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

**验收标准**:
- [ ] 测试覆盖率≥80%
- [ ] 关键用户流程有E2E测试
- [ ] CI自动运行测试

---

### 任务5.1: CI/CD完善
**工时**: 16小时  
**负责人**: DevOps工程师

**技术方案**:
```yaml
# .gitlab-ci.yml
stages:
  - test
  - lint
  - security
  - build
  - deploy

test:
  stage: test
  script:
    - cd dacong-client && flutter test --coverage
    - cd ../dacong-api && deno test --coverage
    - cd ../dacong-spider && pytest --cov
  coverage: '/TOTAL.*\s+(\d+%)$/'

lint:
  stage: lint
  script:
    - cd dacong-client && flutter analyze
    - cd ../dacong-api && deno lint
    - cd ../dacong-spider && pylint **/*.py

security:
  stage: security
  script:
    - npm audit
    - snyk test
    - trivy image dacong-client:latest

build:
  stage: build
  script:
    - docker build -t dacong-client:$CI_COMMIT_SHA ./dacong-client
    - docker build -t dacong-admin:$CI_COMMIT_SHA ./dacong-admin
    - docker build -t dacong-spider:$CI_COMMIT_SHA ./dacong-spider

deploy:
  stage: deploy
  script:
    - docker-compose -f docker-compose.prod.yml up -d
  only:
    - main
  when: manual
```

**验收标准**:
- [ ] 提交代码自动运行测试
- [ ] 测试通过自动部署
- [ ] 支持一键回滚

---

## Week 7-9: 用户体验

### 任务7.1: 主题切换功能
**工时**: 16小时  
**负责人**: 前端工程师

**技术方案**:
```dart
// lib/theme/theme_bloc.dart
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState.light()) {
    on<ToggleTheme>(_onToggleTheme);
    on<SetTheme>(_onSetTheme);
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'system';
    add(SetTheme(ThemeMode.values.byName(mode)));
  }
  
  Future<void> _onToggleTheme(ToggleTheme event, Emitter<ThemeState> emit) async {
    final newMode = state.mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(state.copyWith(mode: newMode));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', newMode.name);
  }
}
```

**验收标准**:
- [ ] 支持亮色/暗色/跟随系统
- [ ] 切换流畅，无闪烁
- [ ] 主题设置持久化

---

### 任务8.1: 内容收藏功能
**工时**: 12小时  
**负责人**: 全栈工程师

**数据库设计**:
```sql
-- 收藏表
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL, -- 'model', 'news', 'weekly'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, content_id, content_type)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_content ON favorites(content_id, content_type);
```

**API设计**:
```typescript
// POST /api/favorites
export async function addFavorite(req: Request): Promise<Response> {
  const data = await validateRequest(AddFavoriteSchema)(req);
  if (data instanceof Response) return data;
  
  const { user_id, content_id, content_type } = data;
  
  const { error } = await supabase
    .from('favorites')
    .insert({ user_id, content_id, content_type });
  
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }
  
  return new Response(JSON.stringify({ success: true }), { status: 201 });
}
```

**验收标准**:
- [ ] 用户可收藏内容
- [ ] 收藏列表正常展示
- [ ] 取消收藏立即生效

---

## Week 10-12: 性能优化

### 任务10.1: Redis缓存实现
**工时**: 12小时  
**负责人**: 后端工程师

**技术方案**:
```typescript
// supabase/functions/_shared/cache.ts
import { connect } from 'redis';

const redis = await connect({
  hostname: Deno.env.get('REDIS_HOST')!,
  port: parseInt(Deno.env.get('REDIS_PORT')!),
});

export async function cacheGet<T>(key: string): Promise<T | null> {
  const value = await redis.get(key);
  return value ? JSON.parse(value) : null;
}

export async function cacheSet(key: string, value: any, ttl: number = 3600): Promise<void> {
  await redis.setex(key, ttl, JSON.stringify(value));
}

export async function cacheInvalidate(pattern: string): Promise<void> {
  const keys = await redis.keys(pattern);
  if (keys.length > 0) {
    await redis.del(...keys);
  }
}
```

**验收标准**:
- [ ] 生产环境使用Redis
- [ ] 缓存命中率>80%
- [ ] 响应时间降低50%

---

### 任务11.1: CDN配置
**工时**: 8小时  
**负责人**: DevOps工程师

**技术方案**: 使用阿里云CDN

**配置步骤**:
1. 创建CDN域名（cdn.dacong.com）
2. 配置源站（origin.dacong.com）
3. 配置缓存规则:
   - 静态资源（.js/.css/.png/.jpg）: 缓存30天
   - HTML: 缓存1小时
   - API: 不缓存
4. 配置HTTPS证书
5. 配置回源Host
6. 配置访问控制（防盗链）

**验收标准**:
- [ ] 静态资源通过CDN加载
- [ ] 首屏加载时间<2秒
- [ ] CDN命中率>90%

---

## 🎯 里程碑和验收

### Milestone 1: 安全加固完成（Week 3）
- ✅ 部署文档完整
- ✅ 错误监控上线
- ✅ CSRF防护上线
- ✅ 输入验证完善
- ✅ 密钥管理完善
- ✅ 日志聚合上线
- ✅ 性能监控上线

### Milestone 2: 质量提升完成（Week 6）
- ✅ 测试覆盖率达标
- ✅ CI/CD流程完整
- ✅ Docker配置完整

### Milestone 3: 用户体验完成（Week 9）
- ✅ 主题切换功能上线
- ✅ 无障碍支持完善
- ✅ 用户功能完整
- ✅ 内容收藏和分享功能上线

### Milestone 4: 性能优化完成（Week 12）
- ✅ Redis缓存上线
- ✅ CDN配置完成
- ✅ 操作日志记录上线
- ✅ 批量操作功能上线
- ✅ 数据导出功能上线

---

## 📊 成功指标

### 技术指标
| 指标 | 当前 | 目标 |
|------|------|------|
| 测试覆盖率（客户端） | 未知 | 80%+ |
| 测试覆盖率（后端） | 未知 | 85%+ |
| 首屏加载时间 | 未知 | <2s |
| API响应时间（P95） | 未知 | <500ms |
| 缓存命中率 | 0% | >80% |
| 错误率 | 未知 | <0.1% |

### 安全指标
| 指标 | 当前 | 目标 |
|------|------|------|
| 高危漏洞 | 未知 | 0 |
| CSRF防护 | ❌ | ✅ |
| 输入验证 | 部分 | 全部 |

---

## 🚨 风险管理

### 风险1: 测试覆盖率提升耗时超预期
**概率**: 中 | **影响**: 高  
**应对**: 优先覆盖核心功能，使用测试生成工具加速

### 风险2: 第三方服务集成困难
**概率**: 低 | **影响**: 中  
**应对**: 提前调研选型，准备备选方案

### 风险3: 性能优化效果不达预期
**概率**: 中 | **影响**: 中  
**应对**: 先做性能基准测试，逐步优化验证

---

**计划制定者**: Claude Code  
**审核状态**: 待审核  
**开始日期**: 待定  
**预计完成日期**: 开始后12周
