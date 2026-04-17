# Cloudflare CDN 配置指南

## 概述

本文档详细说明如何使用 Cloudflare 为 DaCong 项目配置 CDN 加速，优化全球访问速度和静态资源加载性能。

## 为什么选择 Cloudflare

- **免费套餐**：提供无限流量的免费 CDN
- **全球节点**：200+ 数据中心覆盖全球
- **自动 HTTPS**：免费 SSL 证书和自动续期
- **DDoS 防护**：内置安全防护
- **易于配置**：DNS 级别接入，无需修改代码
- **性能优化**：Brotli 压缩、HTTP/3、Early Hints

## 前置要求

- 拥有域名（如 `dacong.ai`）
- Cloudflare 账号（免费注册：https://dash.cloudflare.com/sign-up）
- 域名管理权限（修改 DNS 服务器）
- 服务器已部署并可访问

## 步骤 1：域名接入 Cloudflare

### 1.1 添加站点

1. 登录 Cloudflare Dashboard
2. 点击 "Add a Site"
3. 输入域名：`dacong.ai`
4. 选择 "Free" 套餐
5. 点击 "Continue"

### 1.2 DNS 记录导入

Cloudflare 会自动扫描现有 DNS 记录，确认以下记录：

```
Type    Name              Content                 Proxy Status
A       dacong.ai         <your-server-ip>        Proxied (橙色云朵)
A       www               <your-server-ip>        Proxied
A       api               <api-server-ip>         Proxied
CNAME   cdn               dacong.ai               Proxied
```

**重要**：确保 "Proxy Status" 为 "Proxied"（橙色云朵图标），这样流量才会经过 Cloudflare CDN。

### 1.3 修改域名服务器

1. 复制 Cloudflare 提供的 Nameservers（如 `ns1.cloudflare.com`）
2. 登录域名注册商（阿里云/GoDaddy/Namecheap 等）
3. 修改域名的 DNS 服务器为 Cloudflare 提供的地址
4. 等待 DNS 生效（通常 5 分钟 - 24 小时）

### 1.4 验证接入

```bash
# 检查 DNS 是否指向 Cloudflare
dig dacong.ai +short

# 检查 Cloudflare 是否生效
curl -I https://dacong.ai | grep -i cf-ray
# 如果看到 cf-ray 响应头，说明已经通过 Cloudflare
```

## 步骤 2：SSL/TLS 配置

### 2.1 SSL/TLS 加密模式

导航到：**SSL/TLS** → **Overview**

选择加密模式：

- **Full (strict)**（推荐）：Cloudflare 与源服务器之间使用有效证书加密
- **Full**：加密但不验证证书
- **Flexible**：仅客户端到 Cloudflare 加密（不推荐）

```
客户端 --[HTTPS]--> Cloudflare --[HTTPS]--> 源服务器
```

### 2.2 自动 HTTPS 重写

导航到：**SSL/TLS** → **Edge Certificates**

启用以下选项：
- ✅ Always Use HTTPS
- ✅ Automatic HTTPS Rewrites
- ✅ Minimum TLS Version: TLS 1.2

### 2.3 HSTS 配置

导航到：**SSL/TLS** → **Edge Certificates** → **HTTP Strict Transport Security (HSTS)**

配置：
```
Status: Enabled
Max Age: 6 months (15768000 seconds)
Include Subdomains: Yes
Preload: Yes (可选，需要提交到浏览器预加载列表)
```

## 步骤 3：缓存规则配置

### 3.1 浏览器缓存 TTL

导航到：**Caching** → **Configuration**

设置：
- **Browser Cache TTL**: 4 hours（对于频繁更新的内容）
- **Crawler Hints**: On

### 3.2 缓存级别

导航到：**Caching** → **Configuration** → **Caching Level**

选择：**Standard**（缓存静态资源）

### 3.3 自定义缓存规则

导航到：**Rules** → **Page Rules**（免费套餐 3 条规则）

#### 规则 1：静态资源长缓存

```
URL Pattern: *dacong.ai/*.{jpg,jpeg,png,gif,webp,svg,css,js,woff,woff2,ttf,eot}

Settings:
- Cache Level: Cache Everything
- Edge Cache TTL: 1 month
- Browser Cache TTL: 1 month
```

#### 规则 2：API 不缓存

