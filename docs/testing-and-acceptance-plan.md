# 三大工程测试验收计划

> 创建日期：2026-04-20  
> 状态：待执行

---

## 📋 验收概览

本文档定义了三大工程的测试策略、验收标准和验收流程。

---

## 🎯 验收原则

1. **独立验收**: 每个工程独立验收，互不阻塞
2. **分阶段验收**: 每个里程碑完成后进行阶段验收
3. **自动化优先**: 优先使用自动化测试
4. **文档齐全**: 验收时必须提供完整文档

---

## 🧪 测试策略

### 测试金字塔

```
        ┌─────────────┐
        │  E2E测试    │  10%
        │  (手动+自动)│
        ├─────────────┤
        │  集成测试   │  30%
        │  (自动化)   │
        ├─────────────┤
        │  单元测试   │  60%
        │  (自动化)   │
        └─────────────┘
```

### 测试类型

| 测试类型 | 覆盖范围 | 工具 | 负责人 |
|---------|---------|------|--------|
| 单元测试 | 函数/类 | Jest, pytest, flutter test | 开发工程师 |
| 集成测试 | API/模块 | Supertest, integration_test | 测试工程师 |
| E2E测试 | 用户流程 | Cypress, flutter_driver | 测试工程师 |
| 性能测试 | 响应时间/吞吐量 | k6, JMeter | 性能工程师 |
| 安全测试 | 漏洞扫描 | OWASP ZAP, Snyk | 安全工程师 |

---

## 📊 工程1：生产就绪工程验收

### Milestone 1: 安全加固（Week 3）

#### 验收清单

**1. 部署文档验收**
- [ ] 文档完整性检查
  - [ ] 服务器要求明确
  - [ ] 环境变量清单完整
  - [ ] 部署步骤清晰
  - [ ] 回滚流程明确
- [ ] 实际部署测试
  - [ ] 按文档完成一次完整部署
  - [ ] 记录部署时间（目标<30分钟）
  - [ ] 验证所有服务正常启动

**2. Sentry集成验收**
- [ ] 功能测试
  - [ ] 客户端错误自动上报
  - [ ] 后端错误自动上报
  - [ ] 爬虫错误自动上报
- [ ] 告警测试
  - [ ] 触发测试错误
  - [ ] 验证告警通知（Email/Slack）
  - [ ] 验证错误聚合和去重

**3. CSRF防护验证**
- [ ] 安全测试
  - [ ] 使用OWASP ZAP扫描
  - [ ] 手动CSRF攻击测试
  - [ ] Token过期测试
- [ ] 功能测试
  - [ ] 正常请求通过
  - [ ] 无Token请求被拒绝
  - [ ] 过期Token请求被拒绝

**4. 输入验证验收**
- [ ] SQL注入测试
  ```bash
  # 测试用例
  curl -X POST /api/login \
    -d '{"email": "admin@example.com", "password": "' OR '1'='1"}'
  # 预期：400 Bad Request
  ```
- [ ] XSS测试
  ```bash
  curl -X POST /api/comments \
    -d '{"content": "<script>alert(1)</script>"}'
  # 预期：内容被转义或拒绝
  ```
- [ ] 边界值测试
  - [ ] 超长字符串（>5000字符）
  - [ ] 特殊字符
  - [ ] 空值/null值

**验收标准**:
- ✅ 所有测试用例通过
- ✅ 安全扫描无高危漏洞
- ✅ 文档可用性验证通过

---

### Milestone 2: 质量提升（Week 6）

#### 验收清单

**1. 测试覆盖率验收**
- [ ] 客户端测试覆盖率
  ```bash
  cd dacong-client
  flutter test --coverage
  genhtml coverage/lcov.info -o coverage/html
  # 验证覆盖率 ≥ 80%
  ```
- [ ] 后端测试覆盖率
  ```bash
  cd dacong-api
  deno test --coverage=coverage
  deno coverage coverage --lcov > coverage.lcov
  # 验证覆盖率 ≥ 85%
  ```
- [ ] 管理后台测试覆盖率
  ```bash
  cd dacong-admin
  flutter test --coverage
  # 验证覆盖率 ≥ 70%
  ```

**2. CI/CD流程验收**
- [ ] 自动化测试
  - [ ] 提交代码触发测试
  - [ ] 测试失败阻止合并
  - [ ] 测试报告生成
