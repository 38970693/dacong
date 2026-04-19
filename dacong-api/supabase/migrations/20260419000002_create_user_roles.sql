-- Migration: Create user_roles table
-- Description: 用户角色和权限系统

-- ============================================
-- user_roles 表 - 用户角色
-- ============================================
CREATE TABLE IF NOT EXISTS user_roles (
  -- 主键
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 用户关联
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 角色信息
  role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'moderator', 'user', 'banned')),

  -- 权限配置（JSON格式，用于细粒度权限控制）
  permissions JSONB DEFAULT '{}',

  -- 状态
  is_active BOOLEAN DEFAULT true,

  -- 封禁信息
  banned_until TIMESTAMPTZ,
  ban_reason TEXT,

  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- 唯一约束：每个用户只能有一个角色记录
  CONSTRAINT unique_user_role UNIQUE(user_id)
);

-- 索引
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role) WHERE is_active = true;
CREATE INDEX idx_user_roles_banned ON user_roles(banned_until) WHERE banned_until IS NOT NULL;

-- 注释
COMMENT ON TABLE user_roles IS '用户角色和权限表';
COMMENT ON COLUMN user_roles.user_id IS '用户ID';
COMMENT ON COLUMN user_roles.role IS '角色：admin/moderator/user/banned';
COMMENT ON COLUMN user_roles.permissions IS '细粒度权限配置（JSON）';
COMMENT ON COLUMN user_roles.is_active IS '角色是否激活';
COMMENT ON COLUMN user_roles.banned_until IS '封禁截止时间（NULL表示永久封禁）';
COMMENT ON COLUMN user_roles.ban_reason IS '封禁原因';

-- ============================================
-- 触发器：自动更新 updated_at
-- ============================================
CREATE TRIGGER user_roles_updated_at
  BEFORE UPDATE ON user_roles
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- ============================================
-- 触发器：新用户自动分配默认角色
-- ============================================
CREATE OR REPLACE FUNCTION assign_default_role()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_roles (user_id, role, permissions)
  VALUES (NEW.id, 'user', '{"can_post": true, "can_comment": true, "can_like": true}')
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_assign_default_role
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION assign_default_role();

COMMENT ON FUNCTION assign_default_role IS '新用户注册时自动分配默认角色';

-- ============================================
-- RLS 策略
-- ============================================
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- 用户可以查看自己的角色
CREATE POLICY "Users can view their own role"
  ON user_roles FOR SELECT
  USING (auth.uid() = user_id);

-- 管理员可以查看所有角色
CREATE POLICY "Admins can view all roles"
  ON user_roles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'admin'
      AND ur.is_active = true
    )
  );

-- 管理员可以更新角色
CREATE POLICY "Admins can update roles"
  ON user_roles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'admin'
      AND ur.is_active = true
    )
  );

-- ============================================
-- 辅助函数：检查用户权限
-- ============================================
CREATE OR REPLACE FUNCTION has_permission(
  p_user_id UUID,
  p_permission VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
  v_role VARCHAR;
  v_permissions JSONB;
BEGIN
  SELECT role, permissions INTO v_role, v_permissions
  FROM user_roles
  WHERE user_id = p_user_id AND is_active = true;

  -- 如果没有找到角色，返回 false
  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- admin 拥有所有权限
  IF v_role = 'admin' THEN
    RETURN true;
  END IF;

  -- banned 用户没有任何权限
  IF v_role = 'banned' THEN
    RETURN false;
  END IF;

  -- 检查具体权限
  RETURN COALESCE((v_permissions->>p_permission)::BOOLEAN, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION has_permission IS '检查用户是否拥有特定权限';

-- ============================================
-- 辅助函数：检查用户角色
-- ============================================
CREATE OR REPLACE FUNCTION has_role(
  p_user_id UUID,
  p_role VARCHAR
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = p_user_id
    AND role = p_role
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION has_role IS '检查用户是否拥有特定角色';

-- ============================================
-- 初始化：创建第一个管理员（需要手动设置）
-- ============================================
-- 使用方式：
-- UPDATE user_roles SET role = 'admin' WHERE user_id = '<your-user-id>';
