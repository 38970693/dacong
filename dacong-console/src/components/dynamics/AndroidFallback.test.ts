// @vitest-environment jsdom
import { readFileSync } from 'node:fs';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const html = readFileSync('android/app/src/main/res/raw/news_fallback.html', 'utf8');

class FakeRequest {
  static requests: FakeRequest[] = [];
  url = '';
  headers: Record<string, string> = {};
  timeout = 0;
  status = 0;
  responseText = '';
  onload?: () => void;
  onloadend?: () => void;
  onerror?: () => void;
  ontimeout?: () => void;
  open(method: string, url: string) { expect(method).toBe('GET'); this.url = url; }
  setRequestHeader(name: string, value: string) { this.headers[name] = value; }
  send() { FakeRequest.requests.push(this); }
  respond(body: unknown, status = 200) {
    this.status = status;
    this.responseText = JSON.stringify(body);
    this.onload?.();
    this.onloadend?.();
  }
}

beforeEach(() => {
  FakeRequest.requests = [];
  vi.stubGlobal('XMLHttpRequest', FakeRequest);
  const page = new DOMParser().parseFromString(html, 'text/html');
  document.body.innerHTML = page.body.innerHTML;
  const script = page.querySelector('script')!.textContent!
    .replace('__PUBLIC_NEWS_CONFIG__', JSON.stringify({ url: 'https://news.supabase.co', key: 'public-test-key' }));
  window.eval(script);
});

afterEach(() => { vi.unstubAllGlobals(); document.body.innerHTML = ''; });

describe('Android bundled fallback', () => {
  it('shows loading immediately and requests only published news with the public key', () => {
    expect(document.querySelector('#status')!.textContent).toContain('正在加载');
    expect((document.querySelector('#refresh') as HTMLButtonElement).disabled).toBe(true);
    const request = FakeRequest.requests[0];
    const url = new URL(request.url);
    expect(url.origin).toBe('https://news.supabase.co');
    expect(url.searchParams.get('status')).toBe('eq.published');
    expect(url.searchParams.get('limit')).toBe('30');
    expect(url.searchParams.get('order')).toBe('published_at.desc,id.desc');
    expect(request.headers).toEqual({ apikey: 'public-test-key', Authorization: 'Bearer public-test-key' });
    expect(request.timeout).toBe(15000);
  });

  it('defaults to Chinese, switches to the original and keeps a safe source link', () => {
    FakeRequest.requests[0].respond([{ title: 'New model', summary: 'Model details', title_zh: '新模型', summary_zh: '模型详情', published_at: '2026-10-23',
      ai_news_sources: [{ url: 'https://example.com/news', is_primary: true }] }]);
    expect(document.querySelector('h2')!.textContent).toBe('新模型');
    const toggle = document.querySelector('article button') as HTMLButtonElement;
    expect(toggle.textContent).toBe('查看原文');
    toggle.click();
    expect(document.querySelector('h2')!.textContent).toBe('New model');
    expect(toggle.textContent).toBe('翻译成中文');
    toggle.click();
    expect(document.querySelector('h2')!.textContent).toBe('新模型');
    expect(document.querySelector('article a')!.getAttribute('href')).toBe('https://example.com/news');
  });

  it('keeps existing news on network failure and allows retry after a timeout', () => {
    FakeRequest.requests[0].respond([{ title: 'Original news', summary: 'Details' }]);
    const refresh = document.querySelector('#refresh') as HTMLButtonElement;
    refresh.click();
    FakeRequest.requests[1].ontimeout?.();
    FakeRequest.requests[1].onloadend?.();
    expect(document.querySelector('#status')!.textContent).toContain('检查网络');
    expect(document.querySelector('h2')!.textContent).toBe('Original news');
    expect(refresh.disabled).toBe(false);
    refresh.click();
    FakeRequest.requests[2].respond([]);
    expect(document.querySelector('#status')!.textContent).toBe('暂无已发布资讯');
  });

  it('renders external content as text and rejects unsafe source protocols', () => {
    FakeRequest.requests[0].respond([{ title: '<img src=x onerror=alert(1)>', summary: '<script>alert(1)</script>',
      ai_news_sources: [{ url: 'javascript:alert(1)', is_primary: true }] }]);
    expect(document.querySelector('article img')).toBeNull();
    expect(document.querySelector('article script')).toBeNull();
    expect(document.querySelector('article a')).toBeNull();
    expect(document.querySelector('h2')!.textContent).toContain('<img');
  });
});
