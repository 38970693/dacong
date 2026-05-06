'use client';

/**
 * SkipLink - 跳转到主内容的链接 (WCAG 2.1 AA 要求)
 * 让键盘用户快速跳过导航到达主要内容
 */
import { useEffect, useState } from 'react';

export function SkipLink() {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // 当用户按 Tab 时显示 skip link
      if (e.key === 'Tab') {
        setIsVisible(true);
      }
    };

    const handleClick = () => {
      setIsVisible(false);
    };

    document.addEventListener('keydown', handleKeyDown);
    document.addEventListener('click', handleClick);

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.removeEventListener('click', handleClick);
    };
  }, []);

  return (
    <a
      href="#main-content"
      className={`
        fixed top-4 left-4 z-[100] px-4 py-2 bg-[var(--primary)] text-white font-semibold rounded-lg
        shadow-lg transition-opacity duration-200
        focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[var(--primary)]
        ${isVisible ? 'opacity-100' : 'opacity-0 -translate-y-full'}
        hover:opacity-100 hover:translate-y-0
      `}
      style={{ transform: isVisible ? 'translateY(0)' : 'translateY(-100%)' }}
    >
      跳转到主要内容
    </a>
  );
}