'use client';

/**
 * 通知组件 - 显示通知列表和未读数 (WCAG 2.1 AA 无障碍支持)
 */
import { useEffect, useRef, useState, useId } from 'react';
import { useNotificationStore, Notification } from '@/stores/notificationStore';
import { useAuthStore } from '@/stores/authStore';

// 通知类型映射
const TYPE_LABELS: Record<string, string> = {
  'system.announcement': '系统公告',
  'system.update': '系统更新',
  'system.maintenance': '系统维护',
  'content.reply': '回复通知',
  'content.mention': '提到你',
  'content.like': '点赞通知',
  'content.favorite': '收藏通知',
  'review.published': '评测发布',
  'review.commented': '评测评论',
  'review.liked': '评测点赞',
  'follow.new_follower': '新关注者'
};

const TYPE_ICONS: Record<string, string> = {
  'system.announcement': 'M11 5H6a2 2 0 00-2 2v12a2 2 0 002 2h12a2 2 0 002-2v-6M11 5H6v12h12V5M11 5v7',
  'system.update': 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15',
  'system.maintenance': 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z',
  'content.reply': 'M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6',
  'content.mention': 'M11.5 20H6a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v12a2 2 0 01-2 2',
  'content.like': 'M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z',
  'content.favorite': 'M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z',
  'review.published': 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z',
  'review.commented': 'M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z',
  'review.liked': 'M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z',
  'follow.new_follower': 'M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z'
};

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  const now = new Date();
  const diff = now.getTime() - date.getTime();
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);

  if (minutes < 1) return '刚刚';
  if (minutes < 60) return `${minutes}分钟前`;
  if (hours < 24) return `${hours}小时前`;
  if (days < 7) return `${days}天前`;
  return date.toLocaleDateString('zh-CN');
}

export function NotificationBell() {
  const { user } = useAuthStore();
  const { notifications, unreadCount, fetchNotifications, fetchUnreadCount, markAsRead, markAllAsRead } = useNotificationStore();
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const listboxId = useId();

  useEffect(() => {
    if (user?.id) {
      fetchNotifications(user.id);
      fetchUnreadCount(user.id);

      // 定时刷新未读数
      const interval = setInterval(() => {
        fetchUnreadCount(user.id);
      }, 60000); // 每分钟刷新

      return () => clearInterval(interval);
    }
  }, [user?.id, fetchNotifications, fetchUnreadCount]);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }

    // ESC 键关闭下拉菜单
    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape' && isOpen) {
        setIsOpen(false);
        buttonRef.current?.focus();
      }
    }

    document.addEventListener('mousedown', handleClickOutside);
    document.addEventListener('keydown', handleEscape);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handleEscape);
    };
  }, [isOpen]);

  async function handleMarkAsRead(notification: Notification) {
    if (!notification.is_read) {
      await markAsRead(notification.id);
    }
  }

  async function handleMarkAllRead() {
    if (user?.id) {
      await markAllAsRead(user.id);
    }
  }

  const notificationLabel = unreadCount > 0
    ? `通知，有 ${unreadCount} 条未读`
    : '通知，没有未读';

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        ref={buttonRef}
        onClick={() => setIsOpen(!isOpen)}
        className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-secondary)] hover:bg-[var(--primary-light)] hover:text-[var(--primary)] transition-all relative"
        aria-label={notificationLabel}
        aria-haspopup="listbox"
        aria-expanded={isOpen}
        aria-controls={isOpen ? listboxId : undefined}
      >
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
          <path strokeLinecap="round" strokeLinejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        </svg>

        {unreadCount > 0 && (
          <span
            className="absolute -top-1 -right-1 min-w-[18px] h-[18px] flex items-center justify-center text-xs font-bold bg-red-500 text-white rounded-full px-1"
            aria-label={`${unreadCount} 条未读通知`}
          >
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div
          id={listboxId}
          role="listbox"
          aria-label="通知列表"
          className="absolute right-0 mt-2 w-96 max-h-[500px] bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-[var(--border)] overflow-hidden z-50"
        >
          {/* 标题栏 */}
          <div className="px-4 py-3 border-b border-[var(--border)] flex items-center justify-between bg-[var(--background)]">
            <span id="notification-heading" className="text-sm font-medium text-[var(--foreground)]">通知</span>
            {unreadCount > 0 && (
              <button
                onClick={handleMarkAllRead}
                className="text-xs text-[var(--primary)] hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] rounded px-2 py-1"
                aria-describedby="notification-heading"
              >
                全部已读
              </button>
            )}
          </div>

          {/* 通知列表 */}
          <div
            className="max-h-[400px] overflow-y-auto"
            role="presentation"
          >
            {notifications.length === 0 ? (
              <div className="px-4 py-8 text-center text-[var(--text-muted)]" role="option" aria-selected="false">
                <svg className="w-12 h-12 mx-auto mb-2 opacity-50" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
                <p className="text-sm">暂无通知</p>
              </div>
            ) : (
              notifications.map((notification) => (
                <div
                  key={notification.id}
                  role="option"
                  aria-selected={!notification.is_read}
                  onClick={() => handleMarkAsRead(notification)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                      handleMarkAsRead(notification);
                    }
                  }}
                  tabIndex={0}
                  className={`px-4 py-3 border-b border-[var(--border)]/50 hover:bg-[var(--background)]/50 cursor-pointer focus:outline-none focus:ring-2 focus:ring-[var(--primary)] ${
                    !notification.is_read ? 'bg-[var(--primary-light)]/10' : ''
                  }`}
                >
                  <div className="flex gap-3">
                    {/* 图标 */}
                    <div
                      className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${
                        !notification.is_read ? 'bg-[var(--primary)] text-white' : 'bg-[var(--background)] text-[var(--text-muted)]'
                      }`}
                      aria-hidden="true"
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d={TYPE_ICONS[notification.type] || TYPE_ICONS['system.announcement']} />
                      </svg>
                    </div>

                    {/* 内容 */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-2">
                        <div className="text-sm font-medium text-[var(--foreground)] line-clamp-1">
                          {notification.title}
                        </div>
                        <span className="flex-shrink-0 text-xs text-[var(--text-muted)]" aria-label={`发送时间：${formatDate(notification.created_at)}`}>
                          {formatDate(notification.created_at)}
                        </span>
                      </div>
                      <p className="text-sm text-[var(--text-secondary)] mt-0.5 line-clamp-2">
                        {notification.content}
                      </p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-xs px-2 py-0.5 rounded bg-[var(--background)] text-[var(--text-muted)]">
                          {TYPE_LABELS[notification.type] || notification.type}
                        </span>
                        {notification.source_user_name && (
                          <span className="text-xs text-[var(--text-muted)]">
                            来自 {notification.source_user_name}
                          </span>
                        )}
                      </div>
                    </div>

                    {/* 未读标记 */}
                    {!notification.is_read && (
                      <div className="flex-shrink-0 w-2 h-2 rounded-full bg-[var(--primary)] mt-2" aria-label="未读"></div>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>

          {/* 底部 */}
          <div className="px-4 py-2 border-t border-[var(--border)] bg-[var(--background)] text-center">
            <a
              href="/notifications"
              className="text-sm text-[var(--primary)] hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] rounded px-2 py-1 inline-block"
            >
              查看全部通知
            </a>
          </div>
        </div>
      )}
    </div>
  );
}