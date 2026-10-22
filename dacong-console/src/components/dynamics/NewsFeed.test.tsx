// @vitest-environment jsdom

import React from 'react';
import { act, cleanup, fireEvent, render, screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AINewsItem } from '@/types/dynamics';
import { NewsFeed } from './NewsFeed';

interface PendingRequest {
  url: URL;
  signal: AbortSignal;
  resolve: (response: Response) => void;
  reject: (error: Error) => void;
}

let requests: PendingRequest[];

function news(id: string): AINewsItem {
  return {
    id, title: `English ${id}`, summary: `Summary ${id}`, title_zh: `中文标题 ${id}`, summary_zh: `中文摘要 ${id}`,
    language: 'en', category: 'model', source_tier: 'official', quality_score: 80, importance_score: 80,
    ai_news_sources: [{ source: 'Official', url: `https://example.com/${id}`, is_primary: true }],
  };
}

async function respond(index: number, data: AINewsItem[], nextCursor: string | null = null) {
  await act(async () => requests[index].resolve({ ok: true, json: async () => ({ data, meta: { nextCursor } }) } as Response));
}

async function fail(index: number, message = '网络暂不可用') {
  await act(async () => requests[index].reject(new Error(message)));
}

beforeEach(() => {
  requests = [];
  vi.stubGlobal('fetch', vi.fn((input: string, options: RequestInit) => new Promise<Response>((resolve, reject) => {
    requests.push({ url: new URL(input, 'https://dacong.example'), signal: options.signal as AbortSignal, resolve, reject });
  })));
});

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});

