import { describe, expect, it } from 'vitest';
import { showcaseInput } from './showcase';

const input = { kind: 'work', title: ' AI 工具 ', summary: '帮助创作', content: '实现说明', creator_name: '小明', demo_url: 'https://example.com', source_url: '' };
describe('showcase input', () => {
  it('normalizes a playable work and drops client ownership or status claims', () => {
    const result = showcaseInput({ ...input, user_id: 'another-user', status: 'withdrawn' });
    expect(result.title).toBe('AI 工具');
    expect(result.demo_url).toBe('https://example.com/');
    expect(result.source_url).toBeNull();
    expect(result).not.toHaveProperty('user_id');
    expect(result).not.toHaveProperty('status');
  });
  it('allows an idea without an existing demo', () => {
    expect(showcaseInput({ ...input, kind: 'idea', demo_url: '' }).demo_url).toBeNull();
  });
  it('requires a demo for a work', () => {
    expect(() => showcaseInput({ ...input, demo_url: '' })).toThrow('体验地址');
  });
  it('rejects invalid kinds and missing or oversized text', () => {
    for (const change of [{ kind: 'other' }, { title: ' ' }, { summary: 'a'.repeat(301) }, { content: 'a'.repeat(5001) }, { creator_name: '' }]) {
      expect(() => showcaseInput({ ...input, ...change })).toThrow();
    }
  });
  it('rejects unsafe protocols and embedded credentials', () => {
    for (const demo_url of ['javascript:alert(1)', 'http://example.com', 'data:text/html,x', 'https://user:pass@example.com', '//example.com']) {
      expect(() => showcaseInput({ ...input, demo_url })).toThrow('HTTPS');
    }
  });
});
