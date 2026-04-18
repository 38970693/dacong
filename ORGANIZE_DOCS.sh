#!/bin/bash
# 文档整理脚本

echo "开始整理文档..."

# 创建目录结构
mkdir -p docs/{features/{recommendation,search,user,comment},infrastructure/{docker,logging,monitoring,cache,security},deployment/{gitlab-ci,github-actions},quickstart/{auth,features,security,monitoring,logging},reports/{acceptance,completion,delivery}}

# 功能实现文档
mv RECOMMENDATION_IMPLEMENTATION.md docs/features/recommendation/ 2>/dev/null
mv SEARCH_IMPLEMENTATION.md docs/features/search/ 2>/dev/null
mv USER_AUTH_FAVORITES_IMPLEMENTATION.md docs/features/user/ 2>/dev/null
mv COMMENT_ENHANCEMENTS_SUMMARY.md docs/features/comment/ 2>/dev/null

# 基础设施文档
mv DOCKER_SETUP.md docs/infrastructure/docker/ 2>/dev/null
mv DOCKER_COMPLETION_REPORT.md docs/infrastructure/docker/ 2>/dev/null
mv README_DOCKER.md docs/infrastructure/docker/ 2>/dev/null

mv REDIS_CACHE_COMPLETE.md docs/infrastructure/cache/ 2>/dev/null

mv LOG_AGGREGATION_SUMMARY.md docs/infrastructure/logging/ 2>/dev/null
mv LOGGING_DELIVERY.md docs/infrastructure/logging/ 2>/dev/null

mv PERFORMANCE_MONITORING_COMPLETE.md docs/infrastructure/monitoring/ 2>/dev/null
mv PERFORMANCE_MONITORING_SUMMARY.md docs/infrastructure/monitoring/ 2>/dev/null

mv KEY_MANAGEMENT_IMPLEMENTATION.md docs/infrastructure/security/ 2>/dev/null
mv P2_DEPENDENCY_SCANNING_COMPLETE.md docs/infrastructure/security/ 2>/dev/null

# 部署文档
mv GITLAB_CICD_SETUP_COMPLETE.md docs/deployment/gitlab-ci/ 2>/dev/null
mv GITHUB_MIGRATION_READY.md docs/deployment/github-actions/ 2>/dev/null
mv DEPLOYMENT_SUMMARY.txt docs/deployment/ 2>/dev/null

# 快速开始文档
mv QUICKSTART_AUTH.md docs/quickstart/auth/ 2>/dev/null
mv QUICKSTART_USER_FEATURES.md docs/quickstart/features/ 2>/dev/null
mv QUICKSTART_DEPENDENCY_SCANNING.md docs/quickstart/security/ 2>/dev/null
mv PERFORMANCE_QUICKSTART.md docs/quickstart/monitoring/ 2>/dev/null
mv LOGGING_QUICKSTART.md docs/quickstart/logging/ 2>/dev/null

# 交付报告
mv P1_USER_AUTH_IMPLEMENTATION.md docs/reports/delivery/ 2>/dev/null
mv DELIVERY_SUMMARY.md docs/reports/delivery/ 2>/dev/null
mv DELIVERY_REPORT.md docs/reports/delivery/ 2>/dev/null
mv LOGGING_DELIVERY.md docs/reports/delivery/ 2>/dev/null

# 完成报告
mv TEST_COMPLETION_REPORT.md docs/reports/completion/ 2>/dev/null
mv DOCKER_COMPLETION_REPORT.md docs/reports/completion/ 2>/dev/null
mv P2_DEPENDENCY_SCANNING_COMPLETE.md docs/reports/completion/ 2>/dev/null

# 验收清单
mv P1_ACCEPTANCE_CHECKLIST.md docs/reports/acceptance/ 2>/dev/null
mv LOG_AGGREGATION_ACCEPTANCE.md docs/reports/acceptance/ 2>/dev/null

echo "文档整理完成！"
echo ""
echo "新的文档结构："
tree docs/ -L 2 2>/dev/null || find docs/ -type d | sed 's|[^/]*/| |g'
