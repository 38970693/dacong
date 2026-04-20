# 开发模式配置说明

## Flutter Admin 开发模式

### 启用开发模式按钮

在 `dacong-admin` 中，登录页面已添加"开发模式进入"按钮。

#### 运行方式

**开发模式（显示按钮）：**
```bash
cd dacong-admin
flutter run --dart-define=DEV_MODE=true
```

**生产模式（隐藏按钮）：**
```bash
cd dacong-admin
flutter run --dart-define=DEV_MODE=false
# 或者直接
flutter run
```

#### 功能说明

- 开发模式下，登录页面会显示橙色的"开发模式进入"按钮
- 点击按钮可以跳过登录验证，直接进入后台
- 生产环境该按钮会自动隐藏

#### 配置文件

可以在 `launch.json` 或 `run configuration` 中配置：

```json
{
  "configurations": [
    {
      "name": "dacong-admin (dev mode)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=DEV_MODE=true"
      ]
    },
    {
      "name": "dacong-admin (production)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=DEV_MODE=false"
      ]
    }
  ]
}
```

## API 开发模式

参考 [DEV_MODE_CONFIG.md](./DEV_MODE_CONFIG.md) 配置后端验证开关。
