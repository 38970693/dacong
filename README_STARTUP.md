# DaCong 项目启动指南

## 一键启动所有服务

### Windows
```bash
start-all.bat
```

### Linux/Mac
```bash
./start-all.sh
```

## 启动后访问

- **前台客户端**: http://localhost:8081
- **后台管理**: http://localhost:8080
- **爬虫服务**: 后台运行（查看 `logs/spider.log`）

## 单独启动服务

### 1. 前台客户端 (Flutter Web)

```bash
cd dacong-client
flutter run -d chrome \
  --web-port=8081 \
  --dart-define=DEV_MODE=true \
  --dart-define=SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=你的anon_key
```

### 2. 后台管理 (Flutter Web)

```bash
cd dacong-admin
flutter run -d chrome \
  --web-port=8080 \
  --dart-define=DEV_MODE=true \
  --dart-define=SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=你的anon_key
```

或使用快捷脚本：
```bash
cd dacong-admin
./start-dev-with-config.bat  # Windows
```

### 3. 爬虫服务 (Python)

```bash
cd dacong-spider

# 安装依赖（首次运行）
pip install -r requirements.txt

# 启动爬虫
python main.py

# 或使用调试模式
python main.py --debug
```

### 4. 控制台 (Next.js) - 可选

```bash
cd dacong-console
npm install  # 首次运行
npm run dev
```

访问: http://localhost:3000

## 环境要求

- **Flutter**: >= 3.8.0
- **Node.js**: >= 20.x
- **Python**: >= 3.10
- **Chrome**: 用于 Flutter Web 开发

## 日志文件

一键启动脚本会将日志输出到 `logs/` 目录：

- `logs/client.log` - 前台客户端日志
- `logs/admin.log` - 后台管理日志
- `logs/spider.log` - 爬虫服务日志

## 停止服务

### 使用一键启动脚本
- Windows: 在启动窗口按任意键
- Linux/Mac: 按 `Ctrl+C`

### 手动停止
- 关闭对应的终端窗口
- 或使用 `Ctrl+C` 停止进程

## 常见问题

### 端口被占用
如果端口 8080 或 8081 被占用，修改启动脚本中的 `--web-port` 参数。

### Flutter 应用空白
检查 Supabase 配置是否正确，确认 `SUPABASE_ANON_KEY` 已填写。

### 爬虫启动失败
1. 检查 Python 依赖是否安装：`pip install -r requirements.txt`
2. 检查 `.env` 文件是否配置正确
3. 查看 `logs/spider.log` 获取详细错误信息

### 后台管理登录失败
确保已在 Supabase Dashboard 执行数据库设置脚本，参考 [NEXT_STEPS.md](NEXT_STEPS.md)。

## 开发模式说明

所有服务默认以开发模式启动（`DEV_MODE=true`），会：
- 禁用部分安全检查（CSRF、认证等）
- 启用详细日志输出
- 支持热重载

生产环境部署时需要移除 `DEV_MODE` 参数。
