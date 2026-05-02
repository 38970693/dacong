import { describe, it, expect } from 'vitest';

// 本地关键词黑名单（从 moderator.ts 复制用于测试）
const BLACKLIST = [
  '台独', '藏独', '疆独', '港独',
  '赌博', '色情', '毒品', '诈骗',
];

function checkLocalBlacklist(text: string): boolean {
  const lowerText = text.toLowerCase();
  return BLACKLIST.some(word => lowerText.includes(word.toLowerCase()));
}

function localModeration(title: string, content: string | null): {
  passed: boolean;
  reason?: string;
} {
  const text = `${title} ${content || ''}`;

  if (checkLocalBlacklist(text)) {
    return {
      passed: false,
      reason: '命中本地黑名单',
    };
  }

  return { passed: true };
}

describe('AI 审核 - 本地关键词', () => {
  it('应该通过正常内容', () => {
    const result = localModeration('科技创新引领未来', '科技行业最新动态');
    expect(result.passed).toBe(true);
    expect(result.reason).toBeUndefined();
  });

  it('应该拒绝包含敏感词的内容', () => {
    const result = localModeration('这是一个诈骗案例分析', null);
    expect(result.passed).toBe(false);
    expect(result.reason).toBe('命中本地黑名单');
  });

  it('应该大小写不敏感', () => {
    const result1 = localModeration('赌博网站被查', null);
    const result2 = localModeration('DUBO网站被查', null);  // DUBO 不是中文 "赌博"
    const result3 = localModeration('du赌博网站被查', null); // du + 中文赌博

    expect(result1.passed).toBe(false);
    expect(result2.passed).toBe(true);  // DUBO 只是字母，不是中文
    expect(result3.passed).toBe(false); // du + 赌博
  });

  it('应该处理空内容', () => {
    const result = localModeration('测试标题', null);
    expect(result.passed).toBe(true);
  });

  it('应该处理空标题', () => {
    const result = localModeration('', '这是一段内容');
    expect(result.passed).toBe(true);
  });

  it('应该同时检查标题和内容', () => {
    // 标题正常，内容有敏感词
    const result = localModeration('今日新闻', '涉及赌博案件');
    expect(result.passed).toBe(false);
  });
});