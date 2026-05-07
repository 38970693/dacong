import { describe, it, expect, vi, beforeEach } from 'vitest';

// 使用 vi.hoisted 确保 mock 在模块加载前就准备好
const mockExecAsync = vi.hoisted(() => vi.fn());

// Mock child_process/exec
vi.mock('child_process', () => ({
  exec: mockExecAsync,
  execSync: vi.fn(),
}));

// Mock util/promisify - 直接返回函数本身作为 async 函数
vi.mock('util', () => ({
  promisify: (fn: (cmd: string, options: object) => Promise<{ stdout: string; stderr: string }>) => {
    return (cmd: string, options: object) => Promise.resolve(mockExecAsync(cmd, options));
  },
}));

// Mock logger to avoid output during tests
vi.mock('../../logger', () => ({
  logger: {
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
  },
}));

import { obscuraFetch, checkObscura, initObscura, FetchOptions } from './mod';

describe('Obscura 模块', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    // 清除路径缓存
    vi.resetModules();
  });

  describe('obscuraFetch', () => {
    it('应该成功获取页面内容', async () => {
      const mockOutput = 'Page loaded: https://example.com - "Example Page"\n<html><body>Content</body></html>';

      mockExecAsync.mockResolvedValue({ stdout: mockOutput, stderr: '' });

      const result = await obscuraFetch('https://example.com');

      expect(result.success).toBe(true);
      expect(result.url).toBe('https://example.com');
      expect(result.content).toContain('<html>');
    });

    it('应该处理 fetch 失败', async () => {
      mockExecAsync.mockRejectedValue(new Error('Command failed'));

      const result = await obscuraFetch('https://example.com');

      expect(result.success).toBe(false);
      expect(result.error).toContain('Command failed');
    });

    it('应该正确传递选项参数', async () => {
      let capturedCmd = '';
      mockExecAsync.mockImplementation(async (cmd: string) => {
        capturedCmd = cmd;
        return { stdout: 'Page loaded: https://example.com - "Test"\nContent', stderr: '' };
      });

      const options: FetchOptions = {
        stealth: true,
        waitUntil: 'networkidle0',
        timeout: 60,
        dump: 'text',
        quiet: false,
      };

      await obscuraFetch('https://example.com', options);

      expect(capturedCmd).toContain('--stealth');
      expect(capturedCmd).toContain('--wait-until networkidle0');
      expect(capturedCmd).toContain('--timeout 60');
      expect(capturedCmd).toContain('--dump text');
    });

    it('应该支持自定义 User-Agent', async () => {
      let capturedCmd = '';
      mockExecAsync.mockImplementation(async (cmd: string) => {
        capturedCmd = cmd;
        return { stdout: 'Page loaded: - "Test"\nContent', stderr: '' };
      });

      await obscuraFetch('https://example.com', {
        userAgent: 'CustomBot/1.0',
      });

      expect(capturedCmd).toContain('--user-agent');
      expect(capturedCmd).toContain('CustomBot/1.0');
    });

    it('应该支持 JavaScript eval', async () => {
      let capturedCmd = '';
      mockExecAsync.mockImplementation(async (cmd: string) => {
        capturedCmd = cmd;
        return { stdout: 'Page loaded: - "Test"\n[{"title":"Test"}]', stderr: '' };
      });

      const result = await obscuraFetch('https://example.com', {
        eval: 'JSON.stringify([{title: "Test"}])',
      });

      expect(capturedCmd).toContain('--eval');
      expect(result.content).toContain('[{"title":"Test"}]');
    });
  });

  describe('checkObscura', () => {
    it('应该返回可用状态和版本', async () => {
      mockExecAsync.mockResolvedValue({
        stdout: 'Obscura v1.2.3 - Headless Browser\nUsage: obscura [command]',
        stderr: '',
      });

      const result = await checkObscura();

      expect(result.available).toBe(true);
      expect(result.version).toBe('1.2.3');
    });

    it('应该处理 Obscura 不可用的情况', async () => {
      mockExecAsync.mockRejectedValue(new Error('ENOENT: file not found'));

      const result = await checkObscura();

      expect(result.available).toBe(false);
      expect(result.error).toContain('ENOENT');
    });
  });

  describe('initObscura', () => {
    it('应该在 Obscura 可用时返回 true', async () => {
      mockExecAsync.mockResolvedValue({ stdout: 'Obscura v1.0.0', stderr: '' });

      const result = await initObscura();

      expect(result).toBe(true);
    });

    it('应该在 Obscura 不可用时返回 false', async () => {
      mockExecAsync.mockRejectedValue(new Error('Not found'));

      const result = await initObscura();

      expect(result).toBe(false);
    });
  });
});