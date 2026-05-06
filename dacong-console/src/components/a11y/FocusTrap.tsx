'use client';

/**
 * Focus Trap - 模态框焦点管理 (WCAG 2.1 AA)
 * 确保模态框打开时焦点被限制在框内
 */
import { useEffect, useRef, useCallback } from 'react';

const FOCUSABLE_SELECTORS = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
  'audio[controls]',
  'video[controls]',
  '[contenteditable]:not([contenteditable="false"])',
].join(', ');

interface UseFocusTrapOptions {
  /**
   * 是否激活焦点陷阱
   */
  active?: boolean;
  /**
   * 初始聚焦的元素选择器
   */
  initialFocus?: string;
  /**
   * 允许焦点返回的元素
   */
  returnFocus?: 'auto' | ((previousFocus: HTMLElement | null) => HTMLElement | null);
}

/**
 * Focus Trap Hook
 * @param options 配置选项
 * @returns focusTrapRef - 绑定到容器元素
 */
export function useFocusTrap<T extends HTMLElement>(options: UseFocusTrapOptions = {}) {
  const { active = true, initialFocus, returnFocus } = options;
  const containerRef = useRef<T>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  const getFocusableElements = useCallback((): HTMLElement[] => {
    if (!containerRef.current) return [];
    return Array.from(containerRef.current.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTORS));
  }, []);

  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    if (!active || e.key !== 'Tab') return;

    const focusable = getFocusableElements();
    if (focusable.length === 0) return;

    const first = focusable[0];
    const last = focusable[focusable.length - 1];

    // Shift + Tab: 如果在第一个元素上，跳到最后
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
      return;
    }

    // Tab: 如果在最后一个元素上，跳到第一个
    if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  }, [active, getFocusableElements]);

  useEffect(() => {
    if (!active) return;

    // 保存当前焦点元素
    previousFocusRef.current = document.activeElement as HTMLElement;

    // 如果指定了初始聚焦元素，聚焦它
    if (initialFocus && containerRef.current) {
      const element = containerRef.current.querySelector<HTMLElement>(initialFocus);
      element?.focus();
    } else {
      // 否则聚焦到第一个可聚焦元素
      const focusable = getFocusableElements();
      if (focusable.length > 0) {
        focusable[0].focus();
      } else if (containerRef.current) {
        // 如果没有可聚焦元素，聚焦到容器本身
        containerRef.current.setAttribute('tabindex', '-1');
        containerRef.current.focus();
      }
    }

    // 添加键盘事件监听
    document.addEventListener('keydown', handleKeyDown);

    return () => {
      document.removeEventListener('keydown', handleKeyDown);

      // 恢复焦点
      if (returnFocus !== null) {
        const target = typeof returnFocus === 'function'
          ? returnFocus(previousFocusRef.current)
          : returnFocus || previousFocusRef.current;
        (target as HTMLElement)?.focus();
      }
    };
  }, [active, initialFocus, returnFocus, handleKeyDown, getFocusableElements]);

  return containerRef;
}

/**
 * Focus Trap Provider Component
 * 用于包装模态框等需要焦点陷阱的组件
 */
interface FocusTrapProps {
  active?: boolean;
  children: React.ReactNode;
  className?: string;
}

export function FocusTrap({ active = true, children, className }: FocusTrapProps) {
  const containerRef = useFocusTrap<HTMLDivElement>({ active });

  return (
    <div ref={containerRef} className={className} tabIndex={-1}>
      {children}
    </div>
  );
}