-- Migration: Create spider_logs table
-- Description: 爬虫运行日志

CREATE TABLE spider_logs (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 爬虫信息
  spider_name TEXT NOT NULL,
  source TEXT NOT NULL,

  -- 运行状态
  status TEXT NOT NULL CHECK (status IN ('running', 'success', 'failed', 'partial')),

  -- 统计数据
  items_scraped INT DEFAULT 0 CHECK (items_scraped >= 0),
  items_saved INT DEFAULT 0 CHECK (items_saved >= 0),
  items_failed INT DEFAULT 0 CHECK (items_failed >= 0),

  -- 错误信息
  error_message TEXT,
  error_trace TEXT,

  -- 时间戳
  started_at TIMESTAMPTZ DEFAULT NOW(),
  finished_at TIMESTAMPTZ,
  duration_seconds INT,

  -- 审计字段
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_spider_logs_status ON spider_logs(status, started_at DESC);
CREATE INDEX idx_spider_logs_spider ON spider_logs(spider_name, started_at DESC);
CREATE INDEX idx_spider_logs_source ON spider_logs(source, started_at DESC);

-- 注释
COMMENT ON TABLE spider_logs IS '爬虫运行日志';
COMMENT ON COLUMN spider_logs.status IS '运行状态：running/success/failed/partial';
