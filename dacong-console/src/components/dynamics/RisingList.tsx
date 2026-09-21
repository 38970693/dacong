'use client';

import { useEffect, useState } from 'react';
import { Sparkline } from './Sparkline';

interface RisingRepo {
  repo_name: string;
  repo_url: string;
  owner?: string;
  language?: string | null;
  description?: string | null;
  total_stars?: number;
  stars_1d?: number;
  stars_7d?: number;
  stars_30d?: number;
  velocity?: number;
  snapshot_date?: string;
}

/** 由「总星数 + 各窗口增量」倒推历史点位，用于画走势 */
function buildTrend(r: RisingRepo): number[] {
  const total = r.total_stars ?? 0;
  return [
    total - (r.stars_30d ?? 0),
    total - (r.stars_7d ?? 0),
    total - (r.stars_1d ?? 0),
    total,
  ].map((v) => Math.max(0, v));
}

export function RisingList() {
  const [repos, setRepos] = useState<RisingRepo[]>([]);
  const [loading, setLoading] = useState(true);
  const [snapshot, setSnapshot] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);

    fetch('/api/dynamics/rising?limit=25&sort=velocity')
      .then((r) => r.json())
      .then((j) => {
        if (cancelled) return;
        setRepos(j.data ?? []);
        setSnapshot(j.meta?.snapshot_date ?? null);
      })
      .catch(() => !cancelled && setRepos([]))
      .finally(() => !cancelled && setLoading(false));

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div>
      <div className="flex items-center gap-2 px-4 py-3 text-xs text-[var(--text-muted)]">
        <span>按涨速 velocity 排序</span>
        {snapshot && <span className="ml-auto">快照 {snapshot}</span>}
      </div>

      {loading && (
        <div className="px-4 py-8 text-center text-sm text-[var(--text-muted)]">加载中…</div>
      )}

      {!loading && repos.length === 0 && (
        <div className="px-4 py-8 text-center text-sm text-[var(--text-muted)]">
          暂无飙升数据。需先运行 compute-rising-stars 生成快照。
        </div>
      )}

      <ul className="divide-y divide-[var(--border)]">
        {repos.map((r, i) => (
          <li key={r.repo_name} className="px-4 py-3 flex items-start gap-3">
            <span className="w-6 text-center text-sm font-semibold text-[var(--text-muted)] shrink-0">
              {i + 1}
            </span>

            <div className="min-w-0 flex-1">
              <a
                href={r.repo_url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm font-medium text-[var(--foreground)] hover:text-[var(--primary)] truncate block"
              >
                {r.repo_name}
              </a>
              {r.description && (
                <p className="mt-0.5 text-xs text-[var(--text-muted)] line-clamp-1">
                  {r.description}
                </p>
              )}
              <div className="mt-1.5 flex items-center gap-3 text-[11px] text-[var(--text-secondary)]">
                {r.language && <span>{r.language}</span>}
                <span>★ {(r.total_stars ?? 0).toLocaleString()}</span>
                <span className="text-[var(--success, #22c55e)]">
                  +{r.stars_7d ?? 0} / 7d
                </span>
                <span className="text-[var(--text-muted)]">
                  速度 {(r.velocity ?? 0).toFixed(1)}/天
                </span>
              </div>
            </div>

            <Sparkline points={buildTrend(r)} />
          </li>
        ))}
      </ul>
    </div>
  );
}
