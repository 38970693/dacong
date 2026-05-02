import { z } from 'zod';

// 环境变量验证
export const envSchema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string(),
  ALIYUN_ACCESS_KEY: z.string().optional(),
  ALIYUN_ACCESS_SECRET: z.string().optional(),
  ALIYUN_REGION: z.string().default('cn-shanghai'),
  CRAWL_INTERVAL_MINUTES: z.coerce.number().default(5),
  MAX_POSTS_PER_CRAWL: z.coerce.number().default(50),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
});

export type Env = z.infer<typeof envSchema>;

// 验证环境变量
export function validateEnv(): Env {
  const result = envSchema.safeParse(process.env);
  if (!result.success) {
    throw new Error(`环境变量验证失败: ${result.error.message}`);
  }
  return result.data;
}

// 运行时获取环境变量
export const env = validateEnv();