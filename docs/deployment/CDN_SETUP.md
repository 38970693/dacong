# CDN 配置完整指南

## 概述

本文档提供 DaCong 项目 CDN 配置的完整指南，包括 CDN 选择、配置步骤、性能优化和成本分析。

## 目录

1. [CDN 选择建议](#cdn-选择建议)
2. [Cloudflare 配置](#cloudflare-配置)
3. [阿里云 CDN 配置](#阿里云-cdn-配置)
4. [AWS CloudFront 配置](#aws-cloudfront-配置)
5. [自建 CDN 配置](#自建-cdn-配置)
6. [性能优化建议](#性能优化建议)
7. [成本分析](#成本分析)
8. [故障排查](#故障排查)

---

## CDN 选择建议

### 1. Cloudflare（推荐）

**优势**：
- ✅ 免费套餐提供无限流量
- ✅ 全球 200+ 数据中心
- ✅ 自动 HTTPS 和 SSL 证书
- ✅ 内置 DDoS 防护和 WAF
- ✅ 配置简单，DNS 级别接入
- ✅ 支持 HTTP/3、Brotli 压缩
- ✅ 免费的图片优化（WebP 转换）

**劣势**：
- ❌ 中国大陆访问速度一般（未备案域名）
- ❌ 免费套餐功能有限（3 条页面规则）
- ❌ 缓存控制相对简单

**适用场景**：
- 国际化应用
- 预算有限的初创项目
- 需要快速上线的项目

**详细配置**：见 [CLOUDFLARE_SETUP.md](./CLOUDFLARE_SETUP.md)

---

### 2. 阿里云 CDN

**优势**：
- ✅ 中国大陆访问速度快
- ✅ 与阿里云生态集成良好
- ✅ 支持精细化缓存控制
- ✅ 提供详细的监控和日志
- ✅ 支持 HTTPS 和 HTTP/2

**劣势**：
- ❌ 按流量或带宽计费
- ❌ 需要域名备案（中国大陆）
- ❌ 配置相对复杂
- ❌ 国际节点覆盖不如 Cloudflare

**适用场景**：
- 主要面向中国大陆用户
- 已有阿里云基础设施
- 需要精细化 CDN 控制

**成本估算**：
- 流量计费：¥0.24/GB（中国大陆）
- 带宽计费：¥0.53/Mbps/天
- HTTPS 请求：¥0.05/万次

---

### 3. AWS CloudFront

**优势**：
- ✅ 全球节点覆盖广泛
- ✅ 与 AWS 生态深度集成
- ✅ 支持 Lambda@Edge（边缘计算）
- ✅ 高级缓存策略和行为配置
- ✅ 企业级 SLA 保障

**劣势**：
- ❌ 配置复杂度高
- ❌ 成本相对较高
- ❌ 学习曲线陡峭

**适用场景**：
- 已使用 AWS 基础设施
- 需要边缘计算能力
- 企业级应用

**成本估算**：
- 数据传输：$0.085/GB（美国）
- HTTPS 请求：$0.01/万次
- 免费额度：50GB 流量/月（首年）

---

### 4. 自建 CDN

**优势**：
- ✅ 完全控制
- ✅ 无第三方依赖
- ✅ 可定制化

**劣势**：
- ❌ 需要自己维护服务器
- ❌ 节点覆盖有限
- ❌ 运维成本高
- ❌ 无内置安全防护

**适用场景**：
- 特殊合规要求
- 已有多地域服务器
- 技术团队成熟

---

## Cloudflare 配置

详细配置步骤请参考：[CLOUDFLARE_SETUP.md](./CLOUDFLARE_SETUP.md)

**快速配置清单**：

1. ✅ 注册 Cloudflare 账号
2. ✅ 添加站点并修改 DNS
3. ✅ 配置 SSL/TLS（Full Strict 模式）
4. ✅ 设置缓存规则（静态资源长缓存）
5. ✅ 启用性能优化（Brotli、HTTP/3）
6. ✅ 配置安全规则（WAF、Bot 防护）
7. ✅ 获取 API 凭证用于缓存刷新

---

## 阿里云 CDN 配置

### 1. 开通 CDN 服务

1. 登录阿里云控制台
2. 搜索 "CDN"，开通服务
3. 完成实名认证和域名备案

### 2. 添加加速域名

1. 进入 CDN 控制台
2. 点击 "添加域名"
3. 配置：
   ```
   加速域名：cdn.dacong.ai
   业务类型：图片小文件
   源站信息：
     - 类型：源站域名
     - 域名：dacong.ai
     - 端口：443
     - 协议：HTTPS
   加速区域：全球（含中国大陆）
   ```

### 3. 配置 CNAME

1. 获取 CDN 分配的 CNAME 地址（如 `cdn.dacong.ai.w.kunlunsl.com`）
2. 在 DNS 服务商添加 CNAME 记录：
   ```
   类型：CNAME
   主机记录：cdn
   记录值：cdn.dacong.ai.w.kunlunsl.com
   TTL：10 分钟
   ```

### 4. 配置缓存规则

进入域名管理 → 缓存配置：

```
路径：/images/*
缓存时间：30 天
状态码缓存：200, 206, 301, 302, 304

路径：/assets/*
缓存时间：1 年
状态码缓存：200, 206, 301, 302, 304

路径：/api/*
缓存时间：不缓存
```

### 5. 配置 HTTPS

1. 上传 SSL 证书或使用免费证书
2. 启用 HTTPS 安全加速
3. 强制 HTTPS 跳转

### 6. 性能优化

- ✅ 启用 Gzip 压缩
- ✅ 启用 Brotli 压缩
- ✅ 启用 HTTP/2
- ✅ 启用智能压缩
- ✅ 启用页面优化

### 7. 缓存刷新

**通过控制台**：
1. 进入 CDN 控制台
2. 刷新缓存 → 提交刷新任务
3. 选择刷新类型（URL 刷新或目录刷新）

**通过 API**：
```bash
#!/bin/bash
# 阿里云 CDN 缓存刷新脚本

aliyun cdn RefreshObjectCaches \
  --ObjectPath "https://cdn.dacong.ai/images/logo.png" \
  --ObjectType "File"
```

---

## AWS CloudFront 配置

### 1. 创建 S3 存储桶

```bash
aws s3 mb s3://dacong-cdn --region us-east-1
```

### 2. 上传静态资源

```bash
aws s3 sync ./public s3://dacong-cdn/
```

### 3. 创建 CloudFront 分发

```bash
aws cloudfront create-distribution \
  --origin-domain-name dacong-cdn.s3.amazonaws.com \
  --default-root-object index.html
```

### 4. 配置缓存行为

```json
{
  "PathPattern": "/images/*",
  "TargetOriginId": "S3-dacong-cdn",
  "ViewerProtocolPolicy": "redirect-to-https",
  "AllowedMethods": ["GET", "HEAD"],
  "CachedMethods": ["GET", "HEAD"],
  "Compress": true,
  "DefaultTTL": 2592000,
  "MaxTTL": 31536000,
  "MinTTL": 0
}
```

### 5. 配置自定义域名

1. 申请 SSL 证书（AWS Certificate Manager）
2. 添加 CNAME 记录
3. 关联证书到 CloudFront 分发

### 6. 缓存刷新

```bash
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/images/*" "/*.css" "/*.js"
```

---

## 自建 CDN 配置

### 1. 服务器准备

准备多个地域的服务器：
- 北京（中国北方）
- 上海（中国东部）
- 深圳（中国南方）
- 新加坡（东南亚）
- 东京（日本）
- 法兰克福（欧洲）
- 弗吉尼亚（美国东部）

### 2. Nginx 配置

使用项目根目录的 `nginx-cdn.conf` 配置文件。

### 3. 同步静态资源

使用 rsync 同步资源到各节点：

```bash
#!/bin/bash
# 同步脚本

SERVERS=(
  "user@beijing.dacong.ai"
  "user@shanghai.dacong.ai"
  "user@shenzhen.dacong.ai"
  "user@singapore.dacong.ai"
)

for server in "${SERVERS[@]}"; do
  echo "同步到 $server..."
  rsync -avz --delete ./public/ $server:/var/www/cdn/
done
```

### 4. DNS 智能解析

使用 DNS 服务商的智能解析功能：

```
cdn.dacong.ai
  - 中国联通 → beijing.dacong.ai
  - 中国电信 → shanghai.dacong.ai
  - 中国移动 → shenzhen.dacong.ai
  - 海外 → singapore.dacong.ai
```

### 5. 健康检查

```bash
#!/bin/bash
# 健康检查脚本

SERVERS=(
  "https://beijing.dacong.ai/health"
  "https://shanghai.dacong.ai/health"
)

for url in "${SERVERS[@]}"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [ "$status" != "200" ]; then
    echo "警告：$url 不可用（状态码：$status）"
    # 发送告警
  fi
done
```

---

## 性能优化建议

### 1. 资源版本化

**使用文件哈希**：
```dart
// 构建时生成哈希
const String appCss = '/assets/app.abc123.css';
const String appJs = '/assets/app.def456.js';
```

**使用版本号**：
```dart
const String version = '1.2.3';
const String appCss = '/assets/app.css?v=$version';
```

### 2. 图片优化

**使用 WebP 格式**：
```dart
String imageUrl = CdnConfig.getImageUrl(
  'images/hero.jpg',
  useWebP: true,
  quality: 85,
);
```

**响应式图片**：
```dart
String srcSet = CdnConfig.getResponsiveImageSrcSet(
  'images/hero.jpg',
  [320, 640, 1024, 1920],
);
```

### 3. 预加载关键资源

```html
<!-- 在 index.html 中添加 -->
<link rel="preload" href="https://cdn.dacong.ai/assets/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preconnect" href="https://cdn.dacong.ai">
<link rel="dns-prefetch" href="https://cdn.dacong.ai">
```

### 4. 缓存策略

| 资源类型 | Edge TTL | Browser TTL | 说明 |
|---------|----------|-------------|------|
| 图片 | 30 天 | 30 天 | 不常变化 |
| CSS/JS | 1 年 | 1 年 | 使用版本化 URL |
| 字体 | 1 年 | 1 年 | 几乎不变 |
| HTML | 4 小时 | 0 | 需要及时更新 |
| API | 不缓存 | 不缓存 | 动态内容 |

### 5. 压缩优化

**启用 Brotli**：
- 比 Gzip 压缩率高 15-25%
- 所有现代浏览器支持

**压缩级别**：
- 静态资源：最高压缩级别（11）
- 动态内容：中等压缩级别（4-6）

### 6. HTTP/3 和 QUIC

- 减少连接建立时间
- 改善弱网环境性能
- Cloudflare 免费支持

---

## 成本分析

### Cloudflare（推荐）

**Free 计划**：
- 费用：$0/月
- 流量：无限
- 请求：无限
- 页面规则：3 条
- DDoS 防护：✅
- SSL 证书：✅

**Pro 计划**：
- 费用：$20/月
- 页面规则：20 条
- 图片优化：✅
- 移动端优化：✅
- 高级分析：✅

**升级建议**：
- 流量 < 1TB/月：使用 Free 计划
- 流量 > 1TB/月 或需要高级功能：升级 Pro

---

### 阿里云 CDN

**流量计费**（按量付费）：
```
月流量 0-10TB：    ¥0.24/GB
月流量 10-50TB：   ¥0.23/GB
月流量 50-100TB：  ¥0.21/GB
月流量 > 100TB：   ¥0.18/GB
```

**带宽计费**（按峰值带宽）：
```
带宽 0-500Mbps：   ¥0.53/Mbps/天
带宽 500-5000Mbps：¥0.52/Mbps/天
带宽 > 5000Mbps：  ¥0.49/Mbps/天
```

**成本估算示例**：
- 日均流量 100GB：¥24/天 = ¥720/月
- 峰值带宽 50Mbps：¥26.5/天 = ¥795/月

---

### AWS CloudFront

**数据传输费用**：
```
美国/欧洲：
  0-10TB：    $0.085/GB
  10-50TB：   $0.080/GB
  50-150TB：  $0.060/GB
  > 150TB：   $0.050/GB

亚太地区：
  0-10TB：    $0.140/GB
  10-50TB：   $0.135/GB
  > 50TB：    $0.120/GB
```

**请求费用**：
```
HTTPS 请求：$0.01/万次
HTTP 请求： $0.0075/万次
```

**免费额度**（首年）：
- 50GB 数据传输/月
- 200 万次 HTTP/HTTPS 请求/月

---

### 自建 CDN

**服务器成本**（每节点）：
```
云服务器（2核4G）：¥100-200/月
带宽（10Mbps）：   ¥50-100/月
存储（100GB SSD）：¥20-30/月

单节点总成本：     ¥170-330/月
5 节点总成本：     ¥850-1650/月
```

**运维成本**：
- 人力成本：1 人 × ¥15,000/月
- 监控工具：¥500/月
- 总成本：¥16,350-17,150/月

**结论**：自建 CDN 成本高，不推荐小团队使用。

---

## 故障排查

### 1. 缓存未命中

**症状**：`CF-Cache-Status: MISS` 或缓存命中率低

**排查步骤**：
1. 检查源站响应头：
   ```bash
   curl -I https://dacong.ai/images/logo.png
   # 查看 Cache-Control 头
   ```

2. 检查 CDN 缓存规则配置

3. 检查 URL 是否包含查询参数（会影响缓存）

**解决方案**：
- 设置正确的 `Cache-Control` 响应头
- 使用页面规则强制缓存
- 移除不必要的查询参数

---

### 2. 内容更新不及时

**症状**：更新文件后，用户仍看到旧内容

**排查步骤**：
1. 检查浏览器缓存（Ctrl+Shift+R 强制刷新）
2. 检查 CDN 缓存状态
3. 检查缓存 TTL 设置

**解决方案**：
- 使用版本化 URL（推荐）
- 手动刷新 CDN 缓存
- 减少 Browser Cache TTL

---

### 3. HTTPS 证书错误

**症状**：浏览器显示证书无效

**排查步骤**：
1. 检查 SSL/TLS 模式配置
2. 检查源站证书是否有效
3. 检查证书域名是否匹配

**解决方案**：
- 使用 Full (strict) 模式
- 更新源站证书
- 使用 Cloudflare Origin CA 证书

---

### 4. 502/504 错误

**症状**：间歇性出现 502 或 504 错误

**排查步骤**：
1. 检查源站服务器状态
2. 检查源站响应时间
3. 检查防火墙规则

**解决方案**：
- 优化源站性能
- 增加源站超时时间
- 允许 CDN IP 访问源站

---

### 5. 跨域问题

**症状**：浏览器控制台显示 CORS 错误

**排查步骤**：
1. 检查响应头中的 CORS 配置
2. 检查请求方法和头部

**解决方案**：
在源站 Nginx 配置中添加：
```nginx
add_header Access-Control-Allow-Origin "*" always;
add_header Access-Control-Allow-Methods "GET, HEAD, OPTIONS" always;
```

---

## 监控指标

### 关键指标

1. **缓存命中率**：目标 > 80%
2. **TTFB**：目标 < 200ms
3. **带宽节省**：目标 > 50%
4. **错误率**：目标 < 0.1%
5. **可用性**：目标 > 99.9%

### 监控工具

- Cloudflare Analytics（内置）
- Google Analytics（用户体验）
- Sentry（错误监控）
- Prometheus + Grafana（自建监控）

---

## 相关文档

- [Cloudflare 配置详解](./CLOUDFLARE_SETUP.md)
- [域名与 SSL 配置](./DOMAIN_SSL_SETUP.md)
- [生产环境部署](./PRODUCTION_DEPLOYMENT.md)
- [性能监控](./MONITORING_SETUP.md)

---

## 总结

### 推荐方案

**初创项目/国际化应用**：
- 使用 Cloudflare Free 计划
- 成本：$0/月
- 配置简单，快速上线

**中国大陆为主的应用**：
- 使用阿里云 CDN
- 成本：¥500-1000/月（中小流量）
- 需要域名备案

**企业级应用**：
- 使用 AWS CloudFront
- 成本：根据流量计算
- 与 AWS 生态集成

### 下一步

1. 根据业务需求选择 CDN 方案
2. 按照对应文档完成配置
3. 配置监控和告警
4. 定期检查性能指标
5. 根据数据优化配置

---

**文档维护**：本文档应随着 CDN 配置变化及时更新。
