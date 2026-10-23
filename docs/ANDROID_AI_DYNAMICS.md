# Android AI 动态同步

更新日期：2026-10-23。

## 功能与入口

当前 Android 工程为 `dacong-console/android`，应用 ID 保持 `com.dacong.app`，版本升级为 `1.1.3`（versionCode 5）。旧 Flutter 客户端继续保持归档状态。

Android 首页直接加载 `https://dacong-weld.vercel.app/web/dynamics`，复用已部署的移动端页面和 API，包括：

- AI 动态分类、精选/最新列表、近 7/30 天及全部时间筛选、详情与来源链接；
- 每日摘要列表与详情；
- 已有完整译文的标题和摘要默认显示中文，逐条“查看原文”/“翻译成中文”切换；暂无译文时显示英文；
- 动态、日报、收藏、我的底部导航。

此版对应 2026-10-02 最新 Web 调整，包括真实近 7 日精选、来源统计、原始发布日期与更严格的 AI 内容筛选。RSS 每两小时自动采集，动态每 15 分钟处理，日报每天北京时间 08:00 生成。

已有译文的内容支持切换。新增内容自动翻译仍受 Web 端相同的翻译服务配置限制。

### 1.1.2 手机布局修复

- 主内容增加 `min-width: 0`，允许 Flex 布局随手机屏幕收缩，避免分类栏的内容宽度撑大页面。
- 手机顶部留白与 56px 导航高度一致；底部留白保留至 `lg` 断点，与底部导航的显示范围一致，删除动态页面的重复留白。
- 动态页签和资讯分类保持单行并支持横向滚动；排序与时间筛选在空间不足时换行，增加筛选控件的触控高度。
- 英文标题、摘要和详情来源中的超长词允许换行；飙升榜统计信息允许换行。
- WebView 显式启用 viewport meta 支持及按宽度适配的加载模式。行为参考 [Android WebSettings 文档](https://developer.android.com/reference/android/webkit/WebSettings#setUseWideViewPort(boolean))。

页面布局修复随 Web 发布生效；WebView 设置需要安装新版 APK。

### 1.1.3 启动白屏处理

用户报告启动画面后整屏空白。本次工作区检查：直连生产站点 18 秒超时，经代理访问返回 HTTP 200；这提示网络可达性可能参与问题，但没有手机日志，不能据此断言手机的具体根因。

- 启动即显示原生加载界面与版本号，不再让用户面对没有提示的 WebView；原生提示文字显式使用深色，避免深色主题下白底白字。
- 等待 20 秒仍未显示正文时，显示超时提示和重试入口；HTTP、网络、SSL 及渲染进程退出分别显示中文提示。
- 重试重新加载已验证的站内 URL，并清理 HTTP 缓存，不再只刷新可能已停在错误页的 WebView；渲染进程退出后可新建 WebView。
- 加载或错误界面可进入内置简版，直接通过 Supabase 公开 API 读取最新 30 条已发布资讯，默认中文，支持原文切换、来源链接及刷新。

简版是网络受限时的阅读备用入口，不包含完整版搜索、连续翻页、日报或账户功能，也不是离线新闻库；Supabase 也无法访问时会显示错误和刷新按钮。APK 仅包含公开 anon 配置，遵循公开 RLS，不包含 service role 或管理凭据。SSL 验证、明文及混合内容限制保持启用。

## Android 容器

Web 端已使用 Next.js 服务器 API，无法继续把旧 `out` 静态导出当作完整应用打包。Android 的 `MainActivity` 因此改为原生 WebView 在线客户端，不再依赖 Capacitor 静态资源加载；Gradle 不再包含 Capacitor/Cordova 模块，也不打包旧 Web assets。

仅生产站点的 HTTPS 导航在应用内打开，其他 HTTP/HTTPS 新闻来源由系统浏览器打开。客户端启用 JavaScript 和 DOM Storage 以支持页面交互与登录，禁用本地文件访问、明文连接与混合内容；不注入 JavaScript 原生接口，也不绕过证书校验。

界面为状态栏、刘海、系统导航栏和键盘预留空间。Android 返回键先返回上一页，到首页时退出。主页面网络或 HTTP 错误显示中文提示与“重试”按钮。

此版本需要网络连接；完整版的 Web 端后续发布会同步到 Android。简版为 APK 内置资源，改动简版需重新构建。

## 构建

安装 JDK 17 与 Android SDK 36，在本机 `android/local.properties` 设置 SDK 路径。简版构建读取 `dacong-console/.env.local` 或环境变量中的 `NEXT_PUBLIC_SUPABASE_URL`、`NEXT_PUBLIC_SUPABASE_ANON_KEY`；仅使用公开 anon 配置，缺失时构建会失败。这些本地配置文件不提交到 Git。

```powershell
cd dacong-console/android
.\gradlew.bat :app:testDebugUnitTest :app:lintDebug :app:assembleDebug --console=plain
```

产物：`dacong-console/android/app/build/outputs/apk/debug/app-debug.apk`。

此次生成的便于分发的副本：`dacong-console/android/app/build/outputs/apk/debug/dacong-ai-news-1.1.3.apk`。

该 APK 使用 Android 开发签名，供安装测试。正式分发需使用原应用的发布签名，才能覆盖安装对应的旧正式版本。本次不生成新的发布密钥。

## 验证

导航单元测试覆盖站内动态/日报/登录路径，以及外部来源、伪装域名、HTTP、非标准端口、用户信息和危险协议的拦截。本次 3 项单元测试（含 2 项导航测试）全部通过，APK 构建通过，Lint 为 0 个错误、15 个警告。警告包括资源/图标规范、依赖版本和启用 JavaScript 的通用提示；本站交互需要 JavaScript，客户端通过限定站点与禁用原生接口控制加载范围。

APK 大小约 3.66 MiB，开发签名校验通过；版本信息为 `1.1.3` / `5`，签名与上一测试版本一致。包内包含 `res/raw/news_fallback.html`，不包含旧静态 assets。

简版 4 项 jsdom 测试通过，覆盖启动加载、公开 API 查询范围、默认中文与原文切换、超时后刷新及不安全内容处理。使用 APK 编译产物中的公开配置请求真实 Supabase API 返回 HTTP 200，读取到 30 条完整中文资讯；校验 token 角色为 anon。没有在测试输出中打印 Key。

本次修改的 6 个 Web 文件通过 ESLint，Next.js 生产构建和 TypeScript 检查通过。构建中仍有既有排行榜数据库表/列缺失提示。浏览器页面检查接口持续超时，未取得窄屏渲染截图或实测宽度，不能将构建通过视为手机显示已验收。

本机没有连接 Android 设备，未执行真机交互验收。安装后需检查启动提示、20 秒超时、重试完整版、简版读取与译文切换、原文浏览器跳转、返回键和断网刷新。不能将编译和脚本测试通过等同于手机白屏根因已被确认。
