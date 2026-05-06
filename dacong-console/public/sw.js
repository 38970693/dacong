/**
 * DaCong Service Worker
 * 离线缓存、后台同步、推送通知支持
 */

// 缓存版本
const CACHE_NAME = 'dacong-v1';

// 需要缓存的静态资源
const STATIC_ASSETS = [
  '/',
  '/web',
  '/index.html',
  '/manifest.json',
  // CSS 和 JS 会在安装时自动缓存
];

// 外部资源域名（允许跨域缓存）
const ALLOWED_ORIGINS = [
  'https://prszkdbdgffbdqclbgol.supabase.co',
  'https://www.google.com',
  'fonts.googleapis.com',
  'fonts.gstatic.com',
];

// 安装事件 - 缓存静态资源
self.addEventListener('install', (event) => {
  console.log('[SW] Installing...');
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Caching static assets');
      return cache.addAll(STATIC_ASSETS);
    })
  );
  // 立即激活
  self.skipWaiting();
});

// 激活事件 - 清理旧缓存
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      );
    })
  );
  // 立即接管所有页面
  self.clients.claim();
});

// 请求拦截 - 缓存优先策略
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // 仅处理同源和允许的跨域请求
  const isAllowed = url.origin === self.location.origin ||
    ALLOWED_ORIGINS.some(origin => url.hostname.includes(origin));

  if (!isAllowed) return;

  // 对于同源请求，使用缓存优先策略
  if (url.origin === self.location.origin) {
    event.respondWith(
      caches.match(request).then((cachedResponse) => {
        if (cachedResponse) {
          return cachedResponse;
        }

        return fetch(request).then((response) => {
          // 不缓存非成功响应
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }

          // 缓存响应
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(request, responseToCache);
          });

          return response;
        }).catch(() => {
          // 离线时返回缓存的首页
          if (request.mode === 'navigate') {
            return caches.match('/') || caches.match('/web');
          }
          return new Response('Offline', { status: 503 });
        });
      })
    );
  } else {
    // 跨域请求（如 Supabase API），使用网络优先策略
    event.respondWith(
      fetch(request).catch(() => {
        return caches.match(request);
      })
    );
  }
});

// 后台同步（如果浏览器支持）
self.addEventListener('sync', (event) => {
  console.log('[SW] Background sync:', event.tag);
  if (event.tag === 'sync-favorites') {
    event.waitUntil(syncFavorites());
  }
});

// 推送通知
self.addEventListener('push', (event) => {
  console.log('[SW] Push received');

  const options = {
    body: event.data?.text() || '您有新通知',
    icon: '/favicon.ico',
    badge: '/favicon.ico',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1,
    },
    actions: [
      { action: 'view', title: '查看' },
      { action: 'close', title: '关闭' },
    ],
  };

  event.waitUntil(
    self.registration.showNotification('DaCong', options)
  );
});

// 通知点击
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked');
  event.notification.close();

  if (event.action === 'view') {
    event.waitUntil(
      clients.openWindow(event.notification.data?.url || '/web')
    );
  }
});

// 辅助函数：同步收藏（后台运行）
async function syncFavorites() {
  // 实际实现需要与 IndexedDB 配合
  console.log('[SW] Syncing favorites...');
}

// 定期同步（如果支持）
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'content-sync') {
    event.waitUntil(syncContent());
  }
});

async function syncContent() {
  console.log('[SW] Periodic content sync...');
}