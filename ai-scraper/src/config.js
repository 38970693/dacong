/**
 * AI Model Leaderboard Scraper - Configuration
 */

export const config = {
  // Browser settings
  browser: {
    headless: true,
    timeout: 30000,
    executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-blink-features=AutomationControlled',
      '--disable-gpu'
    ]
  },

  // HTTP request settings
  request: {
    timeout: 30000,
    retries: 3,
    retryDelay: 1000,
    backoffMultiplier: 2,
    maxRetryDelay: 10000,
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  },

  // Proxy settings
  proxy: { host: '127.0.0.1', port: 7890, protocol: 'http' },

  // Output settings
  output: {
    dir: './data',
    format: 'json' // json, csv, markdown
  },

  // Logging
  logLevel: 'info',

  // Rate limiting
  rateLimit: {
    minDelay: 1000,
    maxDelay: 3000
  }
};

// Merge user config with defaults
export function createConfig(options = {}) {
  return deepMerge(config, options);
}

function deepMerge(target, source) {
  const result = { ...target };
  for (const key in source) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      result[key] = deepMerge(target[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }
  return result;
}