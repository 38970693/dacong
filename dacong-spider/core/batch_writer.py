"""
批量写入优化模块
使用批量插入和异步写入提升数据库写入性能
"""

import asyncio
from typing import List, Dict, Any, Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class BatchWriter:
    """批量写入器"""
    
    def __init__(
        self,
        batch_size: int = 100,
        flush_interval: float = 5.0,
        max_retries: int = 3
    ):
        """
        初始化批量写入器
        
        Args:
            batch_size: 批量大小
            flush_interval: 刷新间隔（秒）
            max_retries: 最大重试次数
        """
        self.batch_size = batch_size
        self.flush_interval = flush_interval
        self.max_retries = max_retries
        
        self._buffer: List[Dict[str, Any]] = []
        self._lock = asyncio.Lock()
        self._flush_task: Optional[asyncio.Task] = None
        self._running = False
        
    async def start(self):
        """启动自动刷新任务"""
        if self._running:
            return
            
        self._running = True
        self._flush_task = asyncio.create_task(self._auto_flush())
        logger.info(f"批量写入器已启动 (batch_size={self.batch_size}, interval={self.flush_interval}s)")
        
    async def stop(self):
        """停止并刷新所有数据"""
        self._running = False
        
        if self._flush_task:
            self._flush_task.cancel()
            try:
                await self._flush_task
            except asyncio.CancelledError:
                pass
                
        await self.flush()
        logger.info("批量写入器已停止")
        
    async def add(self, item: Dict[str, Any]):
        """
        添加数据到缓冲区
        
        Args:
            item: 要写入的数据
        """
        async with self._lock:
            self._buffer.append(item)
            
            # 如果达到批量大小，立即刷新
            if len(self._buffer) >= self.batch_size:
                await self._flush()
                
    async def add_many(self, items: List[Dict[str, Any]]):
        """
        批量添加数据
        
        Args:
            items: 要写入的数据列表
        """
        async with self._lock:
            self._buffer.extend(items)
            
            # 如果达到批量大小，立即刷新
            if len(self._buffer) >= self.batch_size:
                await self._flush()
                
    async def flush(self):
        """手动刷新缓冲区"""
        async with self._lock:
            await self._flush()
            
    async def _flush(self):
        """内部刷新方法（需要持有锁）"""
        if not self._buffer:
            return
            
        items = self._buffer.copy()
        self._buffer.clear()
        
        # 执行批量写入
        await self._write_batch(items)
        
    async def _auto_flush(self):
        """自动刷新任务"""
        while self._running:
            try:
                await asyncio.sleep(self.flush_interval)
                await self.flush()
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"自动刷新失败: {e}")
                
    async def _write_batch(self, items: List[Dict[str, Any]]):
        """
        执行批量写入（子类需要实现）
        
        Args:
            items: 要写入的数据列表
        """
        raise NotImplementedError("子类需要实现 _write_batch 方法")


class SupabaseBatchWriter(BatchWriter):
    """Supabase 批量写入器"""
    
    def __init__(
        self,
        supabase_client,
        table_name: str,
        **kwargs
    ):
        """
        初始化 Supabase 批量写入器
        
        Args:
            supabase_client: Supabase 客户端
            table_name: 表名
        """
        super().__init__(**kwargs)
        self.client = supabase_client
        self.table_name = table_name
        
    async def _write_batch(self, items: List[Dict[str, Any]]):
        """执行批量写入到 Supabase"""
        if not items:
            return
            
        for attempt in range(self.max_retries):
            try:
                # 使用 upsert 批量插入或更新
                result = self.client.table(self.table_name).upsert(items).execute()
                
                logger.info(
                    f"批量写入成功: {len(items)} 条数据到 {self.table_name} "
                    f"(attempt={attempt + 1})"
                )
                return
                
            except Exception as e:
                logger.error(
                    f"批量写入失败 (attempt={attempt + 1}/{self.max_retries}): {e}"
                )
                
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(2 ** attempt)  # 指数退避
                else:
                    logger.error(f"批量写入最终失败，丢失 {len(items)} 条数据")


class ContentBatchWriter(SupabaseBatchWriter):
    """内容批量写入器"""
    
    def __init__(self, supabase_client, **kwargs):
        super().__init__(
            supabase_client=supabase_client,
            table_name='contents',
            **kwargs
        )
        
    async def add_content(
        self,
        title: str,
        url: str,
        source_platform: str,
        **kwargs
    ):
        """
        添加内容数据
        
        Args:
            title: 标题
            url: URL
            source_platform: 来源平台
            **kwargs: 其他字段
        """
        item = {
            'title': title,
            'url': url,
            'source_platform': source_platform,
            'created_at': datetime.utcnow().isoformat(),
            'status': 'pending',
            **kwargs
        }
        
        await self.add(item)


class ModelBatchWriter(SupabaseBatchWriter):
    """AI 模型批量写入器"""
    
    def __init__(self, supabase_client, **kwargs):
        super().__init__(
            supabase_client=supabase_client,
            table_name='ai_models',
            **kwargs
        )
        
    async def add_model(
        self,
        name: str,
        provider: str,
        category: str,
        **kwargs
    ):
        """
        添加 AI 模型数据
        
        Args:
            name: 模型名称
            provider: 提供商
            category: 分类
            **kwargs: 其他字段
        """
        item = {
            'name': name,
            'provider': provider,
            'category': category,
            'created_at': datetime.utcnow().isoformat(),
            'status': 'active',
            **kwargs
        }
        
        await self.add(item)


# 使用示例
"""
from supabase import create_client
from core.batch_writer import ContentBatchWriter

# 初始化
supabase = create_client(url, key)
writer = ContentBatchWriter(supabase, batch_size=50, flush_interval=3.0)

# 启动
await writer.start()

# 添加数据
await writer.add_content(
    title="示例标题",
    url="https://example.com",
    source_platform="github",
    summary="示例摘要"
)

# 停止（会自动刷新剩余数据）
await writer.stop()
"""
