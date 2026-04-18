-- Migration: Seed recommendation data
-- Description: 为4个核心场景生成真实的推荐内容

-- ============================================
-- 1. 插入 published_content 数据
-- ============================================

-- 1.1 Coding 场景推荐
INSERT INTO published_content (id, content_type, title_zh, summary_zh, content_zh, scenario) VALUES
-- Cursor + DeepSeek (最佳)
('11111111-1111-1111-1111-111111111111', 'recommendation', 'Cursor + DeepSeek', '国内最佳AI编程组合，速度快、成本低',
'{
  "tool_name": "Cursor + DeepSeek",
  "description": "Cursor编辑器搭配DeepSeek模型，国内开发者的最佳选择",
  "pros": ["国内访问速度快，无需VPN", "DeepSeek模型性价比极高，成本仅为GPT-4的1/10", "Cursor界面友好，支持多种编程语言"],
  "cons": ["DeepSeek在某些复杂场景下不如GPT-4", "需要单独配置API密钥"],
  "target_audience": "国内开发者、预算有限的个人开发者",
  "price": "DeepSeek: ¥0.001/1K tokens, Cursor: $20/月",
  "available_in_china": true,
  "rating": 4.8,
  "type": "best"
}', 'coding'),

-- GitHub Copilot (平替)
('11111111-1111-1111-1111-111111111112', 'recommendation', 'GitHub Copilot', '微软官方AI编程助手，集成度最高',
'{
  "tool_name": "GitHub Copilot",
  "description": "微软推出的AI编程助手，与VS Code深度集成",
  "pros": ["与VS Code无缝集成，开箱即用", "代码补全准确率高", "支持多种编程语言和框架"],
  "cons": ["需要VPN访问", "价格相对较高", "对网络要求高"],
  "target_audience": "VS Code用户、企业开发团队",
  "price": "$10/月（个人）, $19/月（企业）",
  "available_in_china": false,
  "rating": 4.5,
  "type": "alternative"
}', 'coding'),

-- Codeium (免费)
('11111111-1111-1111-1111-111111111113', 'recommendation', 'Codeium', '完全免费的AI编程助手',
'{
  "tool_name": "Codeium",
  "description": "免费的AI代码补全工具，支持70+种编程语言",
  "pros": ["完全免费，无使用限制", "支持多种IDE（VS Code、JetBrains等）", "响应速度快"],
  "cons": ["功能相对简单，不如付费工具强大", "需要VPN访问"],
  "target_audience": "学生、个人开发者、预算为零的团队",
  "price": "免费",
  "available_in_china": false,
  "rating": 4.2,
  "type": "free"
}', 'coding'),

-- 1.2 Video 场景推荐
-- Runway (最佳)
('22222222-2222-2222-2222-222222222221', 'recommendation', 'Runway', 'AI视频生成领域的领导者',
'{
  "tool_name": "Runway",
  "description": "专业级AI视频生成和编辑工具，支持文生视频、图生视频",
  "pros": ["视频质量最高，细节丰富", "支持多种AI功能（去背景、超分辨率等）", "持续更新，功能强大"],
  "cons": ["价格较高", "需要VPN访问", "渲染速度较慢"],
  "target_audience": "专业视频创作者、影视制作团队",
  "price": "$12/月起（125积分），$28/月（625积分）",
  "available_in_china": false,
  "rating": 4.7,
  "type": "best"
}', 'video'),

-- CapCut (平替)
('22222222-2222-2222-2222-222222222222', 'recommendation', 'CapCut（剪映）', '字节跳动出品，国内最好用的视频编辑工具',
'{
  "tool_name": "CapCut（剪映）",
  "description": "字节跳动旗下的视频编辑工具，集成AI功能",
  "pros": ["国内访问无障碍", "AI功能丰富（智能字幕、AI配音等）", "移动端和桌面端体验都很好"],
  "cons": ["AI视频生成功能相对简单", "部分高级功能需要会员"],
  "target_audience": "短视频创作者、自媒体运营者",
  "price": "基础版免费，专业版 ¥30/月",
  "available_in_china": true,
  "rating": 4.6,
  "type": "alternative"
}', 'video'),

-- DaVinci Resolve (免费)
('22222222-2222-2222-2222-222222222223', 'recommendation', 'DaVinci Resolve', '好莱坞级免费视频编辑软件',
'{
  "tool_name": "DaVinci Resolve",
  "description": "专业级视频编辑软件，免费版功能已经非常强大",
  "pros": ["免费版功能完整，无水印", "专业级调色功能", "性能优秀，支持8K视频"],
  "cons": ["学习曲线陡峭", "AI功能较少", "对硬件要求高"],
  "target_audience": "专业视频编辑、影视后期制作",
  "price": "免费（Studio版 $295买断）",
  "available_in_china": true,
  "rating": 4.5,
  "type": "free"
}', 'video'),

-- 1.3 Image 场景推荐
-- Midjourney (最佳)
('33333333-3333-3333-3333-333333333331', 'recommendation', 'Midjourney', 'AI绘画领域的标杆',
'{
  "tool_name": "Midjourney",
  "description": "最受欢迎的AI绘画工具，画质精美，风格多样",
  "pros": ["画质最高，细节丰富", "社区活跃，可以学习他人提示词", "持续更新，V6版本质量惊艳"],
  "cons": ["需要通过Discord使用，不够直观", "需要VPN访问", "价格较高"],
  "target_audience": "专业设计师、插画师、艺术创作者",
  "price": "$10/月（基础版），$30/月（标准版）",
  "available_in_china": false,
  "rating": 4.9,
  "type": "best"
}', 'image'),

