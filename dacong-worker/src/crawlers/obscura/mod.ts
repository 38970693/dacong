/**
 * Obscura 封装模块 - 提供浏览器级别的网页抓取能力
 *
 * 使用 Obscura (Rust 无头浏览器) 替代原生 fetch，
 * 支持 Stealth Mode 反检测和 JS 渲染
 */
import { exec } from 'child_process';
import { promisify } from 'util';
import { logger } from '../../logger';
import path from 'path';
import { fileURLToPath } from 'url';

// ES Module 中获取 __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const execAsync = promisify(exec);

/**
 * 获取 Obscura 工具的根目录
 * 优先使用环境变量，否则回退到相对路径
 */
function getObscuraToolsRoot(): string {
  // 环境变量优先
  if (process.env.OBSCURA_TOOLS_ROOT) {
    return process.env.OBSCURA_TOOLS_ROOT;
  }

  // 回退到 dacong-spider/tools/
  const projectRoot = path.resolve(__dirname, '../../../../');
  return path.join(projectRoot, 'dacong-spider', 'tools');
}

/**
 * 根据平台获取 Obscura 二进制路径
 */
function getObscuraPath(): { obscura: string; worker: string } {
  const toolsRoot = getObscuraToolsRoot();

  if (process.platform === 'win32') {
    return {
      obscura: path.join(toolsRoot, 'windows', 'obscura.exe'),
      worker: path.join(toolsRoot, 'windows', 'obscura-worker.exe'),
    };
  } else if (process.platform === 'darwin') {
    return {
      obscura: path.join(toolsRoot, 'mac', 'obscura'),
      worker: path.join(toolsRoot, 'mac', 'obscura-worker'),
    };
  } else {
    // Linux
    return {
      obscura: path.join(toolsRoot, 'linux', 'obscura'),
      worker: path.join(toolsRoot, 'linux', 'obscura-worker'),
    };
  }
}

// 缓存路径，避免每次调用
let cachedPaths: { obscura: string; worker: string } | null = null;

function getObscura(): { obscura: string; worker: string } {
  if (!cachedPaths) {
    cachedPaths = getObscuraPath();
    logger.info(`Obscura 路径: ${cachedPaths.obscura} (${process.platform})`);
  }
  return cachedPaths;
}

// 环境变量可以覆盖默认路径
const envPath = process.env.OBSCURA_PATH;
const OBSCURA_PATH = envPath || getObscura().obscura;

export interface FetchOptions {
  /** 等待条件: load, domcontentloaded, networkidle0 */
  waitUntil?: 'load' | 'domcontentloaded' | 'networkidle0';
  /** 超时时间 (秒) */
  timeout?: number;
  /** 等待 CSS 选择器出现 */
  selector?: string;
  /** 启用 stealth 模式 */
  stealth?: boolean;
  /** 输出格式: html, text, links */
  dump?: 'html' | 'text' | 'links';
  /** 静默模式 (不显示 banner) */
  quiet?: boolean;
  /** 自定义 User-Agent */
  userAgent?: string;
  /** 代理 URL */
  proxy?: string;
  /** 执行 JavaScript 并返回结果 (用于提取结构化数据) */
  eval?: string;
}

export interface FetchResult {
  content: string;
  url: string;
  title: string;
  success: boolean;
  error?: string;
}

/**
 * 使用 Obscura 获取页面内容
 */
