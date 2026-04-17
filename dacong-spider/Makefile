.PHONY: help install test lint format clean run docker-build docker-up docker-down verify

# 默认目标
help:
	@echo "DaCong Spider - 可用命令:"
	@echo ""
	@echo "  make install       - 安装依赖"
	@echo "  make install-dev   - 安装开发依赖"
	@echo "  make verify        - 验证环境配置"
	@echo "  make test          - 运行测试"
	@echo "  make test-cov      - 运行测试并生成覆盖率报告"
	@echo "  make lint          - 代码检查"
	@echo "  make format        - 格式化代码"
	@echo "  make type-check    - 类型检查"
	@echo "  make clean         - 清理临时文件"
	@echo "  make run           - 启动爬虫调度器"
	@echo "  make run-all       - 运行所有爬虫（一次性）"
	@echo "  make list          - 列出所有爬虫"
	@echo "  make docker-build  - 构建 Docker 镜像"
	@echo "  make docker-up     - 启动 Docker 容器"
	@echo "  make docker-down   - 停止 Docker 容器"
	@echo ""

# 安装依赖
install:
	pip install -r requirements.txt

# 安装开发依赖
install-dev:
	pip install -r requirements.txt
	pip install -e ".[dev]"

# 验证环境
verify:
	python scripts/verify.py

# 运行测试
test:
	pytest

# 运行测试并生成覆盖率报告
test-cov:
	pytest --cov=. --cov-report=html --cov-report=term-missing
	@echo "覆盖率报告已生成: htmlcov/index.html"

# 代码检查
lint:
	ruff check .
	@echo "✅ 代码检查通过"

# 格式化代码
format:
	black .
	isort .
	@echo "✅ 代码格式化完成"

# 类型检查
type-check:
	mypy .
	@echo "✅ 类型检查通过"

# 清理临时文件
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	rm -rf htmlcov/ .coverage coverage.xml 2>/dev/null || true
	@echo "✅ 清理完成"

# 启动爬虫调度器
run:
	python main.py

# 运行所有爬虫（一次性）
run-all:
	python main.py --all

# 列出所有爬虫
list:
	python main.py --list

# 运行单个爬虫（需要指定 SPIDER 参数）
# 例如: make run-spider SPIDER=github
run-spider:
	@if [ -z "$(SPIDER)" ]; then \
		echo "错误: 请指定爬虫名称，例如: make run-spider SPIDER=github"; \
		exit 1; \
	fi
	python main.py --spider $(SPIDER)

# 调试模式运行
run-debug:
	python main.py --debug

# 验证配置
validate-config:
	python main.py --validate-config

# Docker 相关命令
docker-build:
	docker build -t dacong-spider .

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f spider

docker-restart:
	docker-compose restart spider

# 开发环境设置
setup:
	@if [ -f "scripts/setup.sh" ]; then \
		bash scripts/setup.sh; \
	else \
		echo "错误: scripts/setup.sh 不存在"; \
		exit 1; \
	fi

# 创建 .env 文件
init-env:
	@if [ ! -f ".env" ]; then \
		cp .env.example .env; \
		echo "✅ 已创建 .env 文件，请编辑并填入配置"; \
	else \
		echo "⚠️  .env 文件已存在"; \
	fi

# 完整的开发环境初始化
init: init-env install-dev verify
	@echo ""
	@echo "✅ 开发环境初始化完成！"
	@echo ""
	@echo "下一步:"
	@echo "  1. 编辑 .env 文件，填入配置"
	@echo "  2. make verify  # 验证配置"
	@echo "  3. make test    # 运行测试"
	@echo "  4. make run     # 启动爬虫"
	@echo ""

# CI/CD 流程
ci: lint type-check test
	@echo "✅ CI 检查全部通过"

# 代码质量检查（格式化 + 检查 + 类型检查）
quality: format lint type-check
	@echo "✅ 代码质量检查完成"
