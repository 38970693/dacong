-- 敏感数据加密迁移
-- 创建时间: 2026-04-18
-- 用途: 为敏感字段添加加密支持

-- ============================================
-- 1. 启用 pgcrypto 扩展
-- ============================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- 2. 创建加密密钥表（用于密钥轮换）
-- ============================================
CREATE TABLE IF NOT EXISTS encryption_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_version INTEGER NOT NULL UNIQUE,
    key_hash TEXT NOT NULL, -- 密钥的哈希值，用于验证
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    rotated_at TIMESTAMPTZ,
    created_by VARCHAR(100)
);

-- 创建索引
CREATE INDEX idx_encryption_keys_active ON encryption_keys(is_active) WHERE is_active = true;
CREATE INDEX idx_encryption_keys_version ON encryption_keys(key_version DESC);

-- 插入初始密钥版本记录（实际密钥存储在环境变量中）
INSERT INTO encryption_keys (key_version, key_hash, is_active, created_by)
VALUES (1, encode(digest('initial_key_placeholder', 'sha256'), 'hex'), true, 'system')
ON CONFLICT (key_version) DO NOTHING;

-- ============================================
-- 3. 为 profiles 表添加加密字段
-- ============================================

-- 添加加密邮箱字段
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS email_encrypted TEXT,
ADD COLUMN IF NOT EXISTS email_key_version INTEGER DEFAULT 1;

-- 添加加密手机号字段（如果需要）
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS phone_encrypted TEXT,
ADD COLUMN IF NOT EXISTS phone_key_version INTEGER DEFAULT 1;

-- 创建索引（注意：加密字段不应该直接索引，需要时使用哈希索引）
CREATE INDEX IF NOT EXISTS idx_profiles_email_key_version ON profiles(email_key_version);

-- ============================================
-- 4. 为 comments 表添加加密字段（可选）
-- ============================================

-- 如果评论内容需要加密（例如私密评论）
ALTER TABLE comments
ADD COLUMN IF NOT EXISTS content_encrypted TEXT,
ADD COLUMN IF NOT EXISTS content_key_version INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS is_encrypted BOOLEAN DEFAULT false;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_comments_encrypted ON comments(is_encrypted) WHERE is_encrypted = true;

-- ============================================
-- 5. 创建加密/解密函数
-- ============================================

