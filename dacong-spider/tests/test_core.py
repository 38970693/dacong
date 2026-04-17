"""
单元测试 - 核心组件

测试策略：
1. 使用内存存储进行测试
2. Mock HTTP 请求
3. 测试每个组件的单一职责
"""
import pytest
from datetime import datetime, timezone

from core.interfaces import MetricSource, DataType, RawData
from core.implementations import (
    ContentHashDeduplicator,
    ExponentialBackoffRetry,
    FixedDelayRetry
)
from core.storage import InMemoryStorage


# ══════════════════════════════════════════════════════════
# 测试数据
# ══════════════════════════════════════════════════════════

@pytest.fixture
def sample_raw_data():
    """示例原始数据"""
    return RawData(
        source=MetricSource.GITHUB,
        data_type=DataType.REPOSITORY,
        source_id="test/repo",
        title="Test Repo",
        description="A test repository",
        url="https://github.com/test/repo",
        metadata={"stars": 100},
        raw_content='{"name": "test"}',
        content_hash="abc123",
        fetched_at=datetime.now(timezone.utc)
    )


# ══════════════════════════════════════════════════════════
# 测试存储
# ══════════════════════════════════════════════════════════

@pytest.mark.asyncio
async def test_in_memory_storage_save(sample_raw_data):
    """测试内存存储 - 保存数据"""
    storage = InMemoryStorage()

    # 保存数据
    result = await storage.save(sample_raw_data)
    assert result is True

    # 验证数据存在
    exists = await storage.exists(sample_raw_data.source, sample_raw_data.source_id)
    assert exists is True

    # 验证数据数量
    assert storage.count() == 1


@pytest.mark.asyncio
async def test_in_memory_storage_save_batch(sample_raw_data):
    """测试内存存储 - 批量保存"""
    storage = InMemoryStorage()

    # 创建多条数据
    data_list = [
        sample_raw_data,
        RawData(
            source=MetricSource.GITHUB,
            data_type=DataType.REPOSITORY,
            source_id="test/repo2",
            title="Test Repo 2",
            description="Another test",
            url="https://github.com/test/repo2",
            metadata={},
            raw_content='{}',
            content_hash="def456",
            fetched_at=datetime.now(timezone.utc)
        )
    ]

    # 批量保存
    count = await storage.save_batch(data_list)
    assert count == 2
    assert storage.count() == 2


@pytest.mark.asyncio
async def test_in_memory_storage_get_content_hash(sample_raw_data):
    """测试内存存储 - 获取内容哈希"""
    storage = InMemoryStorage()

    # 保存数据
    await storage.save(sample_raw_data)

    # 获取哈希
    hash_value = await storage.get_content_hash(
        sample_raw_data.source,
        sample_raw_data.source_id
    )
    assert hash_value == "abc123"


# ══════════════════════════════════════════════════════════
# 测试去重器
# ══════════════════════════════════════════════════════════

@pytest.mark.asyncio
async def test_deduplicator_filter_duplicates(sample_raw_data):
    """测试去重器 - 过滤重复数据"""
    storage = InMemoryStorage()
    deduplicator = ContentHashDeduplicator()

    # 第一次：全部是新数据
    data_list = [sample_raw_data]
    unique = await deduplicator.filter_duplicates(data_list, storage)
    assert len(unique) == 1

    # 保存数据
    await storage.save_batch(unique)

    # 第二次：相同数据，应该被过滤
    unique = await deduplicator.filter_duplicates(data_list, storage)
    assert len(unique) == 0


@pytest.mark.asyncio
async def test_deduplicator_content_changed(sample_raw_data):
    """测试去重器 - 内容变化检测"""
    storage = InMemoryStorage()
    deduplicator = ContentHashDeduplicator()

    # 保存原始数据
    await storage.save(sample_raw_data)

    # 创建内容变化的数据（相同 source_id，不同 content_hash）
    changed_data = RawData(
        source=sample_raw_data.source,
        data_type=sample_raw_data.data_type,
        source_id=sample_raw_data.source_id,
        title="Updated Title",
        description=sample_raw_data.description,
        url=sample_raw_data.url,
        metadata={"stars": 200},  # 变化
        raw_content='{"name": "updated"}',
        content_hash="xyz789",  # 不同的哈希
        fetched_at=datetime.now(timezone.utc)
    )

    # 应该检测到变化，不过滤
    unique = await deduplicator.filter_duplicates([changed_data], storage)
    assert len(unique) == 1


# ══════════════════════════════════════════════════════════
# 测试重试策略
# ══════════════════════════════════════════════════════════

def test_exponential_backoff_retry():
    """测试指数退避重试策略"""
    strategy = ExponentialBackoffRetry(max_retries=3, base_delay=1.0)

    # 测试重试判断
    assert strategy.should_retry(0, None) is True
    assert strategy.should_retry(2, None) is True
    assert strategy.should_retry(3, None) is False

    # 测试延迟计算（指数增长）
    assert strategy.get_delay(0) == 1.0
    assert strategy.get_delay(1) == 2.0
    assert strategy.get_delay(2) == 4.0


def test_fixed_delay_retry():
    """测试固定延迟重试策略"""
    strategy = FixedDelayRetry(max_retries=3, delay=2.0)

    # 测试重试判断
    assert strategy.should_retry(0, None) is True
    assert strategy.should_retry(3, None) is False

    # 测试延迟计算（固定值）
    assert strategy.get_delay(0) == 2.0
    assert strategy.get_delay(1) == 2.0
    assert strategy.get_delay(2) == 2.0


# ══════════════════════════════════════════════════════════
# 测试数据不可变性
# ══════════════════════════════════════════════════════════

def test_raw_data_immutability(sample_raw_data):
    """测试 RawData 不可变性"""
    # 尝试修改字段应该抛出异常
    with pytest.raises(Exception):
        sample_raw_data.title = "New Title"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