```
URL Pattern: *api.dacong.ai/*

Settings:
- Cache Level: Bypass
```

#### 规则 3：HTML 短缓存

```
URL Pattern: *dacong.ai/*.html

Settings:
- Cache Level: Cache Everything
- Edge Cache TTL: 2 hours
- Browser Cache TTL: 30 minutes
```

### 3.4 使用 Cache Rules（推荐，新版功能）

导航到：**Caching** → **Cache Rules**

创建规则：

```yaml
# 静态资源缓存
Rule Name: Static Assets Cache
When incoming requests match:
  - URI Path matches regex: \.(jpg|jpeg|png|gif|webp|svg|css|js|woff2?|ttf|eot|ico)$
Then:
  - Cache eligibility: Eligible for cache
  - Edge TTL: 30 days
  - Browser TTL: 7 days
```

```yaml
# Flutter Web 构建产物
Rule Name: Flutter Build Cache
When incoming requests match:
  - URI Path starts with: /flutter_service_worker.js
  - OR URI Path starts with: /main.dart.js
  - OR URI Path starts with: /assets/
Then:
  - Cache eligibility: Eligible for cache
  - Edge TTL: 1 hour (构建后需要快速更新)
  - Browser TTL: 30 minutes
```

## 步骤 4：性能优化

### 4.1 Auto Minify

导航到：**Speed** → **Optimization**

启用：
- ✅ JavaScript
- ✅ CSS
- ✅ HTML

### 4.2 Brotli 压缩

导航到：**Speed** → **Optimization**

启用：
- ✅ Brotli

### 4.3 Early Hints

导航到：**Speed** → **Optimization**

启用：
- ✅ Early Hints（HTTP 103，提前加载关键资源）

### 4.4 Rocket Loader（可选）

导航到：**Speed** → **Optimization**

⚠️ **注意**：Rocket Loader 可能与 Flutter Web 冲突，建议先测试。

## 步骤 5：安全配置

### 5.1 防火墙规则

导航到：**Security** → **WAF**

启用：
- ✅ OWASP Core Ruleset
- ✅ Cloudflare Managed Ruleset

### 5.2 Bot 防护

导航到：**Security** → **Bots**

配置：
- Bot Fight Mode: On（免费套餐）

### 5.3 Rate Limiting（付费功能）

如果使用付费套餐，可配置：

```
Rule: API Rate Limit
If: Hostname equals api.dacong.ai
Then: Rate limit 100 requests per minute per IP
```

## 步骤 6：监控与分析

### 6.1 Analytics

导航到：**Analytics & Logs** → **Traffic**

查看：
- 请求数
- 带宽使用
- 缓存命中率（目标 > 80%）
- 响应时间

### 6.2 缓存分析

导航到：**Caching** → **Analytics**

监控：
- Cache Hit Ratio（缓存命中率）
- Bandwidth Saved（节省的带宽）

### 6.3 设置告警

导航到：**Notifications**

配置告警：
- ✅ SSL Certificate Expiration
- ✅ DDoS Attack
- ✅ Origin Error Rate Increase

## 步骤 7：CDN 缓存刷新

### 7.1 手动刷新

Dashboard 操作：
1. 导航到：**Caching** → **Configuration**
2. 点击 "Purge Cache"
3. 选择：
   - **Purge Everything**：清除所有缓存
   - **Custom Purge**：按 URL 或标签清除

### 7.2 获取 API 凭证

#### 获取 Zone ID

1. 登录 Cloudflare Dashboard
2. 选择你的站点（dacong.ai）
3. 在右侧边栏找到 "Zone ID"
4. 点击复制按钮

#### 创建 API Token

1. 导航到：**Profile** → **API Tokens**
2. 点击 "Create Token"
3. 点击 "Create Custom Token"
4. 配置权限：
   ```
   Token Name: DaCong CDN Cache Purge
   
   Permissions:
     - Zone > Cache Purge > Purge
     - Zone > Zone > Read
   
   Zone Resources:
     - Include > Specific zone > dacong.ai
   
   Client IP Address Filtering: (可选，限制 IP)
   TTL: (可选，设置过期时间)
   ```
5. 点击 "Continue to summary"
6. 点击 "Create Token"
7. **重要**：复制 Token 并安全保存（只显示一次）

#### 配置环境变量

在项目根目录的 `.env` 文件中添加：

