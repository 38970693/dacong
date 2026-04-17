#!/usr/bin/env python3
"""
环境验证脚本 - 检查所有依赖和配置是否正确
"""
import sys
import importlib
from typing import List, Tuple


def check_python_version() -> Tuple[bool, str]:
    """检查 Python 版本"""
    version = sys.version_info
    if version.major == 3 and version.minor >= 11:
        return True, f"✅ Python {version.major}.{version.minor}.{version.micro}"
    return False, f"❌ Python 版本过低: {version.major}.{version.minor}.{version.micro} (需要 >= 3.11)"


def check_dependencies() -> List[Tuple[bool, str]]:
    """检查依赖包"""
    dependencies = [
        ("httpx", "HTTP 客户端"),
        ("beautifulsoup4", "HTML 解析"),
        ("supabase", "Supabase 客户端"),
        ("apscheduler", "任务调度"),
        ("dotenv", "环境变量"),
        ("pydantic", "数据验证"),
        ("pydantic_settings", "配置管理"),
        ("pytest", "测试框架"),
        ("black", "代码格式化"),
        ("ruff", "代码检查"),
    ]

    results = []
    for package, description in dependencies:
        try:
            # 特殊处理包名映射
            import_name = package
            if package == "beautifulsoup4":
                import_name = "bs4"
            elif package == "dotenv":
                import_name = "dotenv"
            elif package == "pydantic_settings":
                import_name = "pydantic_settings"

            mod = importlib.import_module(import_name)
            version = getattr(mod, "__version__", "unknown")
            results.append((True, f"✅ {package:20s} {version:15s} ({description})"))
        except ImportError:
            results.append((False, f"❌ {package:20s} 未安装 ({description})"))

    return results


def check_config() -> List[Tuple[bool, str]]:
    """检查配置文件"""
    results = []

    # 检查 .env 文件
    try:
        from pathlib import Path
        env_file = Path(".env")
        if env_file.exists():
            results.append((True, "✅ .env 文件存在"))
        else:
            results.append((False, "❌ .env 文件不存在（请从 .env.example 复制）"))
            return results
    except Exception as e:
        results.append((False, f"❌ 检查 .env 文件失败: {e}"))
        return results

    # 检查配置加载
    try:
        from config import config

        # 检查必需配置
        if config.supabase_url:
            results.append((True, f"✅ Supabase URL: {config.supabase_url[:30]}..."))
        else:
            results.append((False, "❌ SUPABASE_URL 未配置"))

        if config.supabase_service_role_key:
            results.append((True, "✅ Supabase Service Role Key: 已配置"))
        else:
            results.append((False, "❌ SUPABASE_SERVICE_ROLE_KEY 未配置"))

        # 检查可选配置
        if config.github_token:
            results.append((True, "✅ GitHub Token: 已配置"))
        else:
            results.append((True, "⚠️  GitHub Token: 未配置（可选，但建议配置以提高 API 限额）"))

        if config.openrouter_api_key:
            results.append((True, "✅ OpenRouter API Key: 已配置"))
        else:
            results.append((True, "⚠️  OpenRouter API Key: 未配置（可选）"))

        if config.reddit_client_id:
            results.append((True, "✅ Reddit API: 已配置"))
        else:
            results.append((True, "⚠️  Reddit API: 未配置（可选）"))

        results.append((True, f"✅ 日志级别: {config.log_level}"))
        results.append((True, f"✅ 日志文件: {config.log_file}"))

    except Exception as e:
        results.append((False, f"❌ 配置加载失败: {e}"))

    return results


def check_directories() -> List[Tuple[bool, str]]:
    """检查目录结构"""
    from pathlib import Path

    directories = [
        ("core", "核心模块"),
        ("spiders", "爬虫实现"),
        ("schedulers", "调度器"),
        ("models", "数据模型"),
        ("tests", "测试"),
    ]

    results = []
    for dir_name, description in directories:
        path = Path(dir_name)
        if path.exists() and path.is_dir():
            results.append((True, f"✅ {dir_name:15s} 目录存在 ({description})"))
        else:
            results.append((False, f"❌ {dir_name:15s} 目录不存在 ({description})"))

    # 检查日志目录
    log_dir = Path("logs")
    if not log_dir.exists():
        try:
            log_dir.mkdir(parents=True, exist_ok=True)
            results.append((True, "✅ logs 目录已创建"))
        except Exception as e:
            results.append((False, f"❌ 创建 logs 目录失败: {e}"))
    else:
        results.append((True, "✅ logs 目录存在"))

    return results


def main():
    """主函数"""
    print("\n" + "=" * 70)
    print("DaCong Spider 环境验证")
    print("=" * 70)

    all_passed = True

    # 1. 检查 Python 版本
    print("\n[1/4] Python 版本检查")
    print("-" * 70)
    passed, message = check_python_version()
    print(message)
    if not passed:
        all_passed = False

    # 2. 检查依赖包
    print("\n[2/4] 依赖包检查")
    print("-" * 70)
    dep_results = check_dependencies()
    for passed, message in dep_results:
        print(message)
        if not passed:
            all_passed = False

    # 3. 检查目录结构
    print("\n[3/4] 目录结构检查")
    print("-" * 70)
    dir_results = check_directories()
    for passed, message in dir_results:
        print(message)
        if not passed:
            all_passed = False

    # 4. 检查配置
    print("\n[4/4] 配置检查")
    print("-" * 70)
    config_results = check_config()
    for passed, message in config_results:
        print(message)
        if not passed:
            all_passed = False

    # 总结
    print("\n" + "=" * 70)
    if all_passed:
        print("✅ 所有检查通过！环境配置正确。")
        print("\n下一步:")
        print("  python main.py --list          # 列出所有爬虫")
        print("  python main.py --spider github # 测试运行单个爬虫")
        print("  python main.py                 # 启动调度器")
    else:
        print("❌ 部分检查失败，请根据上述提示修复问题。")
        print("\n常见问题:")
        print("  1. 依赖未安装: pip install -r requirements.txt")
        print("  2. .env 未配置: cp .env.example .env && 编辑 .env")
        print("  3. Python 版本过低: 安装 Python 3.11+")

    print("=" * 70 + "\n")

    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
