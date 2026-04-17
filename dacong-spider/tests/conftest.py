"""
Pytest 配置和 fixtures
"""
import sys
from pathlib import Path
from unittest.mock import Mock, patch

import pytest

# 添加项目根目录到 Python 路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


@pytest.fixture(scope="session", autouse=True)
def mock_config():
    """Mock 全局配置"""
    with patch("config.SpiderConfig") as mock_config_class:
        mock_config_instance = Mock()
        mock_config_instance.supabase_url = "https://test.supabase.co"
        mock_config_instance.supabase_service_role_key = "test-service-role-key"
        mock_config_instance.anthropic_api_key = "test-anthropic-key"
        mock_config_instance.github_token = "test-github-token"
        mock_config_instance.spider_debug = False
        mock_config_instance.log_level = "INFO"

        mock_config_class.return_value = mock_config_instance

        # Mock config 实例
        with patch("config.config", mock_config_instance):
            yield mock_config_instance
