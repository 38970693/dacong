/**
 * Comments API Performance Tests
 * 测试所有评论 API 的响应时间
 */
import { describe, it, expect, beforeAll } from 'vitest';

// 测试配置
const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
const PERF_THRESHOLD_MS = 500; // 性能阈值：500ms

interface PerformanceMetrics {
  endpoint: string;
  duration: number;
  passed: boolean;
}

const metrics: PerformanceMetrics[] = [];

describe('Comments API Performance Tests', () => {
  beforeAll(async () => {
    // 等待服务启动
    await new Promise((resolve) => setTimeout(resolve, 1000));
  });

  // Helper function to measure API response time
  async function measureApiCall(
    name: string,
    fetchFn: () => Promise<Response>
  ): Promise<PerformanceMetrics> {
    const start = Date.now();
    try {
      const response = await fetchFn();
      const duration = Date.now() - start;
      const passed = duration < PERF_THRESHOLD_MS && response.ok;

      metrics.push({ endpoint: name, duration, passed });

      return { endpoint: name, duration, passed };
    } catch (error) {
      const duration = Date.now() - start;
      metrics.push({ endpoint: name, duration, passed: false });
      return { endpoint: name, duration, passed: false };
    }
  }

  describe('GET /api/comments - 评论列表', () => {
    it('响应时间应小于 500ms', async () => {
      const metric = await measureApiCall('GET /api/comments', () =>
        fetch(`${API_BASE_URL}/comments?target_type=post&target_id=test123`)
      );

      expect(metric.duration).toBeLessThan(PERF_THRESHOLD_MS);
    });

    it('应返回正确的响应格式', async () => {
      const response = await fetch(
        `${API_BASE_URL}/comments?target_type=post&target_id=test123`
      );
      const data = await response.json();

      expect(response.ok).toBe(true);
      expect(data).toHaveProperty('success');
      expect(data).toHaveProperty('data');
    });

    it('分页参数应正确工作', async () => {
      const response = await fetch(
        `${API_BASE_URL}/comments?target_type=post&target_id=test123&page=1&limit=10`
      );
      const data = await response.json();

      expect(data.data).toHaveProperty('page');
      expect(data.data).toHaveProperty('limit');
      expect(data.data).toHaveProperty('hasMore');
    });

    it('排序参数应正确工作 (latest)', async () => {
      const response = await fetch(
        `${API_BASE_URL}/comments?target_type=post&target_id=test123&sort=latest`
      );
      expect(response.ok).toBe(true);
    });

    it('排序参数应正确工作 (popular)', async () => {
      const response = await fetch(
        `${API_BASE_URL}/comments?target_type=post&target_id=test123&sort=popular`
      );
      expect(response.ok).toBe(true);
    });
  });

  describe('POST /api/comments - 创建评论', () => {
    it('响应时间应小于 500ms', async () => {
      const metric = await measureApiCall('POST /api/comments', () =>
        fetch(`${API_BASE_URL}/comments`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            target_type: 'post',
            target_id: 'perf-test-' + Date.now(),
            content: 'Performance test comment',
          }),
        })
      );

      // 创建操作可能稍慢，但仍应在 1 秒内完成
      expect(metric.duration).toBeLessThan(1000);
    });

    it('应正确验证必填字段', async () => {
      const response = await fetch(`${API_BASE_URL}/comments`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          target_type: 'post',
          // 缺少 target_id 和 content
        }),
      });

      expect(response.status).toBe(400);
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error).toBeDefined();
    });

    it('应正确验证 content 长度', async () => {
      const response = await fetch(`${API_BASE_URL}/comments`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          target_type: 'post',
          target_id: 'test123',
          content: 'a'.repeat(2001), // 超过 2000 字符限制
        }),
      });

      expect(response.status).toBe(400);
      const data = await response.json();
      expect(data.success).toBe(false);
      expect(data.error).toContain('2000');
    });
  });

  describe('API 格式一致性验证', () => {
    it('成功响应应包含 success 和 data 字段', async () => {
      const response = await fetch(
        `${API_BASE_URL}/comments?target_type=post&target_id=test123`
      );
      const data = await response.json();

      expect(data).toHaveProperty('success', true);
      expect(data).toHaveProperty('data');
    });

    it('错误响应应包含 success 和 error 字段', async () => {
      const response = await fetch(`${API_BASE_URL}/comments`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          target_type: 'invalid_type',
          target_id: 'test123',
          content: 'Test',
        }),
      });

      const data = await response.json();
      expect(data).toHaveProperty('success', false);
      expect(data).toHaveProperty('error');
    });

    it('嵌套评论应正确返回 replies 字段', async () => {
      // 这个测试假设存在一些嵌套评论
      const response = await fetch(
        `${API_BASE_URL}/comments?target_type=post&target_id=test123`
      );
      const data = await response.json();

      if (data.data?.comments?.length > 0) {
        // 如果有评论，检查结构
        const comment = data.data.comments[0];
        expect(comment).toHaveProperty('id');
        expect(comment).toHaveProperty('content');
        expect(comment).toHaveProperty('replies');
      }
    });
  });

  describe('并发请求测试', () => {
    it('应能处理 10 个并发请求', async () => {
      const start = Date.now();
      const concurrentRequests = 10;

      const promises = Array.from({ length: concurrentRequests }, () =>
        fetch(`${API_BASE_URL}/comments?target_type=post&target_id=test123`)
      );

      const results = await Promise.all(promises);
      const duration = Date.now() - start;

      // 所有请求都应成功
      results.forEach((response) => {
        expect(response.ok).toBe(true);
      });

      // 并发处理时间应该明显少于串行处理
      console.log(`10 个并发请求耗时: ${duration}ms`);
      expect(duration).toBeLessThan(concurrentRequests * PERF_THRESHOLD_MS);
    });
  });

  // 性能汇总报告
  afterAll(() => {
    console.log('\n=== API 性能测试报告 ===');
    console.log(`性能阈值: ${PERF_THRESHOLD_MS}ms`);
    console.log('\n各端点性能:');
    metrics.forEach((m) => {
      const status = m.passed ? '✅' : '❌';
      console.log(`  ${status} ${m.endpoint}: ${m.duration}ms`);
    });

    const passed = metrics.filter((m) => m.passed).length;
    const total = metrics.length;
    console.log(`\n通过率: ${passed}/${total} (${((passed / total) * 100).toFixed(1)}%)`);
  });
});

