# DaCong Flutter 开发环境快速启动指南

## 🚀 5 分钟快速开始

### 第一步：环境检查

确保已安装：
- **Flutter SDK 3.3.0+**
- **Dart SDK 3.0.0+**
- **Chrome** (用于 Web 开发)
- **Android Studio** 或 **Xcode** (可选，用于移动端)

验证安装：
```bash
flutter doctor
```

### 第二步：初始化项目

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

这个脚本会自动：
- ✅ 检查 Flutter 环境
- ✅ 安装所有依赖
- ✅ 创建 `.env` 配置文件
- ✅ 运行代码生成

### 第三步：配置 Supabase

编辑 `.env` 文件：

```env
SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co
SUPABASE_ANON_KEY=你的_anon_key
API_BASE_URL=http://localhost:8000/api
ENVIRONMENT=dev
```

**获取 Supabase 配置：**
1. 访问 https://app.supabase.com
2. 选择项目
3. Settings → API
4. 复制 `URL` 和 `anon public` key

### 第四步：启动应用

#### Web 开发（推荐）
```bash
# Windows
scripts\run-web.bat

# Linux / macOS
./scripts/run-web.sh
```

访问：http://localhost:3000

#### Android 开发
```bash
# 1. 启动 Android 模拟器或连接设备
# 2. 运行脚本
scripts\run-android.bat      # Windows
./scripts/run-android.sh     # Linux/macOS
```

#### iOS 开发（仅 macOS）
```bash
# 1. 启动 iOS 模拟器或连接设备
# 2. 运行脚本
./scripts/run-ios.sh
```

## 📁 项目结构速览

```
dacong-client/
├── lib/
│   ├── core/                    # 核心层
│   │   ├── constants/           # 配置常量
│   │   ├── di/                  # 依赖注入
│   │   ├── domain/              # 领域层（实体、用例、仓储接口）
│   │   ├── error/               # 错误处理
│   │   └── network/             # 网络层
│   ├── data/                    # 数据层（模型、仓储实现、数据源）
│   ├── presentation/            # 表现层（BLoC、页面、组件）
│   └── main.dart                # 应用入口
├── scripts/                     # 开发脚本
├── .env                         # 环境配置（不提交到 Git）
├── .env.example                 # 环境配置模板
└── pubspec.yaml                 # 依赖配置
```

## 🛠️ 常用命令

### 安装依赖
```bash
flutter pub get
```

### 代码生成
```bash
# 一次性生成
flutter pub run build_runner build --delete-conflicting-outputs

# 或使用脚本
scripts\generate.bat             # Windows
./scripts/generate.sh            # Linux/macOS

# 监听模式（自动生成）
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 运行测试
```bash
# 使用脚本
scripts\test.bat                 # Windows
./scripts/test.sh                # Linux/macOS

# 或直接运行
flutter test --coverage
```

### 环境检查
```bash
scripts\check-env.bat            # Windows
./scripts/check-env.sh           # Linux/macOS
```

## 🎯 开发工作流

### 1. 修改数据模型后
```bash
# 重新生成代码
./scripts/generate.sh
```

### 2. 添加新依赖后
```bash
flutter pub get
```

### 3. 提交代码前
```bash
# 运行测试
./scripts/test.sh

# 检查代码格式
flutter analyze
```

## 🐛 常见问题

### 1. Flutter Doctor 报错
```bash
flutter doctor
# 根据提示修复问题
```

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

### 4. Supabase 连接失败
- 检查 `.env` 文件配置
- 确认 Supabase 项目状态
- 检查网络连接

### 5. Android 构建失败
检查 `android/local.properties` 是否正确配置 Android SDK 路径。

### 6. iOS 构建失败（macOS）
```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

## 📚 VS Code 开发

### 推荐扩展
- Dart
- Flutter
- Flutter Snippets
- Awesome Flutter Snippets
- Error Lens
- GitLens

### 调试配置
按 `F5` 启动调试，可选择：
- **DaCong (Dev)** - 开发模式
- **DaCong Web (Chrome)** - Web 版本
- **DaCong Android** - Android 版本
- **DaCong iOS** - iOS 版本

## 🔗 相关文档

- [完整 README](./README.md)
- [架构文档](./README_ARCHITECTURE.md)
- [脚本说明](./scripts/README.md)
- [API 文档](../dacong-api/README.md)

## 💡 提示

### 热重载
开发时修改代码后：
- 按 `r` - 热重载（保留状态）
- 按 `R` - 热重启（重置状态）
- 按 `q` - 退出

### 性能分析
```bash
# Profile 模式
flutter run --profile

# 打开性能面板
按 `p` 键
```

### 查看日志
```bash
# 实时查看日志
flutter logs
```

## ✅ 验证配置成功

运行环境检查脚本：
```bash
scripts\check-env.bat            # Windows
./scripts/check-env.sh           # Linux/macOS
```

应该看到：
- ✅ Flutter 已安装
- ✅ 依赖已安装
- ✅ .env 文件存在
- ✅ 找到生成文件
- ✅ 可用设备列表

## 🎉 开始开发

一切就绪！现在可以：
1. 启动应用：`./scripts/run-web.sh`
2. 打开 VS Code
3. 开始编码
4. 享受热重载带来的快速迭代

祝开发愉快！🚀
