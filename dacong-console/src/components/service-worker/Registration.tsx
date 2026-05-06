/**
 * Service Worker Registration
 * 注册 Service Worker 用于离线缓存和后台同步
 */
'use client';

import { useEffect } from 'react';

export function ServiceWorkerRegistration() {
  useEffect(() => {
    if (typeof window !== 'undefined' && 'serviceWorker' in navigator) {
      // 仅在生产环境注册 Service Worker
      if (process.env.NODE_ENV === 'production') {
        window.addEventListener('load', () => {
          navigator.serviceWorker
            .register('/sw.js')
            .then((registration) => {
              console.log('SW registered:', registration.scope);
            })
            .catch((error) => {
              console.log('SW registration failed:', error);
            });
        });
      }
    }
  }, []);

  return null;
}