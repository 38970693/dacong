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
  const canTranslate = item.language !== 'zh' && !!item.title_zh && !!item.summary_zh;
  const title = translated ? item.title_zh : item.title;
  const summary = translated ? item.summary_zh : item.summary;
  const content = (
    <div lang={translated ? 'zh-CN' : item.language === 'en' ? 'en' : undefined}>
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
      {canTranslate && <button type="button" onClick={() => setTranslated(!translated)}
        aria-pressed={translated}
        className="mt-2 text-xs text-[var(--primary)] hover:underline">
        {translated ? '查看原文' : '翻译成中文'}
      </button>}
    </div>
  );
}
