/**
 * 主题 Store - 管理亮色/暗色/系统主题
 */
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

type ThemeMode = 'light' | 'dark' | 'system';
type ResolvedTheme = 'light' | 'dark';

interface ThemeState {
  mode: ThemeMode;
  resolved: ResolvedTheme;
  setMode: (mode: ThemeMode) => void;
  init: () => void;
}

function getSystemTheme(): ResolvedTheme {
  if (typeof window !== 'undefined' && window.matchMedia) {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  return 'light';
}

function resolveTheme(mode: ThemeMode): ResolvedTheme {
  if (mode === 'system') {
    return getSystemTheme();
  }
  return mode;
}

function applyTheme(theme: ResolvedTheme) {
  const root = document.documentElement;
  if (theme === 'dark') {
    root.classList.add('dark');
  } else {
    root.classList.remove('dark');
  }
}

export const useThemeStore = create<ThemeState>()(
  persist(
    (set, get) => ({
      mode: 'system',
      resolved: 'light',

      setMode: (mode: ThemeMode) => {
        const resolved = resolveTheme(mode);
        applyTheme(resolved);
        set({ mode, resolved });
      },

      init: () => {
        const { mode } = get();
        const resolved = resolveTheme(mode);
        applyTheme(resolved);
        set({ resolved });

        // 监听系统主题变化
        if (typeof window !== 'undefined' && window.matchMedia) {
          window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
            const { mode } = get();
            if (mode === 'system') {
              const resolved = e.matches ? 'dark' : 'light';
              applyTheme(resolved);
              set({ resolved });
            }
          });
        }
      }
    }),
    {
      name: 'dacong-theme',
      onRehydrateStorage: () => (state) => {
        if (state) {
          const resolved = resolveTheme(state.mode);
          applyTheme(resolved);
          state.resolved = resolved;
        }
      }
    }
  )
);
