# Prisma ORM 配置指南

## 1. 安装Prisma

```bash
# 在dacong-api目录
cd dacong-api
npm install -D prisma
npm install @prisma/client
```

## 2. 初始化Prisma

```bash
npx prisma init
```

这会创建：
- `prisma/schema.prisma` - 数据库Schema定义
- `.env` - 数据库连接配置

## 3. 配置数据库连接

### .env
```env
DATABASE_URL="postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"
```

## 4. 定义Schema（社交系统示例）

### prisma/schema.prisma
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// 评论表
model Comment {
  id            String   @id @default(uuid())
  contentId     String   @map("content_id")
  contentType   String   @map("content_type")
  userId        String   @map("user_id")
  parentId      String?  @map("parent_id")
  content       String
  likesCount    Int      @default(0) @map("likes_count")
  repliesCount  Int      @default(0) @map("replies_count")
  isDeleted     Boolean  @default(false) @map("is_deleted")
  createdAt     DateTime @default(now()) @map("created_at")
  updatedAt     DateTime @updatedAt @map("updated_at")

  // 关系
  parent        Comment?  @relation("CommentReplies", fields: [parentId], references: [id])
  replies       Comment[] @relation("CommentReplies")
  likes         CommentLike[]

  @@index([contentId, contentType])
  @@index([userId])
  @@index([parentId])
  @@map("comments")
}

// 评论点赞表
model CommentLike {
  id        String   @id @default(uuid())
  commentId String   @map("comment_id")
  userId    String   @map("user_id")
  createdAt DateTime @default(now()) @map("created_at")

  comment   Comment  @relation(fields: [commentId], references: [id], onDelete: Cascade)

  @@unique([commentId, userId])
  @@index([commentId])
  @@index([userId])
  @@map("comment_likes")
}

// 关注关系表
model Follow {
  id          String   @id @default(uuid())
  followerId  String   @map("follower_id")
  followingId String   @map("following_id")
  createdAt   DateTime @default(now()) @map("created_at")

  @@unique([followerId, followingId])
  @@index([followerId])
  @@index([followingId])
  @@map("follows")
}

// 收藏表
model Favorite {
  id          String   @id @default(uuid())
  userId      String   @map("user_id")
  contentId   String   @map("content_id")
  contentType String   @map("content_type")
  createdAt   DateTime @default(now()) @map("created_at")

  @@unique([userId, contentId, contentType])
  @@index([userId])
  @@index([contentId, contentType])
  @@map("favorites")
}

// 通知表
model Notification {
  id            String   @id @default(uuid())
  userId        String   @map("user_id")
  actorId       String?  @map("actor_id")
  type          String
  content       String?
  referenceId   String?  @map("reference_id")
  referenceType String?  @map("reference_type")
  isRead        Boolean  @default(false) @map("is_read")
  createdAt     DateTime @default(now()) @map("created_at")

  @@index([userId, isRead])
  @@index([createdAt])
  @@map("notifications")
}

// 用户活动表
model UserActivity {
  id           String   @id @default(uuid())
  userId       String   @map("user_id")
  activityType String   @map("activity_type")
  contentId    String   @map("content_id")
  contentType  String   @map("content_type")
  metadata     Json?
  createdAt    DateTime @default(now()) @map("created_at")

  @@index([userId, createdAt])
  @@index([contentId, contentType])
  @@index([activityType, createdAt])
  @@map("user_activities")
}

// 用户资料表
model UserProfile {
  userId          String   @id @map("user_id")
  username        String   @unique
  avatarUrl       String?  @map("avatar_url")
  bio             String?
  followersCount  Int      @default(0) @map("followers_count")
  followingCount  Int      @default(0) @map("following_count")
  createdAt       DateTime @default(now()) @map("created_at")
  updatedAt       DateTime @updatedAt @map("updated_at")

  @@index([username])
  @@map("user_profiles")
}
```

## 5. 生成迁移

```bash
# 创建迁移文件
npx prisma migrate dev --name init_social_system

# 这会：
# 1. 生成SQL迁移文件
# 2. 应用到数据库
# 3. 生成Prisma Client
```

## 6. 使用Prisma Client

### 创建评论
```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// 创建评论
const comment = await prisma.comment.create({
  data: {
    contentId: 'uuid',
    contentType: 'model',
    userId: 'uuid',
    content: '这个模型很不错！',
  },
});

// 获取评论列表（带分页）
const comments = await prisma.comment.findMany({
  where: {
    contentId: 'uuid',
    contentType: 'model',
    isDeleted: false,
  },
  include: {
    likes: true,
    replies: {
      take: 5,
    },
  },
  orderBy: {
    createdAt: 'desc',
  },
  take: 20,
  skip: 0,
});

// 点赞评论
const like = await prisma.commentLike.create({
  data: {
    commentId: 'uuid',
    userId: 'uuid',
  },
});

// 更新点赞数（使用事务）
await prisma.$transaction([
  prisma.commentLike.create({
    data: { commentId: 'uuid', userId: 'uuid' },
  }),
  prisma.comment.update({
    where: { id: 'uuid' },
    data: { likesCount: { increment: 1 } },
  }),
]);
```

## 7. 自动生成TypeScript类型

```bash
# 每次修改schema后运行
npx prisma generate
```

这会自动生成：
- 完整的TypeScript类型定义
- 类型安全的查询方法
- 自动补全支持

## 8. Prisma Studio（数据库GUI）

```bash
# 启动可视化数据库管理工具
npx prisma studio
```

访问 http://localhost:5555 查看和编辑数据

## 9. 与Supabase集成

### 从现有数据库生成Schema
```bash
# 如果已有Supabase数据库
npx prisma db pull

# 这会自动生成schema.prisma
```

### 同步到Supabase
```bash
# 推送schema到数据库
npx prisma db push
```

## 10. 最佳实践

### 使用中间件
```typescript
// 自动记录查询日志
prisma.$use(async (params, next) => {
  const before = Date.now();
  const result = await next(params);
  const after = Date.now();
  
  console.log(`Query ${params.model}.${params.action} took ${after - before}ms`);
  return result;
});
```

### 连接池管理
```typescript
// 单例模式
let prisma: PrismaClient;

if (process.env.NODE_ENV === 'production') {
  prisma = new PrismaClient();
} else {
  if (!global.prisma) {
    global.prisma = new PrismaClient();
  }
  prisma = global.prisma;
}

export default prisma;
```

## 11. 预期效果

- Schema定义时间：12h → 4h（节省8h）
- 迁移脚本编写：自动生成（节省4h）
- TypeScript类型：自动生成（节省2h）
- API代码：减少50%样板代码（节省12h）

**总节省：26小时**

## 12. 下一步

1. 安装Prisma
2. 定义Schema
3. 生成迁移
4. 集成到API代码
5. 配置CI/CD自动运行迁移