-- Stable Diffusion (平替)
('33333333-3333-3333-3333-333333333332', 'recommendation', 'Stable Diffusion', '开源AI绘画工具，可本地部署',
'{
  "tool_name": "Stable Diffusion",
  "description": "开源的AI绘画模型，支持本地部署和在线使用",
  "pros": ["完全开源，可本地部署", "模型丰富，可自定义训练", "国内有多个镜像站点"],
  "cons": ["本地部署需要较高配置（显卡）", "使用门槛较高", "画质不如Midjourney稳定"],
  "target_audience": "技术爱好者、需要本地部署的团队",
  "price": "开源免费（本地部署），在线服务约 $10/月",
  "available_in_china": true,
  "rating": 4.4,
  "type": "alternative"
}', 'image'),

-- DALL-E 3 (免费)
('33333333-3333-3333-3333-333333333333', 'recommendation', 'DALL-E 3（通过Bing）', '微软Bing集成，每天免费生成',
'{
  "tool_name": "DALL-E 3（通过Bing）",
  "description": "OpenAI的DALL-E 3模型，通过Bing Image Creator免费使用",
  "pros": ["每天免费生成15张图片", "画质优秀，理解能力强", "无需注册OpenAI账号"],
  "cons": ["需要VPN访问", "每天有生成次数限制", "速度较慢"],
  "target_audience": "个人用户、轻度使用者",
  "price": "免费（通过Bing），ChatGPT Plus $20/月",
  "available_in_china": false,
  "rating": 4.3,
  "type": "free"
}', 'image'),

-- 1.4 Chat 场景推荐
-- ChatGPT (最佳)
('44444444-4444-4444-4444-444444444441', 'recommendation', 'ChatGPT', 'AI对话领域的开创者',
'{
  "tool_name": "ChatGPT",
  "description": "OpenAI推出的AI对话助手，功能最全面",
  "pros": ["功能最全面（对话、写作、编程、分析等）", "GPT-4模型能力最强", "插件生态丰富"],
  "cons": ["需要VPN访问", "Plus版本价格较高", "国内支付困难"],
  "target_audience": "知识工作者、内容创作者、开发者",
  "price": "免费版（GPT-3.5），Plus $20/月（GPT-4）",
  "available_in_china": false,
  "rating": 4.8,
  "type": "best"
}', 'chat'),

-- Claude (平替)
('44444444-4444-4444-4444-444444444442', 'recommendation', 'Claude', 'Anthropic出品，长文本处理能力强',
'{
  "tool_name": "Claude",
  "description": "Anthropic推出的AI助手，擅长长文本分析和写作",
  "pros": ["长文本处理能力最强（200K tokens）", "回答更加谨慎和准确", "界面简洁易用"],
  "cons": ["需要VPN访问", "功能相对单一", "国内知名度较低"],
  "target_audience": "需要处理长文档的用户、研究人员",
  "price": "免费版，Pro $20/月",
  "available_in_china": false,
  "rating": 4.6,
  "type": "alternative"
}', 'chat'),

-- Gemini (免费)
('44444444-4444-4444-4444-444444444443', 'recommendation', 'Gemini', 'Google出品，免费使用',
'{
  "tool_name": "Gemini",
  "description": "Google推出的AI助手，与Google生态深度集成",
  "pros": ["完全免费，无使用限制", "与Google服务集成（Gmail、Docs等）", "支持多模态（文本、图片）"],
  "cons": ["需要VPN访问", "中文能力相对较弱", "功能更新较慢"],
  "target_audience": "Google生态用户、预算有限的用户",
  "price": "免费",
  "available_in_china": false,
  "rating": 4.2,
  "type": "free"
}', 'chat');

-- ============================================
-- 2. 插入 scenario_recommendations 关联数据
-- ============================================

INSERT INTO scenario_recommendations (scenario, rank, content_id, active) VALUES
-- Coding 场景
('coding', 1, '11111111-1111-1111-1111-111111111111', true),  -- Cursor + DeepSeek (最佳)
('coding', 2, '11111111-1111-1111-1111-111111111112', true),  -- GitHub Copilot (平替)
('coding', 3, '11111111-1111-1111-1111-111111111113', true),  -- Codeium (免费)

-- Video 场景
('video', 1, '22222222-2222-2222-2222-222222222221', true),   -- Runway (最佳)
('video', 2, '22222222-2222-2222-2222-222222222222', true),   -- CapCut (平替)
('video', 3, '22222222-2222-2222-2222-222222222223', true),   -- DaVinci Resolve (免费)

-- Image 场景
('image', 1, '33333333-3333-3333-3333-333333333331', true),   -- Midjourney (最佳)
('image', 2, '33333333-3333-3333-3333-333333333332', true),   -- Stable Diffusion (平替)
('image', 3, '33333333-3333-3333-3333-333333333333', true),   -- DALL-E 3 (免费)

-- Chat 场景
('chat', 1, '44444444-4444-4444-4444-444444444441', true),    -- ChatGPT (最佳)
('chat', 2, '44444444-4444-4444-4444-444444444442', true),    -- Claude (平替)
('chat', 3, '44444444-4444-4444-4444-444444444443', true);    -- Gemini (免费)

-- ============================================
-- 3. 验证数据
-- ============================================

-- 验证每个场景都有3个推荐
DO $$
DECLARE
  scenario_name TEXT;
  rec_count INT;
BEGIN
  FOR scenario_name IN SELECT DISTINCT scenario FROM scenario_recommendations LOOP
    SELECT COUNT(*) INTO rec_count
    FROM scenario_recommendations
    WHERE scenario = scenario_name AND active = true;

    IF rec_count != 3 THEN
      RAISE EXCEPTION 'Scenario % should have 3 recommendations, but has %', scenario_name, rec_count;
    END IF;
  END LOOP;

  RAISE NOTICE 'Seed data validation passed: All scenarios have 3 recommendations';
END $$;
