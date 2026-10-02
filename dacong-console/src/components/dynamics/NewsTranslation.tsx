'use client';

import Link from 'next/link';
import { useState } from 'react';
import { AINewsItem } from '@/types/dynamics';

export function NewsTranslation({ item, href, detail = false }: {
  item: AINewsItem;
  href?: string;
  detail?: boolean;
}) {
  const [translated, setTranslated] = useState(false);
  const canTranslate = !!item.title_zh?.trim() && (!item.summary.trim() || !!item.summary_zh?.trim());
  const title = translated ? item.title_zh : item.title;
  const summary = translated ? item.summary_zh || item.summary : item.summary;
  const content = (
    <div className="min-w-0 [overflow-wrap:anywhere]" lang={translated ? 'zh-CN' : item.language === 'en' ? 'en' : undefined}>
      {detail
        ? <h1 className="mt-3 text-2xl font-bold leading-tight text-[var(--foreground)]">{title}</h1>
        : <h2 className="font-semibold leading-snug text-[var(--foreground)]">{title}</h2>}
      {summary && <p className={detail
        ? 'mt-5 leading-7 text-[var(--text-secondary)]'
        : 'mt-2 text-sm leading-relaxed text-[var(--text-secondary)] line-clamp-3'}>{summary}</p>}
    </div>
  );
  return (
    <div>
      {href ? <Link href={href} className="block">{content}</Link> : content}
      {item.language !== 'zh' && <div className="mt-2 flex flex-wrap items-center gap-2">
        <button type="button" onClick={() => setTranslated(!translated)} disabled={!canTranslate}
          aria-pressed={translated}
          className="min-h-10 rounded-lg border border-[var(--border)] px-3 text-xs text-[var(--primary)] hover:bg-[var(--primary-light)] disabled:cursor-not-allowed disabled:text-[var(--text-muted)] disabled:hover:bg-transparent">
          {translated ? '查看原文' : '翻译成中文'}
        </button>
        {!canTranslate && <span className="text-xs text-[var(--text-muted)]">暂无中文译文</span>}
      </div>}
    </div>
  );
}
