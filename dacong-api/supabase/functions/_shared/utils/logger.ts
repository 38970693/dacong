/**
 * 结构化日志工具
 * 统一的日志格式，便于 Loki 聚合和查询
 */

export enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
}

interface LogContext {
  [key: string]: any;
}

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  service: string;
  function: string;
  message: string;
  context?: LogContext;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}

class Logger {
  private service: string;
  private functionName: string;

  constructor(service: string = 'dacong-api', functionName: string = 'unknown') {
    this.service = service;
    this.functionName = functionName;
  }

  private formatLog(level: LogLevel, message: string, context?: LogContext, error?: Error): string {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      service: this.service,
      function: this.functionName,
      message,
    };

    if (context && Object.keys(context).length > 0) {
      entry.context = context;
    }

    if (error) {
      entry.error = {
        name: error.name,
        message: error.message,
        stack: error.stack,
      };
    }

    return JSON.stringify(entry);
  }

  debug(message: string, context?: LogContext): void {
    console.log(this.formatLog(LogLevel.DEBUG, message, context));
  }

  info(message: string, context?: LogContext): void {
    console.log(this.formatLog(LogLevel.INFO, message, context));
  }

  warn(message: string, context?: LogContext): void {
    console.warn(this.formatLog(LogLevel.WARN, message, context));
  }

  error(message: string, error?: Error, context?: LogContext): void {
    console.error(this.formatLog(LogLevel.ERROR, message, context, error));
  }

  // 性能日志
  logPerformance(operation: string, durationMs: number, context?: LogContext): void {
    this.info(`Performance: ${operation}`, {
      ...context,
      duration_ms: durationMs,
      operation,
    });
  }

  // 请求日志
  logRequest(method: string, path: string, context?: LogContext): void {
    this.info(`Request: ${method} ${path}`, {
      ...context,
      method,
      path,
    });
  }

  // 响应日志
  logResponse(method: string, path: string, statusCode: number, durationMs: number, context?: LogContext): void {
    const level = statusCode >= 500 ? LogLevel.ERROR : statusCode >= 400 ? LogLevel.WARN : LogLevel.INFO;
    const logMethod = level === LogLevel.ERROR ? this.error.bind(this) :
                      level === LogLevel.WARN ? this.warn.bind(this) :
                      this.info.bind(this);

    logMethod(`Response: ${method} ${path} ${statusCode}`, {
      ...context,
      method,
      path,
      status_code: statusCode,
      duration_ms: durationMs,
    });
  }
}

// 创建日志实例的工厂函数
export function createLogger(functionName: string): Logger {
  return new Logger('dacong-api', functionName);
}

// 默认导出
export default Logger;
