# 快速启动脚本

## Windows (PowerShell)

### 开发模式启动（显示开发按钮）
```powershell
cd dacong-admin
flutter run -d chrome --dart-define=DEV_MODE=true
```

### 生产模式启动（隐藏开发按钮）
```powershell
cd dacong-admin
flutter run -d chrome --dart-define=DEV_MODE=false
```

## 或者创建启动脚本

### start-dev.bat (Windows)
```batch
@echo off
cd dacong-admin
flutter run -d chrome --dart-define=DEV_MODE=true
```

### start-dev.sh (Linux/Mac)
```bash
#!/bin/bash
cd dacong-admin
flutter run -d chrome --dart-define=DEV_MODE=true
```

## 热重载

应用启动后，按 `r` 键进行热重载，按 `R` 键进行热重启。
