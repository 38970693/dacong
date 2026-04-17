# 域名和 SSL 配置指南

## 概述

本文档说明如何配置域名、DNS 记录和 SSL 证书，确保应用可以通过 HTTPS 安全访问。

---

## 1. 域名购买

### 1.1 推荐域名注册商

| 注册商 | 优势 | 价格 |
|--------|------|------|
| Cloudflare | 成本价，免费 DNS，免费 SSL | ~$10/年 |
| Namecheap | 价格实惠，界面友好 | ~$12/年 |
| GoDaddy | 知名度高，支持多 | ~$15/年 |
| 阿里云 | 国内访问快，支持备案 | ~¥60/年 |

### 1.2 域名选择建议

**推荐后缀**：
- `.com` - 最通用，国际化
- `.cn` - 中国用户，需要备案
- `.io` - 科技感，开发者友好
- `.app` - 移动应用

**命名建议**：
- 简短易记（< 15 字符）
- 避免数字和连字符
- 易于拼写和发音
- 与品牌一致

### 1.3 购买流程

以 Cloudflare 为例：

1. 访问 https://www.cloudflare.com/products/registrar/
2. 搜索域名可用性
3. 添加到购物车
4. 完成支付
5. 验证邮箱

---

## 2. DNS 配置

### 2.1 使用 Cloudflare DNS（推荐）

**优势**：
- 免费 CDN
- 免费 SSL 证书
- DDoS 防护
- 全球 Anycast 网络
- 快速 DNS 解析

### 2.2 迁移到 Cloudflare

如果域名在其他注册商：

1. 登录 Cloudflare Dashboard
2. 点击 "Add a Site"
3. 输入域名
4. 选择 Free Plan
5. Cloudflare 会扫描现有 DNS 记录
6. 复制 Cloudflare 提供的 Nameservers：
   ```
   ns1.cloudflare.com
   ns2.cloudflare.com
   ```
7. 在原注册商处更新 Nameservers
8. 等待 DNS 传播（最多 24 小时）

### 2.3 配置 DNS 记录

访问 Cloudflare Dashboard > DNS > Records

**添加以下记录**：

```
类型    名称        内容                          TTL    代理状态
A       @           your-vps-ip                   Auto   已代理（橙色云朵）
A       www         your-vps-ip                   Auto   已代理
CNAME   api         your-project.supabase.co      Auto   仅 DNS（灰色云朵）
CNAME   app         your-vercel-app.vercel.app    Auto   已代理
TXT     @           "v=spf1 include:_spf.mx.cloudflare.net ~all"  Auto  -
```

**记录说明**：

| 记录 | 用途 | 示例 |
|------|------|------|
| `@` | 根域名 | `dacong.com` |
| `www` | WWW 子域名 | `www.dacong.com` |
| `api` | API 端点 | `api.dacong.com` |
| `app` | 前端应用 | `app.dacong.com` |

**代理状态说明**：
- **已代理（橙色云朵）**：流量通过 Cloudflare，启用 CDN 和安全功能
- **仅 DNS（灰色云朵）**：直接解析到目标，不经过 Cloudflare

### 2.4 验证 DNS 配置

```bash
# 检查 A 记录
dig dacong.com A +short
dig www.dacong.com A +short

# 检查 CNAME 记录
dig api.dacong.com CNAME +short
dig app.dacong.com CNAME +short

# 检查 DNS 传播状态
# 访问 https://www.whatsmydns.net/
```

---

## 3. SSL 证书配置

### 3.1 Cloudflare SSL（推荐）

Cloudflare 提供免费的 SSL 证书，自动续期。

#### 配置步骤

1. 访问 Cloudflare Dashboard > SSL/TLS
2. 选择加密模式：**Full (strict)**
   - Off: 不加密（不推荐）
   - Flexible: 浏览器到 Cloudflare 加密，Cloudflare 到源服务器不加密
   - Full: 全程加密，但不验证源服务器证书
   - **Full (strict)**: 全程加密，验证源服务器证书（推荐）

3. 启用以下选项：
   - Always Use HTTPS: 强制 HTTPS
   - Automatic HTTPS Rewrites: 自动重写 HTTP 链接
   - Minimum TLS Version: TLS 1.2
   - Opportunistic Encryption: 启用
   - TLS 1.3: 启用

#### 配置 Edge Certificates

访问 SSL/TLS > Edge Certificates

