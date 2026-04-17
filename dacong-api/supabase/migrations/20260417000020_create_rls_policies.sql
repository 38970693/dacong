-- Migration: Create RLS policies
-- Description: Row Level Security 策略

-- 启用 RLS
ALTER TABLE raw_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE published_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE scenario_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE spider_logs ENABLE ROW LEVEL SECURITY;

-- raw_data: 只有服务端可以访问
CREATE POLICY "Service role can do everything on raw_data"
ON raw_data FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- generated_content: 只有管理员可以访问
CREATE POLICY "Admins can do everything on generated_content"
ON generated_content FOR ALL
TO authenticated
USING (auth.jwt() ->> 'role' = 'admin')
WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- published_content: 所有人可以查看
CREATE POLICY "Anyone can view published_content"
ON published_content FOR SELECT
USING (true);

-- published_content: 只有管理员可以修改
CREATE POLICY "Admins can modify published_content"
ON published_content FOR ALL
TO authenticated
USING (auth.jwt() ->> 'role' = 'admin')
WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- user_feedback: 所有人可以创建
CREATE POLICY "Anyone can create feedback"
ON user_feedback FOR INSERT
WITH CHECK (true);

-- user_feedback: 用户可以查看自己的反馈
CREATE POLICY "Users can view own feedback"
ON user_feedback FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- user_feedback: 管理员可以查看所有反馈
CREATE POLICY "Admins can view all feedback"
ON user_feedback FOR SELECT
TO authenticated
USING (auth.jwt() ->> 'role' = 'admin');

-- scenario_recommendations: 所有人可以查看
CREATE POLICY "Anyone can view scenario_recommendations"
ON scenario_recommendations FOR SELECT
USING (active = true);

-- scenario_recommendations: 只有管理员可以修改
CREATE POLICY "Admins can modify scenario_recommendations"
ON scenario_recommendations FOR ALL
TO authenticated
USING (auth.jwt() ->> 'role' = 'admin')
WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- spider_logs: 只有服务端可以访问
CREATE POLICY "Service role can do everything on spider_logs"
ON spider_logs FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- spider_logs: 管理员可以查看
CREATE POLICY "Admins can view spider_logs"
ON spider_logs FOR SELECT
TO authenticated
USING (auth.jwt() ->> 'role' = 'admin');
