# DaCong Client

AI 工具决策助手，基于 Flutter 构建，支持 Web / Android / iOS 三端。

采用 **Clean Architecture + BLoC** 模式，严格遵循 SOLID 原则。

## 环境要求

- **Flutter SDK**: 3.3.0+
- **Dart SDK**: 3.0.0+
- **Android Studio** / **Xcode** (可选，用于移动端开发)
- **Chrome** (用于 Web 开发)

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd dacong-client
```

### 2. 配置环境

#### Windows

```bash
cd dacong-client
scripts\setup.bat
```

#### Linux / macOS

```bash
cd dacong-client
chmod +x scripts/*.sh
./scripts/setup.sh
```

配置脚本会自动：
- 检查 Flutter 环境
- 安装依赖
- 运行代码生成
- 创建 `.env` 配置文件

### 3. 配置 Supabase

编辑 `.env` 文件，填入你的 Supabase 配置：

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
API_BASE_URL=http://localhost:8000/api
ENVIRONMENT=dev
```

获取 Supabase 配置：
1. 访问 [Supabase Dashboard](https://app.supabase.com)
2. 选择你的项目
3. 进入 Settings → API
4. 复制 `URL` 和 `anon public` key

### 4. 运行应用

#### Web 版本

```bash
# Windows
scripts\run-web.bat

# Linux / macOS
./scripts/run-web.sh
```

访问 http://localhost:3000

#### Android 版本

```bash
# Windows
scripts\run-android.bat

# Linux / macOS
./scripts/run-android.sh
```

确保已连接 Android 设备或启动模拟器。

#### iOS 版本（仅 macOS）

```bash
./scripts/run-ios.sh
```

确保已连接 iOS 设备或启动模拟器。

## 技术栈

### 核心框架
- **Flutter**: 3.3.0+ - 跨平台 UI 框架
- **Dart**: 3.0.0+ - 编程语言

### 状态管理
- **flutter_bloc**: 8.1.3 - BLoC 状态管理
- **equatable**: 2.0.5 - 值对象比较

### 依赖注入
- **get_it**: 7.6.4 - 服务定位器
- **injectable**: 2.3.2 - 代码生成

### 网络层
- **dio**: 5.4.0 - HTTP 客户端
- **supabase_flutter**: 2.5.0 - Supabase 客户端

### 函数式编程
- **dartz**: 0.10.1 - Either 类型，错误处理

### 代码生成
- **freezed**: 2.4.6 - 不可变数据类
- **json_serializable**: 6.7.1 - JSON 序列化
- **build_runner**: 2.4.7 - 代码生成工具

### 路由
- **go_router**: 14.0.0 - 声明式路由

### 本地化
- **intl**: 0.20.2 - 国际化支持
- **flutter_localizations** - Flutter 本地化

## 项目结构

```
lib/
├── core/                           # 核心层
│   ├── constants/                  # 常量配置
│   │   └── app_constants.dart      # 应用配置
│   ├── di/                         # 依赖注入
│   │   └── injection.dart          # DI 配置
│   ├── domain/                     # 领域层
│   │   ├── entities/               # 领域实体（不可变）
│   │   ├── repositories/           # 仓储接口
│   │   └── usecases/               # 用例（业务逻辑）
│   ├── error/                      # 错误处理
│   │   ├── exceptions.dart         # 异常定义
│   │   └── failures.dart           # 失败类型
│   └── network/                    # 网络层
│       └── api_client.dart         # HTTP 客户端
│
├── data/                           # 数据层
│   ├── models/                     # 数据模型（可序列化）
│   ├── repositories/               # 仓储实现
│   └── datasources/                # 数据源
│
├── presentation/                   # 表现层
│   ├── blocs/                      # BLoC 状态管理
│   ├── pages/                      # 页面
│   └── widgets/                    # 可复用组件
│
├── l10n/                           # 多语言资源
│   ├── app_zh.arb                  # 中文翻译
│   └── app_en.arb                  # 英文翻译
│
└── main.dart                       # 应用入口
```

详细架构说明请查看 [README_ARCHITECTURE.md](./README_ARCHITECTURE.md)

## 开发指南

### 代码生成

当修改了 `@freezed` 或 `@JsonSerializable` 注解的类后，需要运行代码生成：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

或使用 watch 模式（自动监听文件变化）：

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 运行测试

```bash
# Windows
scripts\test.bat

# Linux / macOS
./scripts/test.sh
```

测试覆盖率报告会生成在 `coverage/lcov.info`。

### VS Code 调试

项目已配置好 VS Code 调试配置，按 F5 即可启动调试：

- **DaCong (Dev)** - 开发模式
- **DaCong Web (Chrome)** - Web 版本
- **DaCong Android** - Android 版本
- **DaCong iOS** - iOS 版本
- **DaCong (Profile)** - 性能分析模式
- **DaCong (Release)** - 发布模式

### 推荐的 VS Code 扩展

- Dart
- Flutter
- Flutter Snippets
- Awesome Flutter Snippets
- Error Lens
- Code Spell Checker
- GitLens

## 构建发布版本

### Web

```bash
flutter build web --release
```

输出目录：`build/web/`

### Android APK

```bash
flutter build apk --release
```

输出文件：`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle

```bash
flutter build appbundle --release
```

输出文件：`build/app/outputs/bundle/release/app-release.aab`

### iOS (仅 macOS)

```bash
flutter build ios --release
```

## 常见问题

### 1. Flutter Doctor 报错

运行 `flutter doctor` 检查环境问题，根据提示修复。

### 2. 依赖安装失败

```bash
flutter clean
flutter pub get
```

### 3. 代码生成失败

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Android 构建失败

检查 `android/local.properties` 是否正确配置了 Android SDK 路径。

### 5. iOS 构建失败（macOS）

```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

### 6. Supabase 连接失败

- 检查 `.env` 文件配置是否正确
- 确认 Supabase 项目状态正常
- 检查网络连接

## 多语言支持

| 平台 | 行为 |
|------|------|
| Android / iOS | 自动跟随系统语言 |
| Web | 自动跟随系统语言，可手动切换 |

支持语言：
- 中文 (zh)
- 英文 (en)

## 页面说明

| 页面 | 路径 | 说明 |
|------|------|------|
| 首页 | / | 推荐内容流 |
| 内容详情 | /content/:id | 内容详细信息 |
| 搜索 | /search | 搜索功能 |

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

[MIT License](../LICENSE)

## 相关文档

- [架构文档](./README_ARCHITECTURE.md)
- [快速开始指南](../dacong-docs/QUICKSTART.md)
- [API 文档](../dacong-api/README.md)