- Always Use HTTPS: **开启**
- HTTP Strict Transport Security (HSTS): **开启**
  - Max Age: 6 months
  - Include subdomains: 开启
  - Preload: 开启
- Minimum TLS Version: **TLS 1.2**
- Opportunistic Encryption: **开启**
- TLS 1.3: **开启**
- Automatic HTTPS Rewrites: **开启**

### 3.2 Let's Encrypt（自托管）

如果不使用 Cloudflare，可以使用 Let's Encrypt 免费证书。

#### 安装 Certbot

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install certbot python3-certbot-nginx
```

#### 获取证书

```bash
# 为 Nginx 自动配置 SSL
sudo certbot --nginx -d dacong.com -d www.dacong.com

# 或手动获取证书
sudo certbot certonly --standalone -d dacong.com -d www.dacong.com
```

#### 自动续期

```bash
# 测试续期
sudo certbot renew --dry-run

# 配置自动续期（cron）
sudo crontab -e

# 添加以下行（每天凌晨 2 点检查续期）
0 2 * * * certbot renew --quiet --post-hook "systemctl reload nginx"
```

#### Nginx SSL 配置

```nginx
server {
    listen 80;
    server_name dacong.com www.dacong.com;
    
    # 强制跳转到 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name dacong.com www.dacong.com;
    
    # SSL 证书
    ssl_certificate /etc/letsencrypt/live/dacong.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dacong.com/privkey.pem;
    
    # SSL 配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # 其他安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # 网站根目录
    root /var/www/dacong;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 3.3 验证 SSL 配置

```bash
# 检查证书有效性
openssl s_client -connect dacong.com:443 -servername dacong.com < /dev/null 2>/dev/null | openssl x509 -noout -dates

# 检查 SSL 评分
# 访问 https://www.ssllabs.com/ssltest/analyze.html?d=dacong.com
```

**目标评分**：A+ 或 A

---

## 4. HTTPS 强制跳转

### 4.1 Cloudflare 配置

访问 SSL/TLS > Edge Certificates

- **Always Use HTTPS**: 开启

### 4.2 Nginx 配置

```nginx
server {
    listen 80;
    server_name dacong.com www.dacong.com;
    return 301 https://$server_name$request_uri;
}
```

### 4.3 应用层配置

**前端（Flutter）**：
```dart
// 确保所有 API 请求使用 HTTPS
const supabaseUrl = 'https://your-project.supabase.co';
```

**后端（Supabase）**：
Supabase 默认强制 HTTPS，无需额外配置。

---

## 5. CDN 配置

### 5.1 Cloudflare CDN

**自动启用**：DNS 记录设置为"已代理"（橙色云朵）时自动启用 CDN。

#### 优化配置

访问 Cloudflare Dashboard > Speed

**启用以下功能**：

1. **Auto Minify**
   - JavaScript: 开启
   - CSS: 开启
   - HTML: 开启

2. **Brotli**
   - 开启（比 gzip 压缩率更高）

3. **Rocket Loader**
   - 开启（异步加载 JavaScript）

4. **Mirage**
   - 开启（图片优化）

5. **Polish**
   - Lossless（无损压缩）
   - WebP（现代图片格式）

#### 缓存规则

访问 Caching > Configuration

**Browser Cache TTL**: 4 hours
**Crawler Hints**: 开启

**创建页面规则**（Page Rules）：

```
规则 1: 静态资源缓存
URL: *dacong.com/*.{jpg,jpeg,png,gif,ico,css,js,woff,woff2,ttf,svg}
设置:
  - Cache Level: Cache Everything
  - Edge Cache TTL: 1 month
  - Browser Cache TTL: 1 month

规则 2: API 不缓存
URL: api.dacong.com/*
设置:
  - Cache Level: Bypass

规则 3: HTML 短缓存
URL: *dacong.com/*.html
设置:
  - Cache Level: Cache Everything
  - Edge Cache TTL: 2 hours
  - Browser Cache TTL: 2 hours
```

### 5.2 验证 CDN

```bash
# 检查响应头
curl -I https://dacong.com

# 查找以下头部：
# cf-cache-status: HIT  (缓存命中)
# cf-ray: xxxxx  (Cloudflare Ray ID)
# server: cloudflare
```

---

## 6. 安全配置

### 6.1 Cloudflare 安全设置

访问 Security > Settings

**推荐配置**：

1. **Security Level**: Medium
2. **Challenge Passage**: 30 minutes
3. **Browser Integrity Check**: 开启
4. **Privacy Pass Support**: 开启

### 6.2 防火墙规则

访问 Security > WAF

**创建规则**：

```
规则 1: 阻止恶意 User-Agent
表达式: (http.user_agent contains "bot" and not http.user_agent contains "Googlebot")
操作: Block

规则 2: 限制 API 请求频率
表达式: (http.host eq "api.dacong.com")
操作: Rate Limit (100 requests per minute)

规则 3: 地理位置限制（可选）
表达式: (ip.geoip.country ne "CN" and ip.geoip.country ne "US")
操作: Challenge
```

### 6.3 DDoS 防护

Cloudflare 自动提供 DDoS 防护，无需额外配置。

**监控 DDoS 攻击**：
访问 Security > Events

---

## 7. 性能优化

### 7.1 HTTP/2 和 HTTP/3

Cloudflare 自动启用 HTTP/2 和 HTTP/3（QUIC）。

**验证**：
```bash
curl -I --http2 https://dacong.com
curl -I --http3 https://dacong.com
```

### 7.2 Early Hints

访问 Speed > Optimization

- **Early Hints**: 开启（提前发送资源提示）

### 7.3 Argo Smart Routing（付费）

加速全球访问，减少延迟 30%。

**价格**：$5/月 + $0.10/GB

---

## 8. 监控和分析

### 8.1 Cloudflare Analytics

访问 Analytics > Traffic

**监控指标**：
- 请求数
- 带宽使用
- 缓存命中率
- 威胁数量
- 响应时间

### 8.2 配置告警

访问 Notifications

**推荐告警**：
- DDoS 攻击
- SSL 证书即将过期
- 流量异常
- 源服务器宕机

---

## 9. 域名配置检查清单

- [ ] 域名已购买
- [ ] DNS 记录已配置
- [ ] DNS 传播完成
- [ ] SSL 证书已配置
- [ ] HTTPS 强制跳转已启用
- [ ] HSTS 已启用
- [ ] CDN 已启用
- [ ] 缓存规则已配置
- [ ] 防火墙规则已配置
- [ ] 安全头已配置
- [ ] SSL 评分 A 或 A+
- [ ] HTTP/2 已启用
- [ ] Brotli 压缩已启用

---

## 10. 常见问题

### DNS 未生效

**问题**：域名无法访问

**解决方案**：
```bash
# 检查 DNS 传播
dig dacong.com +short

# 清除本地 DNS 缓存
# macOS
sudo dscacheutil -flushcache

# Windows
ipconfig /flushdns

# Linux
sudo systemd-resolve --flush-caches
```

### SSL 证书错误

**问题**：浏览器显示"不安全"

**解决方案**：
1. 检查 Cloudflare SSL 模式是否为 "Full (strict)"
2. 确保源服务器有有效的 SSL 证书
3. 检查证书是否过期
4. 清除浏览器缓存

### 重定向循环

**问题**：页面无限重定向

**解决方案**：
1. 检查 Cloudflare SSL 模式（应为 Full 或 Full strict）
2. 检查源服务器是否也在做 HTTPS 重定向
3. 禁用 Cloudflare 的 "Always Use HTTPS"，手动在源服务器配置重定向

### 缓存未生效

**问题**：静态资源未被缓存

**解决方案**：
1. 检查 DNS 记录是否为"已代理"（橙色云朵）
2. 检查页面规则是否正确
3. 手动清除缓存：Caching > Configuration > Purge Everything
4. 检查响应头 `Cache-Control`

---

## 11. 备案（中国大陆）

如果需要在中国大陆提供服务，需要进行 ICP 备案。

### 11.1 备案要求

- 域名在中国注册商（如阿里云、腾讯云）
- 服务器在中国大陆
- 提供营业执照或个人身份证
- 备案时间：15-20 个工作日

### 11.2 备案流程

1. 在云服务商处申请备案
2. 填写备案信息
3. 提交材料
4. 等待初审
5. 拍照核验
6. 等待管局审核
7. 备案完成

### 11.3 备案后配置

在网站底部添加备案号：
```html
<footer>
  <p>© 2024 DaCong. All rights reserved.</p>
  <p>
    <a href="https://beian.miit.gov.cn/" target="_blank">
      京ICP备xxxxxxxx号
    </a>
  </p>
</footer>
```

---

## 下一步

1. 部署应用：[PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md)
2. 配置监控：[MONITORING_SETUP.md](./MONITORING_SETUP.md)
3. 配置备份：[BACKUP_RECOVERY.md](./BACKUP_RECOVERY.md)
