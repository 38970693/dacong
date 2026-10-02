import React from 'react';
import { renderToStaticMarkup } from 'react-dom/server';
import { describe, expect, it } from 'vitest';
import { AINewsItem } from '@/types/dynamics';
import { NewsTranslation } from './NewsTranslation';

const item: AINewsItem = {
  id: 'news', title: 'New model', summary: 'Model details', language: 'en',
  category: 'model', source_tier: 'official', quality_score: 80,
  importance_score: 80, ai_news_sources: [],
};

describe('NewsTranslation', () => {
  it('shows a disabled translation button and status when no translation exists', () => {
    const html = renderToStaticMarkup(<NewsTranslation item={item} />);
    expect(html).toContain('翻译成中文');
    expect(html).toContain('disabled=""');
    expect(html).toContain('暂无中文译文');
    expect(html).toContain('New model');
  });

  it('defaults to Chinese while keeping the original toggle and the detail link', () => {
    const html = renderToStaticMarkup(<NewsTranslation
      item={{ ...item, title_zh: '新模型', summary_zh: '模型详情' }} href="/web/dynamics/news" />);
    expect(html).toContain('查看原文');
    expect(html).not.toContain('disabled=""');
    expect(html).not.toContain('暂无中文译文');
    expect(html).toContain('新模型');
    expect(html).toContain('模型详情');
    expect(html).toContain('lang="zh-CN"');
    expect(html).toContain('aria-pressed="true"');
    expect(html).toContain('href="/web/dynamics/news"');
    expect(html).not.toContain('New model');
  });

  it('does not offer translation for Chinese news', () => {
    const html = renderToStaticMarkup(<NewsTranslation item={{ ...item, language: 'zh', title: '中文原文', title_zh: '另一个标题', summary_zh: '另一个摘要' }} />);
    expect(html).not.toContain('<button');
    expect(html).toContain('中文原文');
    expect(html).not.toContain('另一个标题');
  });

  it('keeps translation unavailable for incomplete or whitespace-only translations', () => {
    for (const translation of [
      { title_zh: '新模型', summary_zh: null },
      { title_zh: ' ', summary_zh: '模型详情' },
    ]) {
      const html = renderToStaticMarkup(<NewsTranslation item={{ ...item, ...translation }} />);
      expect(html).toContain('disabled=""');
      expect(html).toContain('暂无中文译文');
      expect(html).toContain('New model');
    }
  });

  it('allows title-only translation when the original has no summary', () => {
    const html = renderToStaticMarkup(<NewsTranslation item={{ ...item, summary: '', title_zh: '新模型' }} />);
    expect(html).toContain('查看原文');
    expect(html).toContain('新模型');
    expect(html).not.toContain('disabled=""');
  });

  it('defaults the detail heading and summary to Chinese', () => {
    const html = renderToStaticMarkup(<NewsTranslation
      item={{ ...item, title_zh: '新模型', summary_zh: '模型详情' }} detail />);
    expect(html).toMatch(/<h1[^>]*>新模型<\/h1>/);
    expect(html).toContain('模型详情');
    expect(html).toContain('查看原文');
  });
});
