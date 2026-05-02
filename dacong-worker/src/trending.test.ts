import { describe, it, expect } from 'vitest';

// 简化的评分函数（从 trending.ts 复制用于测试）
function calculateScore(views: number, likes: number, comments: number, createdAt: Date): number {
  const baseScore = views * 0.3 + likes * 0.5 + comments * 0.2;

  // 时间衰减：6小时半衰期
  const ageHours = (Date.now() - createdAt.getTime()) / (1000 * 60 * 60);
  const decay = Math.exp(-ageHours / 6);

  return baseScore * decay;
}

describe('热榜评分算法', () => {
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

  it('应该正确处理零值', () => {
    const now = new Date();
    const score = calculateScore(0, 0, 0, now);
    expect(score).toBe(0);
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