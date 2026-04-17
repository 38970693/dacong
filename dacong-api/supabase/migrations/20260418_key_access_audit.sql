-- 密钥访问审计系统
-- 创建时间: 2026-04-18
-- 用途: 记录和审计密钥访问行为

-- ============================================
-- 1. 密钥访问日志表
-- ============================================
CREATE TABLE IF NOT EXISTS key_access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_name VARCHAR(100) NOT NULL,
    accessed_by VARCHAR(100) NOT NULL,
    access_type VARCHAR(50) NOT NULL, -- READ, WRITE, ROTATE, DELETE
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(100),
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_key_access_logs_key_name ON key_access_logs(key_name);
CREATE INDEX idx_key_access_logs_created_at ON key_access_logs(created_at DESC);
CREATE INDEX idx_key_access_logs_accessed_by ON key_access_logs(accessed_by);
CREATE INDEX idx_key_access_logs_success ON key_access_logs(success) WHERE success = false;

-- ============================================
-- 2. 密钥使用统计表
-- ============================================
CREATE TABLE IF NOT EXISTS key_usage_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_name VARCHAR(100) NOT NULL UNIQUE,
    total_accesses BIGINT DEFAULT 0,
    successful_accesses BIGINT DEFAULT 0,
    failed_accesses BIGINT DEFAULT 0,
    last_accessed_at TIMESTAMPTZ,
    last_accessed_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_key_usage_stats_key_name ON key_usage_stats(key_name);
CREATE INDEX idx_key_usage_stats_last_accessed ON key_usage_stats(last_accessed_at DESC);

-- ============================================
-- 3. 异常访问告警表
-- ============================================
CREATE TABLE IF NOT EXISTS key_access_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type VARCHAR(50) NOT NULL, -- RATE_LIMIT, UNAUTHORIZED, SUSPICIOUS_IP, FAILED_ATTEMPTS
    key_name VARCHAR(100) NOT NULL,
    accessed_by VARCHAR(100),
    ip_address INET,
    description TEXT,
    severity VARCHAR(20) DEFAULT 'MEDIUM', -- LOW, MEDIUM, HIGH, CRITICAL
    is_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMPTZ,
    resolved_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_key_access_alerts_type ON key_access_alerts(alert_type);
CREATE INDEX idx_key_access_alerts_severity ON key_access_alerts(severity);
CREATE INDEX idx_key_access_alerts_resolved ON key_access_alerts(is_resolved) WHERE is_resolved = false;
CREATE INDEX idx_key_access_alerts_created_at ON key_access_alerts(created_at DESC);

