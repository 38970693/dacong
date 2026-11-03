export interface Showcase {
  id: string; user_id: string; kind: 'work' | 'idea'; title: string; summary: string;
  content: string; creator_name: string; demo_url: string | null; source_url: string | null;
  status: 'published' | 'withdrawn'; created_at: string;
}

export function showcaseInput(input: Record<string, unknown>) {
  function text(name: string, max: number, required = true) {
    const value = typeof input[name] === 'string' ? input[name].trim() : '';
    if ((required && !value) || value.length > max) throw new Error('请填写完整内容，并遵守字数限制');
    return value;
  }
  function link(name: string) {
    const value = text(name, 2000, false);
    if (!value) return null;
    try {
      const url = new URL(value);
      if (url.protocol !== 'https:' || url.username || url.password) throw new Error();
      return url.href;
    } catch { throw new Error('体验和源码地址需为有效的 HTTPS 链接'); }
  }
  if (input.kind !== 'work' && input.kind !== 'idea') throw new Error('请选择作品或创意');
  const result = { kind: input.kind, title: text('title', 80), summary: text('summary', 300),
    content: text('content', 5000, false), creator_name: text('creator_name', 40),
    demo_url: link('demo_url'), source_url: link('source_url') };
  if (result.kind === 'work' && !result.demo_url) throw new Error('请为可体验作品填写体验地址');
  return result;
}
