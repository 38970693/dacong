'use client';

import { useEffect, useMemo, useState } from 'react';

interface Series {
  model: string;
  vendor: string | null;
  benchmark: string;
  points: Array<{ date: string; score: number }>;
}

/** 单个模型的评测历史折线（无第三方图表依赖） */
function TrendLine({ points }: { points: Array<{ date: string; score: number }> }) {
  if (points.length < 2) {
    return (
      <p className="text-[11px] text-[var(--text-muted)]">
        仅有 1 个数据点，累积多次评测后才会形成曲线
      </p>
    );
  }

  const W = 260;
  const H = 56;
  const pad = 4;
  const scores = points.map((p) => p.score);
  const min = Math.min(...scores);
  const max = Math.max(...scores);
  const span = max - min || 1;

  const d = points
    .map((p, i) => {
      const x = (i / (points.length - 1)) * W;
      const y = pad + (H - pad * 2) - ((p.score - min) / span) * (H - pad * 2);
      return `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`;
    })
    .join(' ');

  return (
    <div>
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full h-14" role="img" aria-label="评测历史曲线">
        <path d={d} fill="none" stroke="var(--primary)" strokeWidth="1.5" strokeLinejoin="round" />
      </svg>
      <div className="flex justify-between text-[10px] text-[var(--text-muted)]">
        <span>{points[0].date}</span>
        <span>
          {min.toFixed(1)} → {max.toFixed(1)}
        </span>
        <span>{points[points.length - 1].date}</span>
      </div>
    </div>
  );
}

export function ModelPulse() {
  const [series, setSeries] = useState<Series[]>([]);
  const [benchmarks, setBenchmarks] = useState<string[]>([]);
  const [benchmark, setBenchmark] = useState<string>('');
  const [selected, setSelected] = useState<string>('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    fetch('/api/dynamics/pulse?days=365')
      .then((r) => r.json())
      .then((j) => {
        if (cancelled) return;
        setSeries(j.data?.series ?? []);
        const bs: string[] = j.data?.benchmarks ?? [];
        setBenchmarks(bs);
        if (bs.length) setBenchmark(bs[0]);
      })
      .catch(() => !cancelled && setSeries([]))
      .finally(() => !cancelled && setLoading(false));

    return () => {
      cancelled = true;
    };
  }, []);

  // 当前 benchmark 下，各模型的最新一次得分（降序）
  const ranking = useMemo(() => {
    return series
      .filter((s) => s.benchmark === benchmark && s.points.length > 0)
      .map((s) => ({
        model: s.model,
        latest: s.points[s.points.length - 1].score,
      }))
      .sort((a, b) => b.latest - a.latest);
  }, [series, benchmark]);

  const maxScore = ranking[0]?.latest || 1;

  const selectedSeries = series.find((s) => s.benchmark === benchmark && s.model === selected);

  if (loading) {
    return <div className="px-4 py-8 text-center text-sm text-[var(--text-muted)]">加载中…</div>;
  }

  if (series.length === 0) {
    return (
      <div className="px-4 py-8 text-center text-sm text-[var(--text-muted)]">
        暂无评测数据。需先运行 aggregate-evaluations 聚合各榜单分数。
      </div>
    );
  }

  return (
    <div>
      <div className="flex gap-2 px-4 py-3 overflow-x-auto">
        {benchmarks.map((b) => (
          <button
            key={b}
            onClick={() => {
              setBenchmark(b);
              setSelected('');
            }}
            className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-colors ${
              benchmark === b
                ? 'bg-[var(--primary)] text-white'
                : 'border border-[var(--border)] text-[var(--text-secondary)]'
            }`}
          >
            {b}
          </button>
        ))}
      </div>

      <ul className="px-4 pb-2 space-y-1.5">
        {ranking.map((r) => (
          <li key={r.model}>
            <button
              onClick={() => setSelected(r.model === selected ? '' : r.model)}
              className="w-full text-left"
            >
              <div className="flex items-center justify-between text-xs mb-1">
                <span
                  className={`truncate ${selected === r.model ? 'text-[var(--primary)] font-semibold' : 'text-[var(--foreground)]'}`}
                >
                  {r.model}
                </span>
                <span className="text-[var(--text-muted)] shrink-0 ml-2">
                  {r.latest.toFixed(1)}
                </span>
              </div>
              <div className="h-1.5 rounded-full bg-[var(--surface)] overflow-hidden">
                <div
                  className="h-full rounded-full bg-[var(--primary)]"
                  style={{ width: `${Math.max(2, (r.latest / maxScore) * 100)}%` }}
                />
              </div>
            </button>

            {selected === r.model && selectedSeries && (
              <div className="mt-2 mb-3 pl-2 border-l-2 border-[var(--primary)]/30">
                <TrendLine points={selectedSeries.points} />
              </div>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
