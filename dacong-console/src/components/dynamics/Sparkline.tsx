'use client';

/**
 * 极简 SVG 迷你趋势图（无第三方图表依赖）
 * 用于飙升榜的 star 走势与模型脉搏的评测曲线
 */
export function Sparkline({
  points,
  width = 88,
  height = 28,
  strokeWidth = 1.5,
}: {
  points: number[];
  width?: number;
  height?: number;
  strokeWidth?: number;
}) {
  if (points.length < 2) {
    return <div className="w-[88px] h-[28px]" />;
  }

  const min = Math.min(...points);
  const max = Math.max(...points);
  const span = max - min || 1;
  const pad = 2;
  const innerH = height - pad * 2;

  const d = points
    .map((p, i) => {
      const x = (i / (points.length - 1)) * width;
      const y = pad + innerH - ((p - min) / span) * innerH;
      return `${i === 0 ? 'M' : 'L'}${x.toFixed(1)},${y.toFixed(1)}`;
    })
    .join(' ');

  const rising = points[points.length - 1] >= points[0];

  return (
    <svg
      width={width}
      height={height}
      viewBox={`0 0 ${width} ${height}`}
      className="shrink-0"
      role="img"
      aria-label={`趋势图，${points.length} 个数据点`}
    >
      <path
        d={d}
        fill="none"
        stroke={rising ? 'var(--success, #22c55e)' : 'var(--danger, #ef4444)'}
        strokeWidth={strokeWidth}
        strokeLinejoin="round"
        strokeLinecap="round"
      />
    </svg>
  );
}
