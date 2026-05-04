'use client';

import { useEffect, useState } from 'react';
import { useAuthStore, useFavoritesStore, useLikesStore } from '@/stores';
import { LoginDialog } from './LoginDialog';

interface AuthProviderProps {
  children: React.ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [isLoginDialogOpen, setIsLoginDialogOpen] = useState(false);
  const { initialize, user, isInitialized } = useAuthStore();
  const { loadFavorites, clear: clearFavorites } = useFavoritesStore();
  const { loadLikes, clear: clearLikes } = useLikesStore();

  // 初始化认证状态
  useEffect(() => {
    initialize();
  }, [initialize]);

  // 当用户登录/登出时，加载/清空收藏和点赞数据
  useEffect(() => {
    if (user) {
      loadFavorites(user.id);
      loadLikes(user.id);
    } else if (isInitialized) {
      // 用户登出，清空数据
      clearFavorites();
      clearLikes();
    }
  }, [user, isInitialized, loadFavorites, loadLikes, clearFavorites, clearLikes]);

  // 打开登录对话框
  const openLoginDialog = () => setIsLoginDialogOpen(true);
  const closeLoginDialog = () => setIsLoginDialogOpen(false);

  return (
    <>
      {children}

      {/* 登录对话框 */}
      <LoginDialog isOpen={isLoginDialogOpen} onClose={closeLoginDialog} />

      {/* 导出到全局，方便其他组件调用 */}
      <script
        dangerouslySetInnerHTML={{
          __html: `
            window.openLoginDialog = ${openLoginDialog.toString().replace('setIsLoginDialogOpen', '(open) => setIsLoginDialogOpen(open)')};
          `
        }}
      />
    </>
  );
}

// 导出打开登录对话框的函数
export function openLoginDialog() {
  // @ts-ignore
  if (typeof window !== 'undefined' && window.openLoginDialog) {
    // @ts-ignore
    window.openLoginDialog(true);
  }
}