- [ ] 自动化部署
  - [ ] 测试通过自动部署到staging
  - [ ] 手动批准后部署到production
  - [ ] 部署失败自动回滚

**3. Docker配置验收**
- [ ] 镜像构建测试
  ```bash
  docker build -t dacong-client:test ./dacong-client
  docker build -t dacong-admin:test ./dacong-admin
  docker build -t dacong-spider:test ./dacong-spider
  ```
- [ ] 容器运行测试
  ```bash
  docker-compose -f docker-compose.prod.yml up -d
  # 验证所有服务正常启动
  ```

**验收标准**:
- ✅ 测试覆盖率达标
- ✅ CI/CD流程完整且稳定
- ✅ Docker一键启动成功

---

### Milestone 3: 用户体验（Week 9）

#### 验收清单

**1. 主题切换验收**
- [ ] 功能测试
  - [ ] 亮色主题显示正常
  - [ ] 暗色主题显示正常
  - [ ] 跟随系统主题正常
  - [ ] 主题切换无闪烁
- [ ] 持久化测试
  - [ ] 刷新页面主题保持
  - [ ] 重启应用主题保持

**2. 收藏功能验收**
- [ ] API测试
  ```bash
  # 添加收藏
  curl -X POST /api/favorites \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"content_id": "uuid", "content_type": "model"}'
  
  # 获取收藏列表
  curl /api/favorites?content_type=model
  
  # 取消收藏
  curl -X DELETE /api/favorites?content_id=uuid&content_type=model
  ```
- [ ] UI测试
  - [ ] 收藏按钮状态正确
  - [ ] 收藏列表正常展示
  - [ ] 取消收藏立即生效

**3. 分享功能验收**
- [ ] 功能测试
  - [ ] 分享按钮可点击
  - [ ] 系统分享面板弹出
  - [ ] 分享内容格式正确
- [ ] 统计测试
  - [ ] 分享操作被记录
  - [ ] 分享统计数据正确

**验收标准**:
- ✅ 所有功能正常工作
- ✅ 用户体验流畅
- ✅ 无明显bug

---

### Milestone 4: 性能优化（Week 12）

#### 验收清单

**1. Redis缓存验收**
- [ ] 功能测试
  - [ ] Redis连接正常
  - [ ] 缓存写入成功
  - [ ] 缓存读取成功
  - [ ] 缓存失效正常
- [ ] 性能测试
  ```bash
  # 使用k6进行压力测试
  k6 run --vus 100 --duration 30s performance-test.js
  # 验证缓存命中率 > 80%
  ```

**2. CDN配置验收**
- [ ] 配置测试
  - [ ] CDN域名解析正常
  - [ ] HTTPS证书有效
  - [ ] 回源配置正确
- [ ] 性能测试
  - [ ] 静态资源通过CDN加载
  - [ ] 首屏加载时间 < 2s
  - [ ] CDN命中率 > 90%

**3. 性能基准测试**
- [ ] API响应时间
  ```bash
  # 使用Apache Bench测试
  ab -n 1000 -c 100 https://api.dacong.com/models
  # 验证P95 < 500ms
  ```
- [ ] 页面加载时间
  ```bash
  # 使用Lighthouse测试
  lighthouse https://dacong.com --output json
  # 验证Performance Score > 90
  ```

**验收标准**:
- ✅ 缓存命中率 > 80%
- ✅ 首屏加载时间 < 2s
- ✅ API响应时间(P95) < 500ms

---

## 📊 工程2：社交互动系统验收

### Milestone 1: 评论系统（Week 2）

#### 验收清单

**1. 评论CRUD测试**
```bash
# 创建评论
curl -X POST /api/comments \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "content_id": "uuid",
    "content_type": "model",
    "content": "这个模型很不错！"
  }'

# 获取评论列表
curl /api/comments?content_id=uuid&content_type=model&sort=latest

# 删除评论
curl -X DELETE /api/comments/{id} \
  -H "Authorization: Bearer $TOKEN"
```

**2. 嵌套回复测试**
- [ ] 一级回复正常
- [ ] 二级回复正常
- [ ] 回复数统计正确
- [ ] 回复树展示正确

**3. 点赞功能测试**
- [ ] 点赞成功
- [ ] 取消点赞成功
- [ ] 点赞数统计正确
- [ ] 点赞状态正确

**4. Realtime订阅测试**
- [ ] 新评论实时推送
- [ ] 点赞实时更新
- [ ] 订阅延迟 < 100ms

