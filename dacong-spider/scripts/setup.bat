@echo off
REM DaCong Spider 开发环境配置脚本 (Windows)

echo ==================================
echo DaCong Spider 环境配置
echo ==================================

REM 1. 检查 Python 版本
echo.
echo [1/6] 检查 Python 版本...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ 错误: 未找到 python
    echo 请先安装 Python 3.11 或更高版本
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version') do set PYTHON_VERSION=%%i
echo ✅ Python 版本: %PYTHON_VERSION%

REM 2. 创建虚拟环境
echo.
echo [2/6] 创建虚拟环境...
if exist venv (
    echo ⚠️  虚拟环境已存在，跳过创建
) else (
    python -m venv venv
    echo ✅ 虚拟环境创建成功
)

REM 3. 激活虚拟环境
echo.
echo [3/6] 激活虚拟环境...
call venv\Scripts\activate.bat
echo ✅ 虚拟环境已激活

REM 4. 升级 pip
echo.
echo [4/6] 升级 pip...
python -m pip install --upgrade pip >nul 2>&1
echo ✅ pip 已升级到最新版本

REM 5. 安装依赖
echo.
echo [5/6] 安装依赖包...
pip install -r requirements.txt
echo ✅ 依赖包安装完成

REM 6. 配置环境变量
echo.
echo [6/6] 配置环境变量...
if exist .env (
    echo ⚠️  .env 文件已存在，跳过复制
) else (
    copy .env.example .env >nul
    echo ✅ 已创建 .env 文件
    echo.
    echo ⚠️  请编辑 .env 文件，填入真实的配置值：
    echo    - SUPABASE_URL
    echo    - SUPABASE_SERVICE_ROLE_KEY
    echo    - GITHUB_TOKEN (可选，用于提高 API 限额)
    echo    - 其他 API 密钥（根据需要）
)

REM 7. 创建日志目录
echo.
echo 创建日志目录...
if not exist logs mkdir logs
echo ✅ 日志目录已创建

REM 8. 完成
echo.
echo ==================================
echo 环境配置完成！
echo ==================================
echo.
echo 下一步：
echo 1. 编辑 .env 文件，填入配置
echo 2. 激活虚拟环境: venv\Scripts\activate
echo 3. 运行测试: pytest
echo 4. 启动爬虫: python main.py
echo.
echo 更多信息请查看 README.md
echo.
pause
