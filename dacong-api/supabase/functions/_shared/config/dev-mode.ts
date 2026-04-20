/**
 * 开发模式配置
 *
 * 用于在开发阶段快速切换各种验证开关
 * 生产环境会自动启用所有验证
 */

export interface DevModeConfig {
  /** 是否启用 CSRF 验证 */
  enableCsrf: boolean;
  /** 是否启用认证验证 */
  enableAuth: boolean;
  /** 是否启用输入验证 */
  enableInputValidation: boolean;
  /** 是否启用 SQL 注入防护 */
  enableSqlInjectionProtection: boolean;
  /** 是否启用 XSS 防护 */
  enableXssProtection: boolean;
  /** 是否启用速率限制 */
  enableRateLimit: boolean;
}

/**
 * 从环境变量读取开发模式配置
 */
function loadDevModeConfig(): DevModeConfig {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  const isProduction = env === 'production';

  // 生产环境强制启用所有验证
  if (isProduction) {
    return {
      enableCsrf: true,
      enableAuth: true,
      enableInputValidation: true,
      enableSqlInjectionProtection: true,
      enableXssProtection: true,
      enableRateLimit: true,
    };
  }

  // 开发环境从环境变量读取配置（默认全部禁用以便快速开发）
  return {
    enableCsrf: Deno.env.get('DEV_ENABLE_CSRF') === 'true',
    enableAuth: Deno.env.get('DEV_ENABLE_AUTH') === 'true',
    enableInputValidation: Deno.env.get('DEV_ENABLE_INPUT_VALIDATION') === 'true',
    enableSqlInjectionProtection: Deno.env.get('DEV_ENABLE_SQL_INJECTION_PROTECTION') === 'true',
    enableXssProtection: Deno.env.get('DEV_ENABLE_XSS_PROTECTION') === 'true',
    enableRateLimit: Deno.env.get('DEV_ENABLE_RATE_LIMIT') === 'true',
  };
}

// 导出单例配置
export const devMode = loadDevModeConfig();

/**
 * 检查是否为开发环境
 */
export function isDevelopment(): boolean {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  return env === 'development';
}

/**
 * 检查是否为生产环境
 */
export function isProduction(): boolean {
  const env = Deno.env.get('ENVIRONMENT') || 'development';
  return env === 'production';
}

/**
 * 打印当前开发模式配置（仅开发环境）
 */
export function printDevModeConfig(): void {
  if (!isDevelopment()) {
    return;
  }

  console.log('🔧 Development Mode Configuration:');
  console.log('  CSRF Protection:', devMode.enableCsrf ? '✅' : '❌');
  console.log('  Authentication:', devMode.enableAuth ? '✅' : '❌');
  console.log('  Input Validation:', devMode.enableInputValidation ? '✅' : '❌');
  console.log('  SQL Injection Protection:', devMode.enableSqlInjectionProtection ? '✅' : '❌');
  console.log('  XSS Protection:', devMode.enableXssProtection ? '✅' : '❌');
  console.log('  Rate Limiting:', devMode.enableRateLimit ? '✅' : '❌');
  console.log('');
}
