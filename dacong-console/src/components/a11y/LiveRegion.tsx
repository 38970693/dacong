'use client';

/**
 * LiveRegion - 屏幕阅读器实时公告组件 (WCAG 2.1 AA)
 * 用于向屏幕阅读器用户播报动态内容变化
 */
import { useEffect, useRef, useState } from 'react';

interface LiveRegionProps {
  /**
   * 播报模式: 'polite' 等待用户空闲, 'assertive' 立即中断
   */
  politeness?: 'polite' | 'assertive';
  /**
   * 是否启用（避免不必要的播报）
   */
  enabled?: boolean;
}

export function LiveRegion({ politeness = 'polite', enabled = true }: LiveRegionProps) {
  const [message, setMessage] = useState('');
  const timeoutRef = useRef<NodeJS.Timeout | undefined>(undefined);

  useEffect(() => {
    if (!enabled) return;

    // 创建一个全局函数用于外部调用
    (window as unknown as { announce: (message: string) => void }).announce = (message: string) => {
      // 清除之前的超时
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }

      // 短暂延迟确保屏幕阅读器能检测到变化
      setMessage('');
      timeoutRef.current = setTimeout(() => {
        setMessage(message);
      }, 100);
    };

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      delete (window as unknown as { announce?: (message: string) => void }).announce;
    };
  }, [enabled]);

  return (
    <div
      role="status"
      aria-live={politeness}
      aria-atomic="true"
      className="sr-only"
    >
      {message}
    </div>
  );
}

// 便捷函数：全局播报消息
export function announce(message: string, politeness: 'polite' | 'assertive' = 'polite') {
  if (typeof window !== 'undefined') {
    const win = window as unknown as { announce?: (msg: string) => void };
    if (win.announce) {
      win.announce(message);
    }
  }
}