```bash
# Cloudflare CDN 配置
CDN_URL=https://cdn.dacong.ai
CLOUDFLARE_ZONE_ID=your-zone-id-here
CLOUDFLARE_API_TOKEN=your-api-token-here
```

### 7.3 API 刷新

使用脚本自动刷新（见 `scripts/purge_cdn_cache.sh`）：

```bash
# 刷新所有缓存
./scripts/purge_cdn_cache.sh

# 刷新特定文件
./scripts/purge_cdn_cache.sh --files "https://cdn.dacong.ai/images/logo.png"

# 刷新特定路径
./scripts/purge_cdn_cache.sh --prefix "/images/"
```

## 步骤 8：验证 CDN 生效

### 8.1 检查响应头

```bash
curl -I https://dacong.ai

# 应该看到以下响应头：
# cf-cache-status: HIT (缓存命中) 或 MISS (缓存未命中)
# cf-ray: <ray-id>
# server: cloudflare
```

### 8.2 测试全球访问速度

使用工具：
- https://www.dotcom-tools.com/website-speed-test.aspx
- https://tools.pingdom.com/
- https://www.webpagetest.org/

目标：
- 首屏加载时间 < 2 秒
- TTFB (Time to First Byte) < 200ms

### 8.3 检查缓存命中率

```bash
# 第一次请求（MISS）
curl -I https://dacong.ai/assets/logo.png | grep cf-cache-status

# 第二次请求（HIT）
curl -I https://dacong.ai/assets/logo.png | grep cf-cache-status
```

## 常见问题

### Q1: 缓存命中率低怎么办？

**原因**：
- 动态内容过多
- Cache-Control 响应头设置不当
- 查询参数导致缓存失效

**解决**：
1. 检查源服务器响应头：`Cache-Control: public, max-age=31536000`
2. 使用 Page Rules 强制缓存
3. 移除不必要的查询参数

### Q2: 更新后内容不刷新？

**解决**：
1. 使用版本化 URL：`/assets/app.js?v=1.2.3`
2. 使用文件哈希：`/assets/app.abc123.js`
3. 手动刷新缓存：Dashboard → Purge Cache

### Q3: API 响应被缓存了？

**解决**：
1. 确保 API 响应头包含：`Cache-Control: no-cache, no-store, must-revalidate`
2. 创建 Page Rule 绕过 API 缓存
3. 使用不同的子域名（如 `api.dacong.ai`）

### Q4: HTTPS 证书错误？

**解决**：
1. 检查 SSL/TLS 模式是否为 "Full (strict)"
2. 确保源服务器有有效的 SSL 证书
3. 等待 Cloudflare 证书生效（最多 24 小时）

## 最佳实践

### 1. 静态资源版本化

```dart
// 使用文件哈希
const String appJsUrl = '/assets/app.abc123.js';

// 或使用版本号
const String appVersion = '1.2.3';
const String appJsUrl = '/assets/app.js?v=$appVersion';
```

### 2. 关键资源预加载

```html
<!-- 在 index.html 中添加 -->
<link rel="preload" href="/assets/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preconnect" href="https://cdn.dacong.ai">
```

### 3. 响应头优化

源服务器配置：

```nginx
# Nginx 配置
location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

### 4. 监控缓存性能

定期检查：
- 缓存命中率 > 80%
- 带宽节省 > 50%
- TTFB < 200ms

## 成本估算

### 免费套餐限制

- ✅ 无限流量
- ✅ 无限请求
- ✅ 3 条 Page Rules
- ✅ 基础 DDoS 防护
- ❌ 无 Image Optimization
- ❌ 无高级 Rate Limiting

### 升级建议

如果需要以下功能，考虑升级到 Pro ($20/月)：
- Image Optimization（自动 WebP 转换）
- 更多 Page Rules（20 条）
- 高级分析
- 移动端优化

## 相关文档

- [CDN 配置总览](./CDN_SETUP.md)
- [域名与 SSL 配置](./DOMAIN_SSL_SETUP.md)
- [生产环境部署](./PRODUCTION_DEPLOYMENT.md)
- [性能监控](./MONITORING_SETUP.md)

## 支持

- Cloudflare 文档：https://developers.cloudflare.com/
- Cloudflare 社区：https://community.cloudflare.com/
- 项目 Issue：https://github.com/your-org/dacong/issues