-- ============================================
-- 4. 记录密钥访问的函数
-- ============================================
CREATE OR REPLACE FUNCTION log_key_access(
    p_key_name VARCHAR(100),
    p_accessed_by VARCHAR(100),
    p_access_type VARCHAR(50),
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_request_id VARCHAR(100) DEFAULT NULL,
    p_success BOOLEAN DEFAULT true,
    p_error_message TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    -- 插入访问日志
    INSERT INTO key_access_logs (
        key_name,
        accessed_by,
        access_type,
        ip_address,
        user_agent,
        request_id,
        success,
        error_message
    ) VALUES (
        p_key_name,
        p_accessed_by,
        p_access_type,
        p_ip_address,
        p_user_agent,
        p_request_id,
        p_success,
        p_error_message
    ) RETURNING id INTO v_log_id;

    -- 更新使用统计
    INSERT INTO key_usage_stats (
        key_name,
        total_accesses,
        successful_accesses,
        failed_accesses,
        last_accessed_at,
        last_accessed_by
    ) VALUES (
        p_key_name,
        1,
        CASE WHEN p_success THEN 1 ELSE 0 END,
        CASE WHEN p_success THEN 0 ELSE 1 END,
        NOW(),
        p_accessed_by
    )
    ON CONFLICT (key_name) DO UPDATE SET
        total_accesses = key_usage_stats.total_accesses + 1,
        successful_accesses = key_usage_stats.successful_accesses + CASE WHEN p_success THEN 1 ELSE 0 END,
        failed_accesses = key_usage_stats.failed_accesses + CASE WHEN p_success THEN 0 ELSE 1 END,
        last_accessed_at = NOW(),
        last_accessed_by = p_accessed_by,
        updated_at = NOW();

    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. 检测异常访问的函数
-- ============================================
CREATE OR REPLACE FUNCTION detect_suspicious_key_access()
RETURNS TABLE(
    alert_type VARCHAR(50),
    key_name VARCHAR(100),
    description TEXT,
    severity VARCHAR(20)
) AS $$
BEGIN
    -- 检测频繁失败的访问（5 分钟内超过 10 次）
    RETURN QUERY
    SELECT
        'FAILED_ATTEMPTS'::VARCHAR(50),
        kal.key_name,
        format('密钥 %s 在 5 分钟内失败访问 %s 次', kal.key_name, COUNT(*))::TEXT,
        'HIGH'::VARCHAR(20)
    FROM key_access_logs kal
    WHERE kal.success = false
      AND kal.created_at > NOW() - INTERVAL '5 minutes'
    GROUP BY kal.key_name
    HAVING COUNT(*) > 10;

    -- 检测来自可疑 IP 的访问（短时间内多个不同密钥）
    RETURN QUERY
    SELECT
        'SUSPICIOUS_IP'::VARCHAR(50),
        'multiple_keys'::VARCHAR(100),
        format('IP %s 在 10 分钟内访问了 %s 个不同密钥', kal.ip_address, COUNT(DISTINCT kal.key_name))::TEXT,
        'MEDIUM'::VARCHAR(20)
    FROM key_access_logs kal
    WHERE kal.created_at > NOW() - INTERVAL '10 minutes'
      AND kal.ip_address IS NOT NULL
    GROUP BY kal.ip_address
    HAVING COUNT(DISTINCT kal.key_name) > 5;

    -- 检测高频访问（1 分钟内超过 100 次）
    RETURN QUERY
    SELECT
        'RATE_LIMIT'::VARCHAR(50),
        kal.key_name,
        format('密钥 %s 在 1 分钟内被访问 %s 次', kal.key_name, COUNT(*))::TEXT,
        'MEDIUM'::VARCHAR(20)
    FROM key_access_logs kal
    WHERE kal.created_at > NOW() - INTERVAL '1 minute'
    GROUP BY kal.key_name
    HAVING COUNT(*) > 100;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. 创建告警的函数
-- ============================================
CREATE OR REPLACE FUNCTION create_key_access_alert(
    p_alert_type VARCHAR(50),
    p_key_name VARCHAR(100),
    p_accessed_by VARCHAR(100) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_severity VARCHAR(20) DEFAULT 'MEDIUM'
) RETURNS UUID AS $$
DECLARE
    v_alert_id UUID;
BEGIN
    INSERT INTO key_access_alerts (
        alert_type,
        key_name,
        accessed_by,
        ip_address,
        description,
        severity
    ) VALUES (
        p_alert_type,
        p_key_name,
        p_accessed_by,
        p_ip_address,
        p_description,
        p_severity
    ) RETURNING id INTO v_alert_id;

    RETURN v_alert_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. 自动检测异常并创建告警的函数
-- ============================================
CREATE OR REPLACE FUNCTION auto_detect_and_alert()
RETURNS INTEGER AS $$
DECLARE
    v_alert RECORD;
    v_alert_count INTEGER := 0;
BEGIN
    FOR v_alert IN SELECT * FROM detect_suspicious_key_access()
    LOOP
        -- 检查是否已存在相同的未解决告警（避免重复）
        IF NOT EXISTS (
            SELECT 1 FROM key_access_alerts
            WHERE alert_type = v_alert.alert_type
              AND key_name = v_alert.key_name
              AND is_resolved = false
              AND created_at > NOW() - INTERVAL '1 hour'
        ) THEN
            PERFORM create_key_access_alert(
                v_alert.alert_type,
                v_alert.key_name,
                NULL,
                NULL,
                v_alert.description,
                v_alert.severity
            );
            v_alert_count := v_alert_count + 1;
        END IF;
    END LOOP;

    RETURN v_alert_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. 创建定时任务（每 5 分钟检测一次）
-- ============================================
-- 注意：需要 pg_cron 扩展
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- SELECT cron.schedule(
--     'detect-key-access-anomalies',
--     '*/5 * * * *',
--     'SELECT auto_detect_and_alert();'
-- );

-- ============================================
-- 9. 查询视图
-- ============================================

-- 最近的密钥访问
CREATE OR REPLACE VIEW recent_key_accesses AS
SELECT
    kal.id,
    kal.key_name,
    kal.accessed_by,
    kal.access_type,
    kal.ip_address,
    kal.success,
    kal.created_at
FROM key_access_logs kal
ORDER BY kal.created_at DESC
LIMIT 1000;

-- 密钥使用概览
CREATE OR REPLACE VIEW key_usage_overview AS
SELECT
    kus.key_name,
    kus.total_accesses,
    kus.successful_accesses,
    kus.failed_accesses,
    ROUND(kus.successful_accesses::NUMERIC / NULLIF(kus.total_accesses, 0) * 100, 2) AS success_rate,
    kus.last_accessed_at,
    kus.last_accessed_by
FROM key_usage_stats kus
ORDER BY kus.total_accesses DESC;

-- 未解决的告警
CREATE OR REPLACE VIEW unresolved_alerts AS
SELECT
    kaa.id,
    kaa.alert_type,
    kaa.key_name,
    kaa.description,
    kaa.severity,
    kaa.created_at,
    EXTRACT(EPOCH FROM (NOW() - kaa.created_at)) / 3600 AS hours_since_created
FROM key_access_alerts kaa
WHERE kaa.is_resolved = false
ORDER BY
    CASE kaa.severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
    END,
    kaa.created_at DESC;

-- ============================================
-- 10. 数据清理函数（删除旧日志）
-- ============================================
CREATE OR REPLACE FUNCTION cleanup_old_key_logs(
    retention_days INTEGER DEFAULT 90
) RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM key_access_logs
    WHERE created_at < NOW() - (retention_days || ' days')::INTERVAL;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 11. 添加注释
-- ============================================
COMMENT ON TABLE key_access_logs IS '密钥访问日志表';
COMMENT ON TABLE key_usage_stats IS '密钥使用统计表';
COMMENT ON TABLE key_access_alerts IS '密钥访问异常告警表';
COMMENT ON FUNCTION log_key_access IS '记录密钥访问';
COMMENT ON FUNCTION detect_suspicious_key_access IS '检测可疑的密钥访问';
COMMENT ON FUNCTION create_key_access_alert IS '创建密钥访问告警';
COMMENT ON FUNCTION auto_detect_and_alert IS '自动检测异常并创建告警';
COMMENT ON FUNCTION cleanup_old_key_logs IS '清理旧的密钥访问日志';

-- ============================================
-- 使用示例
-- ============================================

-- 1. 记录密钥访问
-- SELECT log_key_access(
--     'SUPABASE_SERVICE_ROLE_KEY',
--     'api-server',
--     'READ',
--     '192.168.1.100'::INET,
--     'Mozilla/5.0...',
--     'req-123',
--     true,
--     NULL
-- );

-- 2. 查看最近的访问
-- SELECT * FROM recent_key_accesses;

-- 3. 查看密钥使用统计
-- SELECT * FROM key_usage_overview;

-- 4. 检测异常访问
-- SELECT * FROM detect_suspicious_key_access();

-- 5. 手动触发异常检测
-- SELECT auto_detect_and_alert();

-- 6. 查看未解决的告警
-- SELECT * FROM unresolved_alerts;

-- 7. 解决告警
-- UPDATE key_access_alerts
-- SET is_resolved = true, resolved_at = NOW(), resolved_by = 'admin'
-- WHERE id = 'xxx';

-- 8. 清理 90 天前的日志
-- SELECT cleanup_old_key_logs(90);
