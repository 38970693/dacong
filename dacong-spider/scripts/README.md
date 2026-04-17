# Scripts 目录

本目录包含用于开发环境配置和维护的脚本。

## 脚本列表

### setup.sh (Linux/Mac)
自动化开发环境配置脚本。

**功能**：
- 检查 Python 版本（3.11+）
- 创建虚拟环境
- 安装依赖
- 创建 .env 配置文件
- 创建日志目录

**使用方法**：
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### setup.bat (Windows)
Windows 版本的开发环境配置脚本。

**使用方法**：
```cmd
scripts\setup.bat
```

### verify.py
环境验证脚本，检查所有依赖和配置是否正确。

**功能**：
- 检查 Python 版本
- 检查依赖包安装状态
- 检查目录结构
- 验证配置文件

**使用方法**：
```bash
python scripts/verify.py
```

## 推荐工作流

1. 首次安装：
```bash
./scripts/setup.sh  # 或 scripts\setup.bat
```

2. 编辑 `.env` 文件，填入配置

3. 验证环境：
```bash
python scripts/verify.py
```

4. 开始开发