**验收标准**:
- ✅ 所有API测试通过
- ✅ Realtime功能正常
- ✅ 性能指标达标

---

### Milestone 2: 关注系统（Week 4）

#### 验收清单

**1. 关注功能测试**
```bash
# 关注用户
curl -X POST /api/follows \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"following_id": "uuid"}'

# 取消关注
curl -X DELETE /api/follows/{following_id} \
  -H "Authorization: Bearer $TOKEN"

# 获取关注列表
curl /api/users/{user_id}/following

# 获取粉丝列表
curl /api/users/{user_id}/followers
```

**2. 动态流测试**
- [ ] 动态流正常展示
- [ ] 只显示关注用户的动态
- [ ] 动态按时间排序
- [ ] 分页功能正常

**3. 用户主页测试**
- [ ] 用户信息正确展示
- [ ] 关注/粉丝数正确
- [ ] 关注按钮状态正确

**验收标准**:
- ✅ 所有功能正常
- ✅ 数据统计准确
- ✅ 性能良好

---

### Milestone 3: 通知系统（Week 7）

#### 验收清单

**1. 站内通知测试**
- [ ] 评论通知正常
- [ ] 点赞通知正常
- [ ] 关注通知正常
- [ ] 回复通知正常
- [ ] 通知角标正确

**2. 推送通知测试**
- [ ] FCM推送配置正确
- [ ] 推送消息正常接收
- [ ] 推送延迟 < 5s
- [ ] 推送点击跳转正确

**3. 邮件通知测试**
- [ ] 邮件发送成功
- [ ] 邮件内容正确
- [ ] 邮件模板美观

**验收标准**:
- ✅ 所有通知类型正常
- ✅ 推送延迟达标
- ✅ 用户可配置通知设置

---

## 📊 工程3：AI增强系统验收

### Milestone 1: 推荐引擎（Week 3）

#### 验收清单

**1. 推荐准确率测试**
- [ ] 准备测试数据集（100个用户，1000个内容）
- [ ] 计算Precision@10
  ```python
  def precision_at_k(recommended, relevant, k=10):
      recommended_k = recommended[:k]
      hits = len(set(recommended_k) & set(relevant))
      return hits / k
  ```
- [ ] 计算Recall@10
- [ ] 验证准确率 > 60%

**2. 推荐多样性测试**
- [ ] 推荐结果不重复
- [ ] 推荐结果覆盖多个类别
- [ ] 推荐结果有新鲜内容

**3. 冷启动测试**
- [ ] 新用户推荐热门内容
- [ ] 新内容推荐给相关用户
- [ ] 冷启动推荐质量可接受

**4. 性能测试**
```bash
# 推荐接口压力测试
k6 run --vus 50 --duration 30s recommend-test.js
# 验证P95延迟 < 200ms
```

**验收标准**:
- ✅ 推荐准确率 > 60%
- ✅ 推荐延迟 < 200ms
- ✅ 冷启动策略有效

---

### Milestone 2: 智能搜索（Week 5）

#### 验收清单

**1. 语义搜索测试**
```bash
# 测试用例1: 同义词搜索
curl /api/search?q=大语言模型
# 应该返回包含"LLM"、"GPT"等相关内容

# 测试用例2: 模糊搜索
curl /api/search?q=图像生成
# 应该返回"图片生成"、"画图"等相关内容
```

**2. 搜索相关性测试**
- [ ] 准备测试查询（50个）
- [ ] 人工标注相关结果
- [ ] 计算NDCG@10
  ```python
  def ndcg_at_k(relevance_scores, k=10):
      dcg = sum(rel / log2(i + 2) for i, rel in enumerate(relevance_scores[:k]))
      idcg = sum(rel / log2(i + 2) for i, rel in enumerate(sorted(relevance_scores, reverse=True)[:k]))
      return dcg / idcg if idcg > 0 else 0
  ```
- [ ] 验证NDCG > 0.7

**3. 搜索性能测试**
```bash
k6 run --vus 30 --duration 30s search-test.js
# 验证P95延迟 < 500ms
```

**验收标准**:
- ✅ 搜索相关性 > 70%
- ✅ 搜索延迟 < 500ms
- ✅ 搜索建议功能正常

---

### Milestone 3: AI审核（Week 9）

#### 验收清单

**1. 内容审核准确率测试**
- [ ] 准备测试数据集（1000条评论）
  - 500条正常评论
  - 500条违规评论（广告、辱骂、色情等）