describe('NewsFeed', () => {
  it('requests the first page and keeps Chinese, original text and source links usable', async () => {
    render(<NewsFeed />);
    expect(requests[0].url.searchParams.toString()).toBe('sort=selected&days=7&limit=30');
    await respond(0, [news('one')]);
    expect(screen.getByRole('heading', { name: '中文标题 one' })).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: '查看原文' }));
    expect(screen.getByRole('heading', { name: 'English one' })).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: '翻译成中文' }));
    expect(screen.getByRole('heading', { name: '中文标题 one' })).toBeTruthy();
    expect(screen.getByRole('link', { name: '阅读原文 ↗' }).getAttribute('href')).toBe('https://example.com/one');
    expect(screen.getByRole('link', { name: /中文标题 one/ }).getAttribute('href')).toBe('/web/dynamics/one');
  });

  it('appends multiple pages with opaque cursors, deduplicates IDs and prevents repeated loading', async () => {
    render(<NewsFeed />);
    await respond(0, [news('one'), news('two')], 'opaque+/first=');
    fireEvent.click(screen.getByRole('button', { name: '加载更多' }));
    fireEvent.click(screen.getByRole('button', { name: '加载中…' }));
    expect(requests).toHaveLength(2);
    expect(requests[1].url.searchParams.get('cursor')).toBe('opaque+/first=');
    expect(screen.getByRole('heading', { name: '中文标题 one' })).toBeTruthy();
    await respond(1, [news('two'), news('three')], 'opaque-second');
    expect(screen.getAllByRole('heading')).toHaveLength(3);
    fireEvent.click(screen.getByRole('button', { name: '加载更多' }));
    expect(requests[2].url.searchParams.get('cursor')).toBe('opaque-second');
    await respond(2, [news('four')]);
    expect(screen.getAllByRole('heading')).toHaveLength(4);
    expect(screen.queryByRole('button', { name: '加载更多' })).toBeNull();
    expect(screen.getByText('已显示全部资讯')).toBeTruthy();
  });

  it('submits trimmed search to the server and clears back to the first unsearched page', async () => {
    render(<NewsFeed />);
    await respond(0, [news('old')], 'old-cursor');
    const input = screen.getByRole('searchbox', { name: '搜索 AI 动态' });
    fireEvent.change(input, { target: { value: '  Claude 中文 & API  ' } });
    expect(requests).toHaveLength(1);
    expect(input.getAttribute('maxlength')).toBe('120');
    fireEvent.submit(screen.getByRole('search'));
    expect(requests[1].url.searchParams.get('q')).toBe('Claude 中文 & API');
    expect(requests[1].url.searchParams.has('cursor')).toBe(false);
    expect(screen.queryByRole('heading', { name: '中文标题 old' })).toBeNull();
    await respond(1, [news('match')]);
    expect(screen.getByRole('heading', { name: '中文标题 match' })).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: '清空' }));
    expect(requests[2].url.searchParams.has('q')).toBe(false);
    expect(requests[2].url.searchParams.has('cursor')).toBe(false);
    await respond(2, [news('unsearched')]);
    expect((input as HTMLInputElement).value).toBe('');
    expect(screen.getByRole('heading', { name: '中文标题 unsearched' })).toBeTruthy();
  });

  it('aborts obsolete pages and resets category, sort and time filters without mixing late responses', async () => {
    render(<NewsFeed />);
    await respond(0, [news('old')], 'old-cursor');
    fireEvent.click(screen.getByRole('button', { name: '加载更多' }));
    fireEvent.click(screen.getByRole('button', { name: '模型进展' }));
    expect(requests[1].signal.aborted).toBe(true);
    expect(requests[2].url.searchParams.get('category')).toBe('model');
    expect(requests[2].url.searchParams.has('cursor')).toBe(false);
    await respond(2, [news('current')]);
    await respond(1, [news('obsolete')], 'obsolete-cursor');
    expect(screen.queryByRole('heading', { name: '中文标题 obsolete' })).toBeNull();
    expect(screen.queryByRole('button', { name: '加载更多' })).toBeNull();
    fireEvent.click(screen.getByRole('button', { name: '🕒 最新' }));
    fireEvent.change(screen.getByRole('combobox', { name: '动态时间范围' }), { target: { value: '30' } });
    expect(requests[3].signal.aborted).toBe(true);
    expect(requests[4].url.searchParams.get('sort')).toBe('latest');
    expect(requests[4].url.searchParams.get('days')).toBe('30');
    expect(requests[4].url.searchParams.get('category')).toBe('model');
    await respond(4, [news('latest')]);
    await fail(3, '旧请求失败');
    expect(screen.queryByRole('alert')).toBeNull();
    expect(screen.getByRole('heading', { name: '中文标题 latest' })).toBeTruthy();
  });

  it('retries an initial HTTP error and shows the recovered first page', async () => {
    render(<NewsFeed />);
    await act(async () => requests[0].resolve({ ok: false, json: async () => ({ error: '服务暂不可用' }) } as Response));
    expect(screen.getByRole('alert').textContent).toContain('服务暂不可用');
    fireEvent.click(screen.getByRole('button', { name: '重试' }));
    expect(requests[1].url.searchParams.has('cursor')).toBe(false);
    await respond(1, [news('recovered')]);
    expect(screen.queryByRole('alert')).toBeNull();
    expect(screen.getByRole('heading', { name: '中文标题 recovered' })).toBeTruthy();
  });

  it('keeps loaded news on a pagination failure and retries the failed cursor', async () => {
    render(<NewsFeed />);
    await respond(0, [news('retained')], 'retry-cursor');
    fireEvent.click(screen.getByRole('button', { name: '加载更多' }));
    await fail(1);
    expect(screen.getByRole('heading', { name: '中文标题 retained' })).toBeTruthy();
    expect(screen.getByRole('alert').textContent).toContain('网络暂不可用');
    fireEvent.click(screen.getByRole('button', { name: '重试' }));
    expect(requests[2].url.searchParams.get('cursor')).toBe('retry-cursor');
    await respond(2, [news('new')]);
    expect(screen.getAllByRole('heading')).toHaveLength(2);
  });

  it('refreshes the current search from its first page and retains old results until retry succeeds', async () => {
    render(<NewsFeed />);
    await respond(0, []);
    fireEvent.change(screen.getByRole('searchbox'), { target: { value: 'Claude' } });
    fireEvent.submit(screen.getByRole('search'));
    await respond(1, [news('retained')], 'previous-cursor');
    fireEvent.click(screen.getByRole('button', { name: '刷新' }));
    expect(requests[2].url.searchParams.get('q')).toBe('Claude');
    expect(requests[2].url.searchParams.has('cursor')).toBe(false);
    expect(screen.getByRole('heading', { name: '中文标题 retained' })).toBeTruthy();
    await fail(2);
    expect(screen.getByRole('heading', { name: '中文标题 retained' })).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: '重试' }));
    expect(requests[3].url.searchParams.has('cursor')).toBe(false);
    await respond(3, [news('fresh')]);
    expect(screen.queryByRole('heading', { name: '中文标题 retained' })).toBeNull();
    expect(screen.getByRole('heading', { name: '中文标题 fresh' })).toBeTruthy();
  });

  it('shows a search-specific empty state and aborts a request when leaving the feed', async () => {
    const { unmount } = render(<NewsFeed />);
    await respond(0, []);
    fireEvent.change(screen.getByRole('searchbox'), { target: { value: '不存在的模型' } });
    fireEvent.submit(screen.getByRole('search'));
    await respond(1, []);
    expect(screen.getByText('未找到匹配的 AI 动态')).toBeTruthy();
    fireEvent.click(screen.getByRole('button', { name: '刷新' }));
    unmount();
    expect(requests[2].signal.aborted).toBe(true);
    await respond(2, [news('late')]);
  });
});
