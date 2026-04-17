# DaCong Flutter 开发脚本

本目录包含用于开发 DaCong Flutter 客户端的便捷脚本。

## 脚本列表

### 环境配置

#### `setup.sh` / `setup.bat`
初始化开发环境，自动完成：
- 检查 Flutter 环境
- 安装依赖
- 创建 .env 配置文件
- 运行代码生成

**使用方法：**
```bash
# Windows
scripts\setup.bat

# Linux / macOS
./scripts/setup.sh
```

#### `check-env.sh` / `check-env.bat`
检查开发环境状态：
- Flutter 版本
- 依赖安装状态
- 环境配置文件
- 代码生成状态
- 可用设备

**使用方法：**
```bash
# Windows
scripts\check-env.bat

# Linux / macOS
./scripts/check-env.sh
```

### 代码生成

#### `generate.sh` / `generate.bat`
运行代码生成，生成 freezed 和 json_serializable 文件。

**使用方法：**
```bash
# Windows
scripts\generate.bat

# Linux / macOS
./scripts/generate.sh
```

### 运行应用

#### `run-web.sh` / `run-web.bat`
启动 Web 版本（Chrome，端口 3000）

**使用方法：**
```bash
# Windows
scripts\run-web.bat

# Linux / macOS
./scripts/run-web.sh
```

#### `run-android.sh` / `run-android.bat`
启动 Android 版本

**使用方法：**
```bash
# Windows
scripts\run-android.bat

# Linux / macOS
./scripts/run-android.sh
```

**前置条件：**
- 已连接 Android 设备或启动模拟器

#### `run-ios.sh`
启动 iOS 版本（仅 macOS）

**使用方法：**
```bash
./scripts/run-ios.sh
```

**前置条件：**
- macOS 系统
- 已连接 iOS 设备或启动模拟器

### 测试

#### `test.sh` / `test.bat`
运行所有测试并生成覆盖率报告

**使用方法：**
```bash
# Windows
scripts\test.bat

# Linux / macOS
./scripts/test.sh
```

**输出：**
- 测试结果
- 覆盖率报告：`coverage/lcov.info`

## 快速开始流程

### 首次配置

```bash
# 1. 运行环境配置
./scripts/setup.sh          # Linux/macOS
scripts\setup.bat           # Windows

# 2. 编辑 .env 文件，填入 Supabase 配置

# 3. 检查环境
./scripts/check-env.sh      # Linux/macOS
scripts\check-env.bat       # Windows
```

### 日常开发

```bash
# 启动 Web 开发
./scripts/run-web.sh        # Linux/macOS
scripts\run-web.bat         # Windows

# 或启动 Android 开发
./scripts/run-android.sh    # Linux/macOS
scripts\run-android.bat     # Windows

# 修改数据模型后，重新生成代码
./scripts/generate.sh       # Linux/macOS
scripts\generate.bat        # Windows

# 运行测试
./scripts/test.sh           # Linux/macOS
scripts\test.bat            # Windows
```

## 注意事项

### Linux / macOS
- 首次使用前需要添加执行权限：
  ```bash
  chmod +x scripts/*.sh
  ```

### Windows
- 直接双击 `.bat` 文件即可运行
- 或在命令行中执行：`scripts\<script-name>.bat`

### 环境变量
- 所有脚本会自动检查依赖是否安装
- 如果依赖未安装，会自动运行 `flutter pub get`

## 故障排除

### 脚本无法执行（Linux/macOS）
```bash
chmod +x scripts/*.sh
```

### Flutter 命令未找到
确保 Flutter SDK 已添加到 PATH 环境变量。

### 依赖安装失败
```bash
flutter clean
flutter pub get
```

### 代码生成失败
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```