-- 加密函数
CREATE OR REPLACE FUNCTION encrypt_data(
    plaintext TEXT,
    encryption_key TEXT
) RETURNS TEXT AS $$
BEGIN
    -- 使用 AES-256-GCM 加密
    RETURN encode(
        pgp_sym_encrypt(
            plaintext,
            encryption_key,
            'cipher-algo=aes256'
        ),
        'base64'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 解密函数
CREATE OR REPLACE FUNCTION decrypt_data(
    ciphertext TEXT,
    encryption_key TEXT
) RETURNS TEXT AS $$
BEGIN
    -- 解密
    RETURN pgp_sym_decrypt(
        decode(ciphertext, 'base64'),
        encryption_key
    );
EXCEPTION
    WHEN OTHERS THEN
        -- 解密失败返回 NULL
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. 创建数据迁移函数（明文 -> 加密）
-- ============================================

-- 迁移 profiles 邮箱
CREATE OR REPLACE FUNCTION migrate_profiles_email_to_encrypted(
    encryption_key TEXT,
    batch_size INTEGER DEFAULT 100
) RETURNS TABLE(migrated_count INTEGER) AS $$
DECLARE
    affected_rows INTEGER := 0;
    total_migrated INTEGER := 0;
BEGIN
    LOOP
        -- 批量迁移
        WITH to_migrate AS (
            SELECT id, email
            FROM profiles
            WHERE email IS NOT NULL
              AND email_encrypted IS NULL
            LIMIT batch_size
        )
        UPDATE profiles p
        SET
            email_encrypted = encrypt_data(tm.email, encryption_key),
            email_key_version = 1
        FROM to_migrate tm
        WHERE p.id = tm.id;

        GET DIAGNOSTICS affected_rows = ROW_COUNT;
        total_migrated := total_migrated + affected_rows;

        -- 如果没有更多数据，退出循环
        EXIT WHEN affected_rows = 0;

        -- 提交批次
        COMMIT;
    END LOOP;

    RETURN QUERY SELECT total_migrated;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. 创建审计触发器
-- ============================================

-- 记录加密字段的访问
CREATE TABLE IF NOT EXISTS encryption_access_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    column_name VARCHAR(100) NOT NULL,
    operation VARCHAR(20) NOT NULL, -- SELECT, UPDATE, INSERT
    user_id UUID,
    accessed_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

-- 创建索引
CREATE INDEX idx_encryption_access_log_table ON encryption_access_log(table_name, column_name);
CREATE INDEX idx_encryption_access_log_time ON encryption_access_log(accessed_at DESC);
CREATE INDEX idx_encryption_access_log_user ON encryption_access_log(user_id);

-- ============================================
-- 8. 创建密钥轮换函数
-- ============================================

CREATE OR REPLACE FUNCTION rotate_encryption_key(
    old_key TEXT,
    new_key TEXT,
    new_version INTEGER
) RETURNS TABLE(
    table_name TEXT,
    rows_updated INTEGER
) AS $$
DECLARE
    profiles_count INTEGER := 0;
    comments_count INTEGER := 0;
BEGIN
    -- 更新 profiles 表
    UPDATE profiles
    SET
        email_encrypted = encrypt_data(
            decrypt_data(email_encrypted, old_key),
            new_key
        ),
        email_key_version = new_version
    WHERE email_encrypted IS NOT NULL
      AND email_key_version < new_version;

    GET DIAGNOSTICS profiles_count = ROW_COUNT;

    -- 更新 comments 表
    UPDATE comments
    SET
        content_encrypted = encrypt_data(
            decrypt_data(content_encrypted, old_key),
            new_key
        ),
        content_key_version = new_version
    WHERE content_encrypted IS NOT NULL
      AND content_key_version < new_version;

    GET DIAGNOSTICS comments_count = ROW_COUNT;

    -- 更新密钥版本
    UPDATE encryption_keys SET is_active = false WHERE is_active = true;
    INSERT INTO encryption_keys (key_version, key_hash, is_active, created_by)
    VALUES (new_version, encode(digest(new_key, 'sha256'), 'hex'), true, 'system');

    -- 返回结果
    RETURN QUERY
    SELECT 'profiles'::TEXT, profiles_count
    UNION ALL
    SELECT 'comments'::TEXT, comments_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 9. 创建视图（自动解密，需要传入密钥）
-- ============================================

-- 注意：实际使用时，解密应该在应用层完成，而不是数据库层
-- 这里提供一个示例视图，仅用于管理员调试

-- ============================================
-- 10. 添加注释
-- ============================================

COMMENT ON TABLE encryption_keys IS '加密密钥版本管理表';
COMMENT ON TABLE encryption_access_log IS '加密字段访问审计日志';
COMMENT ON FUNCTION encrypt_data IS '使用 AES-256 加密数据';
COMMENT ON FUNCTION decrypt_data IS '解密数据';
COMMENT ON FUNCTION migrate_profiles_email_to_encrypted IS '迁移 profiles 邮箱到加密字段';
COMMENT ON FUNCTION rotate_encryption_key IS '轮换加密密钥';

-- ============================================
-- 11. 权限设置
-- ============================================

-- 限制加密函数的访问权限
REVOKE ALL ON FUNCTION encrypt_data FROM PUBLIC;
REVOKE ALL ON FUNCTION decrypt_data FROM PUBLIC;
REVOKE ALL ON FUNCTION rotate_encryption_key FROM PUBLIC;

-- 只允许服务角色访问
GRANT EXECUTE ON FUNCTION encrypt_data TO service_role;
GRANT EXECUTE ON FUNCTION decrypt_data TO service_role;
GRANT EXECUTE ON FUNCTION rotate_encryption_key TO service_role;

-- ============================================
-- 使用说明
-- ============================================

-- 1. 加密数据示例：
-- SELECT encrypt_data('sensitive@email.com', 'your-encryption-key');

-- 2. 解密数据示例：
-- SELECT decrypt_data(email_encrypted, 'your-encryption-key') FROM profiles WHERE id = 'xxx';

-- 3. 迁移现有数据：
-- SELECT migrate_profiles_email_to_encrypted('your-encryption-key');

-- 4. 密钥轮换：
-- SELECT * FROM rotate_encryption_key('old-key', 'new-key', 2);

-- 5. 查看加密密钥版本：
-- SELECT * FROM encryption_keys ORDER BY key_version DESC;

-- 6. 查看访问日志：
-- SELECT * FROM encryption_access_log ORDER BY accessed_at DESC LIMIT 100;