export async function obscuraFetch(url: string, options: FetchOptions = {}): Promise<FetchResult> {
  const {
    waitUntil = 'load',
    timeout = 30,
    selector,
    stealth = true,
    dump = 'html',
    quiet = true,
    userAgent,
    proxy,
    eval: evalScript,
  } = options;

  // 构建命令
  let cmd = `"${OBSCURA_PATH}" fetch "${url}"`;

  // 添加参数
  cmd += ` --dump ${dump}`;
  cmd += ` --wait-until ${waitUntil}`;
  cmd += ` --timeout ${timeout}`;

  if (stealth) cmd += ' --stealth';
  if (quiet) cmd += ' --quiet';
  if (selector) cmd += ` --selector "${selector}"`;
  if (proxy) cmd += ` --proxy "${proxy}"`;
  if (userAgent) cmd += ` --user-agent "${userAgent}"`;
  if (evalScript) {
    // 将多行脚本转换为单行，并正确转义引号
    const singleLineScript = evalScript.replace(/\s+/g, ' ').replace(/"/g, '\\"');
    cmd += ` --eval "${singleLineScript}"`;
  }

  try {
    const { stdout } = await execAsync(cmd, {
      timeout: (timeout + 10) * 1000,
    });

    // 解析输出
    const output = stdout.trim();

    // 提取标题 (从 "Page loaded: ... - \"标题\"")
    const titleMatch = output.match(/Page loaded:.*?"([^"]+)"/);
    const title = titleMatch ? titleMatch[1] : '';

    // 提取内容 (在 "Page loaded" 之后的部分)
    const contentMatch = output.match(/Page loaded:[\s\S]+?\n(.*)/s);
    let content = contentMatch ? contentMatch[1].trim() : output;

    // 如果有 eval，返回原始内容（可能是 JSON）
    if (evalScript) {
      // 清理 ANSI 颜色代码
      content = content.replace(/\x1b\[[0-9;]*m/g, '').trim();
    }

    return {
      content,
      url,
      title,
      success: true,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`Obscura fetch 失败 [${url}]:`, message);

    return {
      content: '',
      url,
      title: '',
      success: false,
      error: message,
    };
  }
}

/**
 * 并行抓取多个 URL
 */
export async function obscuraScrape(
  urls: string[],
  options: {
    concurrency?: number;
    eval?: string;
    format?: 'json' | 'text';
    stealth?: boolean;
    timeout?: number;
  } = {}
): Promise<Array<FetchResult & { index: number }>> {
  const {
    concurrency = 10,
    stealth = true,
    timeout = 30,
    format = 'json',
  } = options;

  const args = ['scrape', ...urls];
  args.push('--concurrency', String(concurrency));
  args.push('--format', format);
  args.push('--timeout', String(timeout));
  args.push('--quiet');

  if (stealth) args.push('--stealth');

  try {
    const { stdout } = await execAsync(`${OBSCURA_PATH} ${args.join(' ')}`, {
      timeout: (timeout * urls.length / concurrency + 30) * 1000,
    });

    // 解析 JSON 输出
    const results = JSON.parse(stdout);

    return results.map((r: FetchResult, index: number) => ({
      ...r,
      index,
    }));
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error('Obscura scrape 失败:', message);

    return urls.map((url, index) => ({
      content: '',
      url,
      title: '',
      success: false,
      error: message,
      index,
    }));
  }
}

/**
 * 启动 CDP 服务器 (用于 Puppeteer/Playwright)
 */
export async function startCDPServer(port: number = 9222, stealth: boolean = true): Promise<string> {
  const args = ['serve', '--port', String(port), '--quiet'];
  if (stealth) args.push('--stealth');

  const child = exec(`${OBSCURA_PATH} ${args.join(' ')}`);

  // 等待服务器启动
  await new Promise(resolve => setTimeout(resolve, 2000));

  const wsEndpoint = `ws://127.0.0.1:${port}/devtools/browser`;

  logger.info(`CDP 服务器已启动: ${wsEndpoint}`);

  return wsEndpoint;
}

/**
 * 检查 Obscura 是否可用
 */
export async function checkObscura(): Promise<{ available: boolean; version?: string; error?: string }> {
  try {
    const { stdout } = await execAsync(`"${OBSCURA_PATH}" --help`);
    if (stdout.includes('Obscura')) {
      // 提取版本信息
      const versionMatch = stdout.match(/Obscura\s+v?([\d.]+)/i);
      return {
        available: true,
        version: versionMatch ? versionMatch[1] : 'unknown',
      };
    }
    return { available: false, error: 'Unknown binary' };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { available: false, error: message };
  }
}

/**
 * 初始化 Obscura - 在服务启动时调用
 */
export async function initObscura(): Promise<boolean> {
  const check = await checkObscura();
  if (check.available) {
    logger.info(`Obscura 已就绪 (v${check.version})`);
    return true;
  } else {
    logger.error(`Obscura 不可用: ${check.error}`);
    logger.error(`期望路径: ${OBSCURA_PATH}`);
    return false;
  }
}