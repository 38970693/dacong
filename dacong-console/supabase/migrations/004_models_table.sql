-- =============================================
-- AI 模型排行榜表 - DaCong
-- 存储 AI 模型信息和评分数据
-- =============================================

-- =============================================
-- 1. 创建 models 表
-- =============================================
CREATE TABLE IF NOT EXISTS models (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,                        -- 模型名称
  provider TEXT NOT NULL,                     -- 提供商
  category TEXT NOT NULL DEFAULT '综合',       -- 分类：综合、开源、RAG、代码、数学、多模态
  icon TEXT DEFAULT '🤖',                       -- 图标 emoji
  score DECIMAL(5,2) DEFAULT 0,                -- 综合评分
  change INTEGER DEFAULT 0,                    -- 排名变化
  description TEXT,                           -- 模型描述
  context_window INTEGER DEFAULT 128000,       -- 上下文窗口大小
  pricing_input DECIMAL(10,4),                -- 输入价格 ($/1M tokens)
  pricing_output DECIMAL(10,4),               -- 输出价格 ($/1M tokens)
  website_url TEXT,                           -- 官网链接
  api_endpoint TEXT,                          -- API 端点
  is_active BOOLEAN DEFAULT true,              -- 是否启用
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 2. 插入初始数据
-- =============================================
INSERT INTO models (name, provider, category, icon, score, change, description, context_window, pricing_input, pricing_output, website_url, is_active) VALUES
-- 综合类
('Claude 3.5 Sonnet', 'Anthropic', '综合', '🧠', 98.50, 0, 'Anthropic 最新旗舰模型，强大的推理和代码能力', 200000, 3.00, 15.00, 'https://claude.ai', true),
('GPT-4o', 'OpenAI', '综合', '🤖', 97.20, 1, 'OpenAI 最新多模态模型', 128000, 5.00, 15.00, 'https://platform.openai.com', true),
('Gemini 1.5 Pro', 'Google', '综合', '✨', 96.80, -1, 'Google 最强多模态模型，支持 1M tokens', 1000000, 1.25, 5.00, 'https://ai.google.dev', true),
('Gemini 2.0 Flash', 'Google', '综合', '⚡', 95.50, 2, 'Google 快速推理模型', 1000000, 0.00, 0.00, 'https://ai.google.dev', true),
('Deepseek V3', '深度求索', '综合', '🔍', 94.80, 3, '中国最强开源模型', 640000, 0.27, 1.10, 'https://platform.deepseek.com', true),

-- 开源类
('Llama 3.1 405B', 'Meta', '开源', '🦙', 94.30, 2, 'Meta 最大开源模型', 128000, NULL, NULL, 'https://llama.meta.com', true),
('Llama 3.1 70B', 'Meta', '开源', '🦙', 92.50, 0, 'Meta 高性能开源模型', 128000, NULL, NULL, 'https://llama.meta.com', true),
('Qwen 2.5 72B', '阿里', '开源', '🔮', 93.10, 0, '阿里开源旗舰模型', 128000, 0.60, 1.80, 'https://qwenlm.ai', true),
('Qwen 2.5 32B', '阿里', '开源', '🔮', 91.20, 1, '阿里高性能开源模型', 128000, 0.40, 1.20, 'https://qwenlm.ai', true),
('Mistral Large 2', 'Mistral', '开源', '🌊', 91.70, 1, 'Mistral 旗舰模型', 128000, 2.00, 6.00, 'https://mistral.ai', true),
('Yi-Large', '零一万物', '开源', 'Yi', 90.50, 0, '零一万物旗舰模型', 200000, 3.00, 9.00, 'https://www.lingyiwanwu.com', true),
('GLM-4', '智谱', '开源', 'GL', 89.80, -1, '智谱旗舰模型', 128000, 0.60, 1.80, 'https://www.zhipuai.cn', true),
('Baichuan 4', '百川', '开源', 'BC', 88.90, 1, '百川旗舰模型', 128000, 1.00, 3.00, 'https://www.baichuan-ai.com', true),

-- RAG 类
('Command R+', 'Cohere', 'RAG', '📚', 89.20, -1, '专为 RAG 优化的模型', 128000, 2.50, 10.00, 'https://cohere.com', true),
('Mistral 7B', 'Mistral', 'RAG', '🌊', 86.50, 0, '高性能开源 RAG 模型', 32000, NULL, NULL, 'https://mistral.ai', true),
('Gemma 2 27B', 'Google', 'RAG', '💎', 88.30, 2, 'Google 开源 RAG 模型', 32000, NULL, NULL, 'https://ai.google.dev', true),

-- 代码类
('Claude 3.5 Haiku', 'Anthropic', '代码', '💻', 95.20, 1, '快速代码模型', 200000, 0.25, 1.25, 'https://claude.ai', true),
('GPT-4o-mini', 'OpenAI', '代码', '🤖', 93.80, 0, 'OpenAI 高性价比代码模型', 128000, 0.15, 0.60, 'https://platform.openai.com', true),
('Code Llama 70B', 'Meta', '代码', '🦙', 90.10, 0, 'Meta 代码专用模型', 128000, NULL, NULL, 'https://llama.meta.com', true),
('Deepseek Coder', '深度求索', '代码', '🔍', 91.50, 2, '深度求索代码模型', 128000, 0.27, 1.10, 'https://platform.deepseek.com', true),

-- 数学类
('o3-mini', 'OpenAI', '数学', '🔢', 94.60, 1, 'OpenAI 数学推理模型', 200000, 1.10, 4.40, 'https://platform.openai.com', true),
('o1-mini', 'OpenAI', '数学', '🔢', 93.20, 0, 'OpenAI 轻量数学模型', 65536, 1.10, 4.40, 'https://platform.openai.com', true),
('Gemini 2.0 Flash Thinking', 'Google', '数学', '✨', 92.80, 3, 'Google 思维链模型', 1000000, 0.00, 0.00, 'https://ai.google.dev', true),

-- 多模态类
('GPT-4o Vision', 'OpenAI', '多模态', '👁️', 96.30, 0, 'OpenAI 视觉理解模型', 128000, 5.00, 15.00, 'https://platform.openai.com', true),
('Claude 3.5 Sonnet Vision', 'Anthropic', '多模态', '🧠', 97.50, 1, 'Anthropic 视觉理解模型', 200000, 3.00, 15.00, 'https://claude.ai', true),
('Gemini 1.5 Pro Vision', 'Google', '多模态', '✨', 95.70, -1, 'Google 多模态模型', 1000000, 1.25, 5.00, 'https://ai.google.dev', true)
ON CONFLICT DO NOTHING;

-- =============================================
-- 3. 创建索引
-- =============================================
CREATE INDEX IF NOT EXISTS idx_models_score ON models(score DESC);
CREATE INDEX IF NOT EXISTS idx_models_category ON models(category);
CREATE INDEX IF NOT EXISTS idx_models_provider ON models(provider);
CREATE INDEX IF NOT EXISTS idx_models_is_active ON models(is_active);
CREATE INDEX IF NOT EXISTS idx_models_created_at ON models(created_at DESC);

-- =============================================
-- 4. 自动更新 updated_at 触发器
-- =============================================
CREATE OR REPLACE FUNCTION update_models_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_models_updated_at ON models;
CREATE TRIGGER update_models_updated_at
  BEFORE UPDATE ON models
  FOR EACH ROW
  EXECUTE FUNCTION update_models_updated_at();

-- =============================================
-- 5. RLS 策略
-- =============================================
ALTER TABLE models ENABLE ROW LEVEL SECURITY;

-- 公开读取
DROP POLICY IF EXISTS "models_public_read" ON models;
CREATE POLICY "models_public_read" ON models
  FOR SELECT TO public USING (true);

-- 服务端写入
DROP POLICY IF EXISTS "models_service_write" ON models;
CREATE POLICY "models_service_write" ON models
  FOR ALL TO service_role USING (true);

-- =============================================
-- 6. 允许 anon key 读取（用于排行榜公开显示）
-- =============================================
GRANT SELECT ON models TO anon;
