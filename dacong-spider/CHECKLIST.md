# 开发环境配置清单

使用本清单确保开发环境正确配置。

## 📋 安装清单

### 1. 系统要求
- [ ] Python 3.11 或更高版本已安装
- [ ] pip 已安装并升级到最新版本
- [ ] Git 已安装
- [ ] 有 Supabase 账号（免费）

### 2. 项目克隆
- [ ] 已克隆项目到本地
- [ ] 已进入项目目录 `cd dacong-spider`

### 3. 依赖安装
- [ ] 已运行安装脚本（`./scripts/setup.sh` 或 `scripts\setup.bat`）
- [ ] 虚拟环境已创建（`venv/` 目录存在）
- [ ] 所有依赖已安装（运行 `python scripts/verify.py` 验证）

### 4. 环境配置
- [ ] `.env` 文件已创建（从 `.env.example` 复制）
- [ ] `SUPABASE_URL` 已配置
- [ ] `SUPABASE_SERVICE_ROLE_KEY` 已配置
- [ ] （可选）`GITHUB_TOKEN` 已配置
- [ ] （可选）其他 API 密钥已配置

### 5. Supabase 配置
- [ ] 已在 Supabase 创建项目
- [ ] 已执行数据表创建 SQL（见 `QUICKSTART.md`）
- [ ] 数据表已创建：
  - [ ] `model_raw_metrics`
  - [ ] `repository_metrics`
  - [ ] `hot_news_raw`
  - [ ] `trending_keywords`

### 6. 环境验证
- [ ] 运行 `python scripts/verify.py` 全部通过
- [ ] 运行 `python main.py --validate-config` 验证通过
- [ ] 运行 `python main.py --list` 可以看到爬虫列表

### 7. 功能测试
- [ ] 运行 `python main.py --spider github` 测试单个爬虫
- [ ] 检查 Supabase 数据表中是否有数据写入
- [ ] 查看日志文件 `logs/dacong_spider.log` 无错误

## 🚀 快速验证命令

```bash
# 1. 验证环境
python scripts/verify.py

# 2. 验证配置
python main.py --validate-config

# 3. 列出爬虫
python main.py --list

# 4. 测试运行
python main.py --spider github

# 5. 查看日志
tail -f logs/dacong_spider.log
```

## ⚠️ 常见问题检查

### Python 版本问题
```bash
python --version  # 应该是 3.11 或更高
```

### 依赖安装问题
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 配置文件问题
```bash
# 检查 .env 文件是否存在
ls -la .env

# 验证配置
python main.py --validate-config
```

### Supabase 连接问题
- 检查 URL 格式：`https://xxx.supabase.co`
- 检查 Key 是否正确复制（无多余空格）
- 检查网络连接

## ✅ 配置完成标志

当以下所有命令都成功执行时，说明环境配置完成：

```bash
✅ python scripts/verify.py
✅ python main.py --validate-config
✅ python main.py --list
✅ python main.py --spider github
```

## 📚 相关文档

- [README.md](README.md) - 完整项目文档
- [QUICKSTART.md](QUICKSTART.md) - 快速开始指南
- [SETUP_COMPLETE.md](SETUP_COMPLETE.md) - 配置完成总结
- [ARCHITECTURE.md](ARCHITECTURE.md) - 架构设计文档

---

**提示**: 按照清单逐项检查，确保每一项都完成后再进行下一步。