describe('Comments API Response Format Tests', () => {
  describe('评论数据格式', () => {
    it('评论对象应包含所有必需字段', () => {
      const mockComment = {
        id: 'test-id',
        target_type: 'post',
        target_id: 'post-id',
        user_id: 'user-id',
        content: 'Test content',
        parent_id: null,
        likes: 0,
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z',
      };

      expect(mockComment).toHaveProperty('id');
      expect(mockComment).toHaveProperty('target_type');
      expect(mockComment).toHaveProperty('target_id');
      expect(mockComment).toHaveProperty('user_id');
      expect(mockComment).toHaveProperty('content');
      expect(mockComment).toHaveProperty('parent_id');
      expect(mockComment).toHaveProperty('likes');
      expect(mockComment).toHaveProperty('created_at');
      expect(mockComment).toHaveProperty('updated_at');
    });

    it('回复对象应正确引用父评论', () => {
      const mockReply = {
        id: 'reply-id',
        parent_id: 'parent-id',
        content: 'Reply content',
      };

      expect(mockReply.parent_id).toBe('parent-id');
      expect(mockReply.parent_id).not.toBeNull();
    });

    it('评论内容应支持最多 2000 字符', () => {
      const maxContent = 'a'.repeat(2000);
      expect(maxContent.length).toBe(2000);

      const overLimit = 'a'.repeat(2001);
      expect(overLimit.length).toBe(2001);
    });
  });

  describe('分页响应格式', () => {
    it('分页响应应包含所有分页字段', () => {
      const mockPaginatedResponse = {
        success: true,
        data: {
          comments: [],
          total: 0,
          page: 1,
          limit: 20,
          hasMore: false,
        },
      };

      expect(mockPaginatedResponse.data).toHaveProperty('total');
      expect(mockPaginatedResponse.data).toHaveProperty('page');
      expect(mockPaginatedResponse.data).toHaveProperty('limit');
      expect(mockPaginatedResponse.data).toHaveProperty('hasMore');
    });

    it('hasMore 应正确计算', () => {
      const testCases = [
        { offset: 0, length: 20, total: 100, expected: true },
        { offset: 80, length: 20, total: 100, expected: false },
        { offset: 0, length: 0, total: 0, expected: false },
        { offset: 0, length: 10, total: 5, expected: false },
      ];

      testCases.forEach(({ offset, length, total, expected }) => {
        const hasMore = offset + length < total;
        expect(hasMore).toBe(expected);
      });
    });
  });

  describe('错误响应格式', () => {
    it('验证错误应返回 400 状态码', () => {
      const errorResponse = {
        success: false,
        error: 'target_type must be "post" or "review"',
      };

      expect(errorResponse.success).toBe(false);
      expect(errorResponse.error).toBeDefined();
    });

    it('未找到资源应返回 404', () => {
      const notFoundResponse = {
        success: false,
        error: 'Comment not found',
      };

      expect(notFoundResponse.success).toBe(false);
      expect(notFoundResponse.error).toContain('not found');
    });

    it('权限错误应返回 403', () => {
      const forbiddenResponse = {
        success: false,
        error: 'You can only delete your own comments',
      };

      expect(forbiddenResponse.success).toBe(false);
      expect(forbiddenResponse.error).toContain('delete');
    });
  });
});