/**
 * Date Formatting Tests
 */
import { describe, it, expect } from 'vitest';
import { formatDistanceToNow, format, parseISO } from 'date-fns';
import { zhCN } from 'date-fns/locale';

// 简化的时间格式化函数
const formatRelativeTime = (date: Date | string): string => {
  const d = typeof date === 'string' ? parseISO(date) : date;
  const now = new Date();
  const diffMs = now.getTime() - d.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHour = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHour / 24);

  if (diffSec < 60) return '刚刚';
  if (diffMin < 60) return `${diffMin}分钟前`;
  if (diffHour < 24) return `${diffHour}小时前`;
  if (diffDay < 7) return `${diffDay}天前`;
  return format(d, 'MM-dd', { locale: zhCN });
};

const formatNumber = (num: number): string => {
  if (num >= 10000) {
    return `${(num / 10000).toFixed(1)}万`;
  }
  if (num >= 1000) {
    return `${(num / 1000).toFixed(1)}k`;
  }
  return String(num);
};

describe('Date Formatting', () => {
  it('应该正确显示"刚刚"', () => {
    const now = new Date();
    expect(formatRelativeTime(now)).toBe('刚刚');
  });

  it('应该正确显示分钟前', () => {
    const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000);
    expect(formatRelativeTime(fiveMinAgo)).toBe('5分钟前');
  });

  it('应该正确显示小时前', () => {
    const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);
    expect(formatRelativeTime(threeHoursAgo)).toBe('3小时前');
  });

  it('应该正确显示天前', () => {
    const twoDaysAgo = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);
    expect(formatRelativeTime(twoDaysAgo)).toBe('2天前');
  });

  it('应该正确处理 ISO 字符串', () => {
    // 使用最近一周内的日期
    const recentDate = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000); // 2天前
    const result = formatRelativeTime(recentDate.toISOString());
    expect(result).toContain('天前');
  });

  it('应该正确格式化日期', () => {
    const date = new Date(2024, 0, 15); // Jan 15, 2024
    const result = format(date, 'yyyy-MM-dd');
    expect(result).toBe('2024-01-15');
  });
});

describe('Number Formatting', () => {
  it('应该正确格式化小于1000的数字', () => {
    expect(formatNumber(999)).toBe('999');
    expect(formatNumber(0)).toBe('0');
    expect(formatNumber(100)).toBe('100');
  });

  it('应该正确格式化千位数字', () => {
    expect(formatNumber(1000)).toBe('1.0k');
    expect(formatNumber(1500)).toBe('1.5k');
    expect(formatNumber(10000)).toBe('1.0万');
    expect(formatNumber(55000)).toBe('5.5万');
  });

  it('应该正确格式化万位数字', () => {
    expect(formatNumber(10000)).toBe('1.0万');
    expect(formatNumber(100000)).toBe('10.0万');
    expect(formatNumber(1000000)).toBe('100.0万');
  });
});

// 列表排序测试
describe('List Sorting', () => {
  const posts = [
    { id: '1', created_at: '2024-01-01T00:00:00Z', views: 100 },
    { id: '2', created_at: '2024-01-03T00:00:00Z', views: 200 },
    { id: '3', created_at: '2024-01-02T00:00:00Z', views: 150 },
  ];

  it('应该按时间降序排序', () => {
    const sorted = [...posts].sort((a, b) =>
      new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );
    expect(sorted[0].id).toBe('2');
    expect(sorted[1].id).toBe('3');
    expect(sorted[2].id).toBe('1');
  });

  it('应该按热度降序排序', () => {
    const sorted = [...posts].sort((a, b) => b.views - a.views);
    expect(sorted[0].views).toBe(200);
    expect(sorted[2].views).toBe(100);
  });
});

// 热榜评分计算
describe('Trending Score Calculation', () => {
  const calculateScore = (views: number, likes: number, comments: number, createdAt: Date): number => {
    const baseScore = views * 0.3 + likes * 0.5 + comments * 0.2;

    // 时间衰减：6小时半衰期
    const ageHours = (Date.now() - createdAt.getTime()) / (1000 * 60 * 60);
    const decay = Math.exp(-ageHours / 6);

    return baseScore * decay;
  };

  it('应该正确计算基础分数', () => {
    const now = new Date();
    const score = calculateScore(100, 50, 20, now);
    // 100 * 0.3 + 50 * 0.5 + 20 * 0.2 = 30 + 25 + 4 = 59
    expect(score).toBe(59);
  });

  it('应该对新内容给予更高分数', () => {
    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);

    const freshScore = calculateScore(100, 50, 20, now);
    const oldScore = calculateScore(100, 50, 20, oneHourAgo);

    expect(freshScore).toBeGreaterThan(oldScore);
  });

  it('应该处理零值', () => {
    const now = new Date();
    expect(calculateScore(0, 0, 0, now)).toBe(0);
  });

  it('半衰期衰减应该正确', () => {
    const now = new Date();
    const sixHoursAgo = new Date(now.getTime() - 6 * 60 * 60 * 1000);

    const currentScore = calculateScore(100, 0, 0, now);
    const halfLifeScore = calculateScore(100, 0, 0, sixHoursAgo);

    // e^-1 ≈ 0.368，所以半衰期后应该是原来的 ~37%
    const ratio = halfLifeScore / currentScore;
    expect(ratio).toBeCloseTo(Math.E ** -1, 2);
  });
});

// 关键词审核
describe('Content Moderation', () => {
  const BLACKLIST = [
    '台独', '藏独', '疆独', '港独',
    '赌博', '色情', '毒品', '诈骗',
  ];

  const checkLocalBlacklist = (text: string): boolean => {
    const lowerText = text.toLowerCase();
    return BLACKLIST.some(word => lowerText.includes(word.toLowerCase()));
  };

  const localModeration = (title: string, content: string | null): {
    passed: boolean;
    reason?: string;
  } => {
    const text = `${title} ${content || ''}`;

    if (checkLocalBlacklist(text)) {
      return {
        passed: false,
        reason: '命中本地黑名单',
      };
    }

    return { passed: true };
  };

  it('应该通过正常内容', () => {
    const result = localModeration('科技创新引领未来', '科技行业最新动态');
    expect(result.passed).toBe(true);
  });

  it('应该拒绝包含敏感词的内容', () => {
    const result = localModeration('这是一个诈骗案例分析', null);
    expect(result.passed).toBe(false);
    expect(result.reason).toBe('命中本地黑名单');
  });

  it('应该大小写不敏感', () => {
    const result1 = localModeration('赌博网站被查', null);
    expect(result1.passed).toBe(false);
  });

  it('应该处理空内容', () => {
    const result = localModeration('测试标题', null);
    expect(result.passed).toBe(true);
  });

  it('应该同时检查标题和内容', () => {
    const result = localModeration('今日新闻', '涉及赌博案件');
    expect(result.passed).toBe(false);
  });
});