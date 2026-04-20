-- CSRF Tokens Table
-- 用于存储和验证 CSRF Token

CREATE TABLE IF NOT EXISTS csrf_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,
  ip_address TEXT,
  user_agent TEXT
);

-- 索引优化
CREATE INDEX idx_csrf_tokens_user_id ON csrf_tokens(user_id);
CREATE INDEX idx_csrf_tokens_token ON csrf_tokens(token);
CREATE INDEX idx_csrf_tokens_expires_at ON csrf_tokens(expires_at);

-- 自动清理过期 Token 的函数
CREATE OR REPLACE FUNCTION cleanup_expired_csrf_tokens()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM csrf_tokens
  WHERE expires_at < NOW();
END;
$$;

-- 创建定时任务清理过期 Token（每小时执行一次）
-- 注意：需要 pg_cron 扩展支持
-- SELECT cron.schedule('cleanup-csrf-tokens', '0 * * * *', 'SELECT cleanup_expired_csrf_tokens()');

-- 或者使用触发器在插入新 Token 时清理过期的
CREATE OR REPLACE FUNCTION trigger_cleanup_expired_csrf_tokens()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- 10% 概率清理过期 Token，避免每次插入都清理
  IF random() < 0.1 THEN
    DELETE FROM csrf_tokens
    WHERE expires_at < NOW();
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER cleanup_csrf_tokens_on_insert
AFTER INSERT ON csrf_tokens
FOR EACH STATEMENT
EXECUTE FUNCTION trigger_cleanup_expired_csrf_tokens();

-- RLS 策略（确保用户只能访问自己的 Token）
ALTER TABLE csrf_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own CSRF tokens"
ON csrf_tokens
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own CSRF tokens"
ON csrf_tokens
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own CSRF tokens"
ON csrf_tokens
FOR DELETE
USING (auth.uid() = user_id);

-- 注释
COMMENT ON TABLE csrf_tokens IS 'CSRF Token 存储表，用于防止跨站请求伪造攻击';
COMMENT ON COLUMN csrf_tokens.token IS 'CSRF Token 值（加密安全的随机字符串）';
COMMENT ON COLUMN csrf_tokens.expires_at IS 'Token 过期时间（默认 1 小时）';
COMMENT ON COLUMN csrf_tokens.last_used_at IS '最后使用时间（用于审计）';
