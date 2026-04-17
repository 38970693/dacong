"""
单元测试 - 爬虫

测试策略：
1. Mock HTTP 客户端
2. 测试数据处理逻辑
3. 验证执行流程
4. 测试错误处理
5. 测试去重逻辑
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timezone

from core.interfaces import MetricSource, DataType
from core.storage import InMemoryStorage
from core.implementations import ContentHashDeduplicator, SpiderLogger
from spiders.github_spider import GitHubSpider, GitHubDataProcessor
from spiders.huggingface_spider import HuggingFaceDataProcessor


# ══════════════════════════════════════════════════════════
# Mock HTTP 客户端
# ══════════════════════════════════════════════════════════

class MockHttpClient:
    """Mock HTTP 客户端"""

    def __init__(self, responses: dict):
        self.responses = responses

    async def get(self, url: str, headers=None):
        return self.responses.get(url)

    async def get_json(self, url: str, headers=None):
        return self.responses.get(url)

    async def close(self):
        pass


# ══════════════════════════════════════════════════════════
# 测试 GitHub 数据处理器
# ══════════════════════════════════════════════════════════

def test_github_processor():
    """测试 GitHub 数据处理器 - 完整数据"""
    processor = GitHubDataProcessor()

    # 模拟 GitHub API 响应
    raw_data = {
        "full_name": "test/repo",
        "name": "repo",
        "description": "A test repository",
        "html_url": "https://github.com/test/repo",
        "stargazers_count": 100,
        "forks_count": 20,
        "watchers_count": 80,
        "language": "Python",
        "topics": ["ai", "ml"],
        "created_at": "2024-01-01T00:00:00Z",
        "updated_at": "2024-04-01T00:00:00Z",
        "owner": {"login": "test"},
        "fork": False,
        "open_issues_count": 5,
        "default_branch": "main",
        "license": {"name": "MIT"}
    }

    # 处理数据
    result = processor.process(raw_data)

    # 验证结果
    assert result is not None
    assert result.source == MetricSource.GITHUB
    assert result.data_type == DataType.REPOSITORY
    assert result.source_id == "test/repo"
    assert result.title == "repo"
    assert result.description == "A test repository"
    assert result.url == "https://github.com/test/repo"
    assert result.metadata["stars"] == 100
    assert result.metadata["forks"] == 20
    assert result.metadata["watchers"] == 80
    assert result.metadata["language"] == "Python"
    assert result.metadata["topics"] == ["ai", "ml"]
    assert result.metadata["owner"] == "test"
    assert result.metadata["is_fork"] is False
    assert result.metadata["open_issues"] == 5
    assert result.metadata["default_branch"] == "main"
    assert result.metadata["license"] == "MIT"
    assert result.content_hash is not None


def test_github_processor_missing_description():
    """测试 GitHub 数据处理器 - 缺少描述"""
    processor = GitHubDataProcessor()

    raw_data = {
        "full_name": "test/repo",
        "name": "repo",
        "html_url": "https://github.com/test/repo",
        "stargazers_count": 100,
        "forks_count": 20
    }

    result = processor.process(raw_data)

    assert result is not None
    assert result.description == ""


def test_github_processor_invalid_data():
    """测试 GitHub 数据处理器 - 无效数据"""
    processor = GitHubDataProcessor()

    # 缺少必填字段
    invalid_data = {
        "name": "repo",
        "description": "Test"
    }

    result = processor.process(invalid_data)
    assert result is None


def test_github_processor_content_hash():
    """测试 GitHub 数据处理器 - 内容哈希生成"""
    processor = GitHubDataProcessor()

    data1 = {
        "full_name": "test/repo",
        "name": "repo",
        "html_url": "https://github.com/test/repo",
        "stargazers_count": 100
    }

    data2 = {
        "full_name": "test/repo",
        "name": "repo",
        "html_url": "https://github.com/test/repo",
        "stargazers_count": 200  # 不同的 stars
    }

    hash1 = processor.generate_content_hash(data1)
    hash2 = processor.generate_content_hash(data2)

    # 内容不同，哈希应该不同
    assert hash1 != hash2
    assert len(hash1) == 32  # MD5 哈希长度
    assert len(hash2) == 32


# ══════════════════════════════════════════════════════════
# 测试 HuggingFace 数据处理器
# ══════════════════════════════════════════════════════════

def test_huggingface_processor():
    """测试 HuggingFace 数据处理器"""
    processor = HuggingFaceDataProcessor()

    # 模拟 HuggingFace API 响应
    raw_data = {
        "modelId": "meta-llama/Llama-2-7b",
        "author": "meta-llama",
        "downloads": 1000000,
        "likes": 5000,
        "tags": ["text-generation", "llama"],
        "pipeline_tag": "text-generation",
        "library_name": "transformers"
    }

    # 处理数据
    result = processor.process(raw_data)

    # 验证结果
    assert result is not None
    assert result.source == MetricSource.HUGGINGFACE
    assert result.data_type == DataType.MODEL
    assert result.source_id == "meta-llama/Llama-2-7b"
    assert result.title == "Llama-2-7b"
    assert result.url == "https://huggingface.co/meta-llama/Llama-2-7b"
    assert result.metadata["downloads"] == 1000000


# ══════════════════════════════════════════════════════════
# 测试爬虫执行流程
# ══════════════════════════════════════════════════════════

@pytest.mark.asyncio
async def test_github_spider_run():
    """测试 GitHub 爬虫执行流程"""
    # Mock HTTP 响应
    mock_responses = {
        "https://api.github.com/search/repositories?q=topic:artificial-intelligence&sort=stars&order=desc&per_page=30&page=1": {
            "total_count": 1,
            "items": [
                {
                    "full_name": "test/ai-repo",
                    "name": "ai-repo",
                    "description": "AI repository",
                    "html_url": "https://github.com/test/ai-repo",
                    "stargazers_count": 1000,
                    "forks_count": 100,
                    "watchers_count": 800,
                    "language": "Python",
                    "topics": ["ai"],
                    "created_at": "2024-01-01T00:00:00Z",
                    "updated_at": "2024-04-01T00:00:00Z",
                    "owner": {"login": "test"},
                    "fork": False,
                    "open_issues_count": 10,
                    "default_branch": "main"
                }
            ]
        }
    }

    # 创建 Mock 组件
    http_client = MockHttpClient(mock_responses)
    storage = InMemoryStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("test")

    # 创建爬虫
    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger
    )

    # 执行爬虫
    result = await spider.run()

    # 验证结果
    assert result.success is True
    assert result.items_fetched > 0
    assert result.items_written > 0
    assert storage.count() > 0


@pytest.mark.asyncio
async def test_github_spider_deduplication():
    """测试 GitHub 爬虫去重逻辑"""
    mock_responses = {
        "https://api.github.com/search/repositories?q=topic:artificial-intelligence&sort=stars&order=desc&per_page=30&page=1": {
            "total_count": 2,
            "items": [
                {
                    "full_name": "test/repo1",
                    "name": "repo1",
                    "html_url": "https://github.com/test/repo1",
                    "stargazers_count": 100
                },
                {
                    "full_name": "test/repo1",  # 重复
                    "name": "repo1",
                    "html_url": "https://github.com/test/repo1",
                    "stargazers_count": 100
                }
            ]
        }
    }

    http_client = MockHttpClient(mock_responses)
    storage = InMemoryStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("test")

    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger
    )

    result = await spider.run()

    # 应该只写入 1 条数据（去重后）
    assert result.success is True
    assert storage.count() == 1


@pytest.mark.asyncio
async def test_github_spider_api_error():
    """测试 GitHub 爬虫 API 错误处理"""
    # Mock 返回 None（模拟 API 失败）
    mock_responses = {}

    http_client = MockHttpClient(mock_responses)
    storage = InMemoryStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("test")

    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger
    )

    result = await spider.run()

    # API 失败但不应该抛出异常
    assert result.success is True
    assert result.items_fetched == 0
    assert result.items_written == 0


@pytest.mark.asyncio
async def test_github_spider_pagination():
    """测试 GitHub 爬虫分页功能"""
    mock_responses = {
        "https://api.github.com/search/repositories?q=topic:artificial-intelligence&sort=stars&order=desc&per_page=30&page=1": {
            "total_count": 60,
            "items": [
                {
                    "full_name": f"test/repo-page1-{i}",
                    "name": f"repo-page1-{i}",
                    "html_url": f"https://github.com/test/repo-page1-{i}",
                    "stargazers_count": 100 + i
                }
                for i in range(30)
            ]
        },
        "https://api.github.com/search/repositories?q=topic:artificial-intelligence&sort=stars&order=desc&per_page=30&page=2": {
            "total_count": 60,
            "items": [
                {
                    "full_name": f"test/repo-page2-{i}",
                    "name": f"repo-page2-{i}",
                    "html_url": f"https://github.com/test/repo-page2-{i}",
                    "stargazers_count": 200 + i
                }
                for i in range(30)
            ]
        }
    }

    http_client = MockHttpClient(mock_responses)
    storage = InMemoryStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("test")

    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger
    )

    result = await spider.run()

    # 应该获取到两页数据
    assert result.success is True
    assert result.items_fetched >= 60  # 至少 60 条（可能有其他主题的数据）


@pytest.mark.asyncio
async def test_github_spider_content_update():
    """测试 GitHub 爬虫内容更新检测"""
    # 第一次爬取
    mock_responses_v1 = {
        "https://api.github.com/search/repositories?q=topic:artificial-intelligence&sort=stars&order=desc&per_page=30&page=1": {
            "total_count": 1,
            "items": [
                {
                    "full_name": "test/repo",
                    "name": "repo",
                    "html_url": "https://github.com/test/repo",
                    "stargazers_count": 100
                }
            ]
        }
    }

    http_client = MockHttpClient(mock_responses_v1)
    storage = InMemoryStorage()
    processor = GitHubDataProcessor()
    deduplicator = ContentHashDeduplicator()
    logger = SpiderLogger("test")

    spider = GitHubSpider(
        http_client=http_client,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger
    )

    result1 = await spider.run()
    assert storage.count() == 1

    # 第二次爬取（内容变化）
    mock_responses_v2 = {
        "https://api.github.com/search/repositories?q=topic:artificial-intelligence&sort=stars&order=desc&per_page=30&page=1": {
            "total_count": 1,
            "items": [
                {
                    "full_name": "test/repo",
                    "name": "repo",
                    "html_url": "https://github.com/test/repo",
                    "stargazers_count": 200  # stars 增加
                }
            ]
        }
    }

    http_client2 = MockHttpClient(mock_responses_v2)
    spider2 = GitHubSpider(
        http_client=http_client2,
        data_processor=processor,
        storage=storage,
        deduplicator=deduplicator,
        logger=logger
    )

    result2 = await spider2.run()

    # 应该检测到内容变化并更新
    assert result2.success is True
    assert result2.items_written > 0
    assert storage.count() == 1  # 仍然是 1 条（更新而非新增）


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
