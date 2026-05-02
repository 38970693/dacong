import { describe, it, expect } from 'vitest';
// 直接导入类型文件
import type { Post, ApiResponse } from './database';

// 模拟 Post 结构测试
describe('Post 类型定义', () => {
  it('应该接受正确的 Post 对象', () => {
    const post: Post = {
      id: 'test-id-123',
      raw_post_id: 'raw-123',
      title: '测试标题',
      content: '测试内容',
      source: '36kr',
      source_url: 'https://example.com/123',
      views: 100,
      likes: 50,
      comments_count: 10,
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z',
    };

    expect(post.id).toBe('test-id-123');
    expect(post.title).toBe('测试标题');
    expect(post.views).toBe(100);
  });

  it('应该允许可选字段为空', () => {
    const post: Post = {
      id: 'test-id-456',
      raw_post_id: null,
      title: '无来源帖子',
      content: null,
      source: null,
      source_url: null,
      views: 0,
      likes: 0,
      comments_count: 0,
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z',
    };

    expect(post.source).toBeNull();
    expect(post.content).toBeNull();
  });
});

// API 响应格式测试
describe('ApiResponse 类型', () => {
  it('应该正确构建成功响应', () => {
    const response: ApiResponse<Post> = {
      success: true,
      data: {
        id: 'test',
        raw_post_id: null,
        title: 'Test',
        content: null,
        source: null,
        source_url: null,
        views: 0,
        likes: 0,
        comments_count: 0,
        created_at: '',
        updated_at: '',
      },
    };

    expect(response.success).toBe(true);
    expect(response.data).toBeDefined();
    expect(response.error).toBeUndefined();
  });

  it('应该正确构建错误响应', () => {
    const response: ApiResponse<never> = {
      success: false,
      error: 'Database connection failed',
    };

    expect(response.success).toBe(false);
    expect(response.error).toBe('Database connection failed');
    expect(response.data).toBeUndefined();
  });

  it('应该包含分页元数据', () => {
    const response: ApiResponse<Post[]> = {
      success: true,
      data: [],
      meta: {
        total: 100,
        page: 1,
        limit: 20,
        next_cursor: '2024-01-01T00:00:00Z_abc123',
      },
    };

    expect(response.meta?.next_cursor).toBe('2024-01-01T00:00:00Z_abc123');
  });
});

// Cursor 分页逻辑测试
describe('Cursor 分页', () => {
  it('应该正确解析 cursor 格式', () => {
    const cursor = '2024-01-01T00:00:00Z_abc123';
    const [timestamp, id] = cursor.split('_');

    expect(timestamp).toBe('2024-01-01T00:00:00Z');
    expect(id).toBe('abc123');
  });

  it('应该正确生成 next_cursor', () => {
    const lastPost = {
      created_at: '2024-01-01T00:00:00Z',
      id: 'post-123',
    };

    const nextCursor = `${lastPost.created_at}_${lastPost.id}`;
    expect(nextCursor).toBe('2024-01-01T00:00:00Z_post-123');
  });

  it('应该处理空 cursor', () => {
    const cursor = '';
    const parts = cursor.split('_');
    const [timestamp, id] = parts;

    // 空字符串分割后得到 ['']
    expect(timestamp).toBe('');
    expect(id).toBeUndefined();
  });
});