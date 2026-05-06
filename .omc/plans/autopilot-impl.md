# DaCong 新闻聚合平台 - 功能开发计划

## 实现顺序

1. 基础设施 (P0) - 统一客户端、类型定义
2. 标签系统 (P1) - 依赖 Phase 1
3. 搜索功能 (P1) - 依赖 Phase 1
4. 评测 CRUD (P1) - 依赖 Phase 1, 2
5. 收藏/点赞 (P1) - 依赖 Phase 1

## 文件清单

### 新建 (P1)
- src/lib/supabase.ts
- src/stores/tagsStore.ts
- src/stores/reviewsStore.ts
- src/app/api/tags/[id]/route.ts
- src/app/api/reviews/[id]/route.ts
- src/app/api/favorites/route.ts
- src/app/api/favorites/[id]/route.ts
- src/app/web/review/create/page.tsx
- src/app/web/review/[id]/page.tsx
- src/app/web/review/edit/[id]/page.tsx
- src/components/TagSelector.tsx
- src/components/StarRating.tsx

### 修改
- src/types/database.ts (P0)
- src/app/web/review/page.tsx (P1)
- src/app/web/saved/page.tsx (P1)
- src/stores/favoritesStore.ts (P1)
- src/stores/likesStore.ts (P2)

## 技术方案

### 搜索
- posts: textSearch (全文)
- reviews: textSearch + ilike
- models: ilike

### 标签关联
- review_tags 表 (review_id, tag_id)

### 收藏/点赞
- target_type 字段支持 post/review/model

## 测试策略

- 单元测试: Vitest + testing-library
- 覆盖率目标: 80%+