- [ ] 计算准确率
  ```python
  accuracy = (TP + TN) / (TP + TN + FP + FN)
  precision = TP / (TP + FP)
  recall = TP / (TP + FN)
  f1_score = 2 * (precision * recall) / (precision + recall)
  ```
- [ ] 验证准确率 > 90%

**2. 垃圾评论过滤测试**
- [ ] 广告评论识别
- [ ] 恶意链接识别
- [ ] 重复内容识别
- [ ] 误报率 < 5%

**3. 敏感信息识别测试**
- [ ] 手机号识别
- [ ] 邮箱识别
- [ ] 身份证号识别
- [ ] 银行卡号识别

**4. 审核性能测试**
```bash
k6 run --vus 20 --duration 30s moderation-test.js
# 验证P95延迟 < 1s
```

**验收标准**:
- ✅ 审核准确率 > 90%
- ✅ 审核延迟 < 1s
- ✅ 误报率 < 5%

---

### Milestone 4: 成本控制（Week 10）

#### 验收清单

**1. 成本监控**
- [ ] OpenAI API使用量统计
- [ ] 每日成本报告
- [ ] 成本告警配置

**2. 成本优化验证**
- [ ] 缓存命中率 > 80%
- [ ] 批处理任务正常运行
- [ ] 降级策略有效

**3. 月度成本验收**
- [ ] 统计实际月度成本
- [ ] 验证成本 < $500

**验收标准**:
- ✅ 成本监控完善
- ✅ 成本控制在预算内
- ✅ 优化策略有效

---

## 🔄 集成验收（所有工程完成后）

### 端到端用户流程测试

**流程1: 新用户注册到使用**
1. [ ] 用户注册
2. [ ] 邮箱验证
3. [ ] 选择兴趣标签
4. [ ] 浏览推荐内容
5. [ ] 搜索内容
6. [ ] 收藏内容
7. [ ] 发表评论
8. [ ] 关注用户
9. [ ] 接收通知

**流程2: 内容发布到审核**
1. [ ] 管理员发布内容
2. [ ] AI自动标签提取
3. [ ] AI质量评分
4. [ ] 内容推荐给用户
5. [ ] 用户互动（点赞、评论）
6. [ ] 评论AI审核
7. [ ] 违规内容人工复审

### 性能压力测试

```bash
# 模拟1000并发用户
k6 run --vus 1000 --duration 5m full-load-test.js

# 验收标准:
# - 系统稳定运行
# - 错误率 < 0.1%
# - P95响应时间 < 1s
```

### 安全渗透测试

- [ ] SQL注入测试
- [ ] XSS测试
- [ ] CSRF测试
- [ ] 权限绕过测试
- [ ] 敏感信息泄露测试

---

## 📝 验收报告模板

```markdown
# [工程名称] - [里程碑] 验收报告

## 基本信息
- 验收日期: YYYY-MM-DD
- 验收人: XXX
- 开发负责人: XXX

## 验收结果
- [ ] 通过
- [ ] 有条件通过（需修复问题）
- [ ] 不通过

## 测试结果

### 功能测试
| 测试项 | 结果 | 备注 |
|--------|------|------|
| XXX | ✅ | - |
| XXX | ❌ | 需修复 |

### 性能测试
| 指标 | 目标 | 实际 | 结果 |
|------|------|------|------|
| 响应时间 | <500ms | 450ms | ✅ |
| 吞吐量 | >100 QPS | 120 QPS | ✅ |

### 安全测试
| 测试项 | 结果 | 备注 |
|--------|------|------|
| SQL注入 | ✅ | 无漏洞 |
| XSS | ✅ | 无漏洞 |

## 问题清单
1. [P0] XXX问题描述
2. [P1] XXX问题描述

## 验收结论
XXX

## 签字
- 验收人: ___________  日期: ___________
- 开发负责人: ___________  日期: ___________
```

---

## ✅ 验收通过标准

### 必须满足（P0）
- ✅ 所有P0功能正常工作
- ✅ 无P0级别bug
- ✅ 安全测试通过
- ✅ 性能指标达标
- ✅ 文档完整

### 建议满足（P1）
- ✅ 所有P1功能正常工作
- ✅ 无P1级别bug
- ✅ 代码质量良好
- ✅ 测试覆盖率达标

---

**文档维护者**: Claude Code  
**最后更新**: 2026-04-20  
**状态**: 待执行
