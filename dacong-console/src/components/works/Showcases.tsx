'use client';

import Link from 'next/link';
import { useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createSupabaseClient } from '@/utils/supabase/client';
import { Showcase, showcaseInput } from '@/lib/showcase';

const button = 'inline-flex min-h-11 items-center justify-center rounded-xl border border-[var(--border)] px-4 py-2 text-sm font-medium text-[var(--primary)] disabled:opacity-50';
const field = 'w-full min-w-0 rounded-xl border border-[var(--border)] bg-[var(--background)] p-3 text-sm';

function Experience({ item }: { item: Showcase }) {
  return <div className="flex flex-wrap gap-2">
    {item.demo_url && <a className={button + ' bg-[var(--primary)] text-white'} href={item.demo_url} target="_blank" rel="noopener noreferrer">立即体验 ↗</a>}
    {item.source_url && <a className={button} href={item.source_url} target="_blank" rel="noopener noreferrer">查看源码 ↗</a>}
  </div>;
}

export function ShowcaseFeed() {
  const db = useMemo(() => createSupabaseClient(), []);
  const [kind, setKind] = useState('all');
  const [items, setItems] = useState<Showcase[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [more, setMore] = useState(false);
  const [revision, setRevision] = useState(0);
  const generation = useRef(0);
  const active = useRef(false);
  const offset = useRef(0);
  async function load(append = false, version = generation.current) {
    if (active.current) return;
    active.current = true; setBusy(true); setError('');
    const start = append ? offset.current : 0;
    let query = db.from('ai_showcases').select('*').eq('status', 'published');
    if (kind !== 'all') query = query.eq('kind', kind);
    const { data, error: failed } = await query.order('created_at', { ascending: false }).order('id', { ascending: false }).range(start, start + 12);
    if (generation.current !== version) return;
    active.current = false; setBusy(false);
    if (failed) { setError('作品暂时无法加载，请重试'); return; }
    const page = (data ?? []).slice(0, 12) as Showcase[];
    setItems(previous => append ? [...new Map([...previous, ...page].map(item => [item.id, item])).values()] : page);
    offset.current = start + page.length; setMore((data ?? []).length > 12);
  }
  useEffect(() => {
    const version = ++generation.current; active.current = false; offset.current = 0; setItems([]); setMore(false);
    void load(false, version);
    return () => { if (generation.current === version) { generation.current = version + 1; active.current = false; } };
    // kind and revision explicitly restart the feed.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [kind, revision]);
  return <section className="min-w-0">
    <header className="border-b border-[var(--border)] p-5">
      <p className="text-xs font-semibold tracking-widest text-[var(--primary)]">AI × 创造力</p>
      <h1 className="mt-2 text-2xl font-bold">把想法变成可体验的作品</h1>
      <p className="mt-2 text-sm leading-6 text-[var(--text-secondary)]">发现 AI 做出来的工具、互动体验与创作，也欢迎分享还在萌芽的好点子。</p>
      <Link href="/web/works/new" className={button + ' mt-4 bg-[var(--primary)] text-white'}>＋ 分享作品 / 创意</Link>
    </header>
    <nav aria-label="作品筛选" className="flex gap-2 overflow-x-auto p-4">{[['all', '全部'], ['work', '可体验作品'], ['idea', '创意提案']].map(([value, label]) => <button key={value} aria-pressed={kind === value} className={button + (kind === value ? ' bg-[var(--primary-light)]' : '')} onClick={() => setKind(value)}>{label}</button>)}</nav>
    {error && <div role="alert" className="px-5 py-3 text-red-600">{error} <button className={button} onClick={() => void load(items.length > 0)}>重试</button></div>}
    {!busy && !error && !items.length && <div className="px-5 py-14 text-center"><h2 className="font-semibold">这里期待你的第一个分享</h2><p className="mt-2 text-sm text-[var(--text-secondary)]">一个 AI 小工具、一段互动体验，或一个值得一起实现的想法。</p><Link className={button + ' mt-4'} href="/web/works/new">开始分享</Link></div>}
    <div className="space-y-4 px-4 pb-4">{items.map(item => <article key={item.id} className="rounded-2xl border border-[var(--border)] p-5 [overflow-wrap:anywhere]">
      <span className="rounded-full bg-[var(--primary-light)] px-3 py-1 text-xs text-[var(--primary)]">{item.kind === 'work' ? '✦ 可体验作品' : '✧ 创意提案'}</span>
      <Link className="mt-3 block text-lg font-bold" href={`/web/works/${item.id}`}>{item.title}</Link>
      <p className="my-3 text-sm leading-6 text-[var(--text-secondary)]">{item.summary}</p>
      <p className="mb-4 text-xs text-[var(--text-muted)]">{item.creator_name} 分享 · {new Date(item.created_at).toLocaleDateString('zh-CN')}</p>
      <div className="flex flex-wrap gap-2"><Experience item={item} /><Link className={button} href={`/web/works/${item.id}`}>查看详情</Link></div>
    </article>)}</div>
    {busy && <p role="status" className="p-5 text-center text-sm">加载中…</p>}
    {more && !error && <div className="pb-6 text-center"><button className={button} disabled={busy} onClick={() => void load(true)}>加载更多</button></div>}
    <button className={button + ' mx-4 mb-4'} disabled={busy} onClick={() => setRevision(value => value + 1)}>刷新</button>
  </section>;
}

export function ShowcaseForm() {
  const db = useMemo(() => createSupabaseClient(), []);
  const router = useRouter();
  const [kind, setKind] = useState('work');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [loginRequired, setLoginRequired] = useState(false);
  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault(); if (busy) return;
    setBusy(true); setError(''); setLoginRequired(false);
    const input = Object.fromEntries(new FormData(event.currentTarget));
    try {
      const clean = showcaseInput(input);
      const { data: { user }, error: authError } = await db.auth.getUser();
      if (authError || !user) { setLoginRequired(true); throw new Error('请先登录，再分享你的作品或创意。填写内容会暂时保留在此页面。'); }
      const { data, error: failed } = await db.from('ai_showcases').insert({ ...clean, user_id: user.id }).select('id').single();
      if (failed) throw new Error('发布失败，请稍后重试');
      router.push(`/web/works/${data.id}`);
    } catch (reason) { setError(reason instanceof Error ? reason.message : '发布失败，请重试'); }
    finally { setBusy(false); }
  }
  return <section className="p-5">
    <Link href="/web/works" className="text-sm text-[var(--primary)]">← 返回作品广场</Link>
    <h1 className="mt-5 text-2xl font-bold">分享你的 AI 创造</h1>
    <p className="mt-2 text-sm text-[var(--text-secondary)]">分享可体验的成果，或邀请大家一起实现你的想法。</p>
    <form className="mt-6 space-y-5" onSubmit={submit}>
      <label className="block">分享类型<select name="kind" value={kind} onChange={event => setKind(event.target.value)} className={field + ' mt-2'}><option value="work">可体验作品</option><option value="idea">创意提案</option></select></label>
      <label className="block">标题<input name="title" required maxLength={80} className={field + ' mt-2'} placeholder="你的作品或想法叫什么？" /></label>
      <label className="block">一句话介绍<textarea name="summary" required maxLength={300} rows={3} className={field + ' mt-2'} placeholder="它能帮助谁，解决什么问题？" /></label>
      <label className="block">实现说明 / 创意详情<textarea name="content" maxLength={5000} rows={7} className={field + ' mt-2'} placeholder="用了哪些 AI 能力？如何体验？还有哪些想法希望一起完成？" /></label>
      <label className="block">体验地址{kind === 'work' ? '（必填）' : '（可选）'}<input name="demo_url" type="url" required={kind === 'work'} maxLength={2000} className={field + ' mt-2'} placeholder="https://…" /></label>
      <label className="block">源码地址（可选）<input name="source_url" type="url" maxLength={2000} className={field + ' mt-2'} placeholder="https://github.com/…" /></label>
      <label className="block">分享者昵称<input name="creator_name" required maxLength={40} className={field + ' mt-2'} placeholder="展示给大家的名字，请勿填写私人联系方式" /></label>
      <p className="text-xs leading-5 text-[var(--text-muted)]">发布后所有人可见。请注明原创或引用关系；体验链接会在外部页面打开。</p>
      {error && <p role="alert" className="text-sm text-red-600">{error}</p>}
      {loginRequired && <Link href="/web/auth/login" target="_blank" rel="noopener noreferrer" className={button}>在新页登录，完成后返回发布</Link>}
      <button className={button + ' w-full bg-[var(--primary)] text-white'} disabled={busy}>{busy ? '发布中…' : '发布分享'}</button>
    </form>
  </section>;
}

export function ShowcaseDetail({ id }: { id: string }) {
  const db = useMemo(() => createSupabaseClient(), []);
  const [item, setItem] = useState<Showcase | null>(null);
  const [owner, setOwner] = useState(false);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    let alive = true;
    void (async () => {
      const { data, error } = await db.from('ai_showcases').select('*').eq('id', id).maybeSingle();
      if (!alive) return;
      if (error || !data) { setError('这条分享不存在或已被撤回'); return; }
      setItem(data as Showcase);
      const { data: { user } } = await db.auth.getUser();
      if (alive) setOwner(user?.id === data.user_id);
    })();
    return () => { alive = false; };
  }, [db, id]);
  async function withdraw() {
    if (!item || busy) return;
    setBusy(true);
    const { data, error } = await db.from('ai_showcases').update({ status: 'withdrawn' }).eq('id', item.id).select('id');
    setBusy(false);
    if (error || !data?.length) setError('撤回失败，请重试');
    else setItem({ ...item, status: 'withdrawn' });
  }
  return <article className="p-5 [overflow-wrap:anywhere]">
    <Link href="/web/works" className="text-sm text-[var(--primary)]">← 返回作品广场</Link>
    {error && <p role="alert" className="my-5 text-red-600">{error}</p>}
    {!item && !error && <p role="status" className="py-10">加载中…</p>}
    {item && <><p className="mt-6 text-sm text-[var(--primary)]">{item.kind === 'work' ? '可体验作品' : '创意提案'}{item.status === 'withdrawn' && ' · 已撤回'}</p>
      <h1 className="mt-2 text-2xl font-bold">{item.title}</h1><p className="mt-2 text-xs text-[var(--text-muted)]">{item.creator_name} 分享 · {new Date(item.created_at).toLocaleDateString('zh-CN')}</p>
      <p className="my-6 text-base leading-7">{item.summary}</p>
      {item.status === 'published' && <Experience item={item} />}
      <h2 className="mb-3 mt-8 font-semibold">{item.kind === 'work' ? '作品说明' : '创意详情'}</h2>
      <p className="whitespace-pre-wrap text-sm leading-7 text-[var(--text-secondary)]">{item.content || '分享者暂未补充详细说明。'}</p>
      {owner && item.status === 'published' && <button disabled={busy} onClick={() => void withdraw()} className={button + ' mt-8'}>{busy ? '撤回中…' : '撤回我的分享'}</button>}
    </>}
  </article>;
}
