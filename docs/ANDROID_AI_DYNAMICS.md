# Android AI 动态同步

更新日期：2026-10-03。

## 功能与入口

当前 Android 工程为 `dacong-console/android`，应用 ID 保持 `com.dacong.app`，版本升级为 `1.1.2`（versionCode 4）。旧 Flutter 客户端继续保持归档状态。

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

## Android 容器

Web 端已使用 Next.js 服务器 API，无法继续把旧 `out` 静态导出当作完整应用打包。Android 的 `MainActivity` 因此改为原生 WebView 在线客户端，不再依赖 Capacitor 静态资源加载；Gradle 不再包含 Capacitor/Cordova 模块，也不打包旧 Web assets。

仅生产站点的 HTTPS 导航在应用内打开，其他 HTTP/HTTPS 新闻来源由系统浏览器打开。客户端启用 JavaScript 和 DOM Storage 以支持页面交互与登录，禁用本地文件访问、明文连接与混合内容；不注入 JavaScript 原生接口，也不绕过证书校验。

界面为状态栏、刘海、系统导航栏和键盘预留空间。Android 返回键先返回上一页，到首页时退出。主页面网络或 HTTP 错误显示中文提示与“重试”按钮。

此版本需要网络连接；Web 端后续发布会同步到 Android，无需为页面文案或翻译按钮另行重打 APK。

## 构建

安装 JDK 17 与 Android SDK 36，在本机 `android/local.properties` 设置 SDK 路径。该文件不提交到 Git。

```powershell
cd dacong-console/android
.\gradlew.bat :app:testDebugUnitTest :app:lintDebug :app:assembleDebug --console=plain
```

产物：`dacong-console/android/app/build/outputs/apk/debug/app-debug.apk`。

此次生成的便于分发的副本：`dacong-console/android/app/build/outputs/apk/debug/dacong-ai-news-1.1.2.apk`。

该 APK 使用 Android 开发签名，供安装测试。正式分发需使用原应用的发布签名，才能覆盖安装对应的旧正式版本。本次不生成新的发布密钥。

## 验证

导航单元测试覆盖站内动态/日报/登录路径，以及外部来源、伪装域名、HTTP、非标准端口、用户信息和危险协议的拦截。本次 3 项单元测试（含 2 项导航测试）全部通过，APK 构建通过，Lint 为 0 个错误、16 个警告。警告包括资源/图标规范、依赖版本和启用 JavaScript 的通用提示；本站交互需要 JavaScript，客户端通过限定站点与禁用原生接口控制加载范围。

APK 大小为 3.65 MiB，开发签名校验通过；版本信息确认为 `1.1.2` / `4`，签名与上一测试版本一致。SHA-256：`3C3E6425FCC4CAEA39842D0D039EC60EF979DD2BEB01DE62D08746671A6C3D9B`。

本次修改的 6 个 Web 文件通过 ESLint，Next.js 生产构建和 TypeScript 检查通过。构建中仍有既有排行榜数据库表/列缺失提示。浏览器页面检查接口持续超时，未取得窄屏渲染截图或实测宽度，不能将构建通过视为手机显示已验收。

本机没有连接 Android 设备或配置模拟器，未执行真机交互验收。安装后需检查首页加载、译文切换、日报导航、原文浏览器跳转、返回键和断网重试。
