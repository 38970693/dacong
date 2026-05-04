// Re-export all stores

// Posts Store (posts, trending)
export { usePostsStore, useTrendingStore, useUserStore } from './postsStore';

// Auth Store (Supabase authentication)
export { useAuthStore } from './authStore';

// Favorites Store
export { useFavoritesStore } from './favoritesStore';

// Likes Store
export { useLikesStore } from './likesStore';
