# dacong-web

AI 模型排行与社区平台 Web 端，基于 Flutter 构建。

## 技术栈

- **Flutter SDK 3.16+** — 跨平台 UI 框架
- **supabase_flutter** — Supabase 客户端
- **go_router** — 路由管理
- **Riverpod / Provider** — 状态管理（待定）

## 项目结构

```
lib/
├── main.dart              # 入口
├── pages/                 # 页面
│   ├── home_page.dart     # 主页（底部导航）
│   ├── news_page.dart     # 快讯流
│   ├── ranking_page.dart  # 排行榜
│   ├── empower_page.dart  # 赋能学习
│   ├── community_page.dart# 社区
│   └── profile_page.dart  # 个人中心
├── widgets/               # 公共组件
├── models/                # 数据模型
├── services/              # 业务服务
└── utils/                 # 工具类
```

## 页面说明

| 页面 | 路径 | 说明 |
|------|------|------|
| 首页/快讯 | / | 热点新闻流、热搜词 |
| 排行榜 | /ranking | 模型综合榜/分类榜 |
| 赋能 | /empower | 提示词库、工作流 |
| 社区 | /community | 帖子流、评论 |
| 我的 | /profile | 收藏、历史、订阅 |

## 开发

```bash
# 获取依赖
flutter pub get

# 本地开发
flutter run -d chrome

# 构建 Web
flutter build web --release
```

## 环境配置

在 `lib/main.dart` 中配置 Supabase：
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```
