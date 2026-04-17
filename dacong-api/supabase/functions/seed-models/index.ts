// Edge Function: seed-models
// 初始化种子模型数据（运行一次即可）
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const MODELS = [
  { name: 'GPT-4o', vendor: 'OpenAI', category: 'LLM', description: 'OpenAI 最新多模态大模型', tags: ['LLM', '多模态', 'GPT'] },
  { name: 'Claude 3.5 Sonnet', vendor: 'Anthropic', category: 'LLM', description: 'Anthropic 最强推理模型', tags: ['LLM', '推理'] },
  { name: 'Gemini 2.0 Flash', vendor: 'Google', category: 'LLM', description: 'Google 高效多模态模型', tags: ['LLM', '多模态', 'Gemini'] },
  { name: 'Llama 3.1 405B', vendor: 'Meta', category: 'LLM', description: 'Meta 开源大模型', tags: ['LLM', '开源', 'Meta'] },
  { name: 'Qwen 2.5 72B', vendor: 'Alibaba', category: 'LLM', description: '阿里通义千问开源模型', tags: ['LLM', '开源', 'Qwen'] },
  { name: 'DeepSeek-V2.5', vendor: 'DeepSeek', category: 'LLM', description: '幻方深度求索推理模型', tags: ['LLM', '推理', 'DeepSeek'] },
  { name: 'Stable Diffusion 3', vendor: 'Stability AI', category: '文生图', description: 'Stability AI 最新文生图模型', tags: ['文生图', 'SD3'] },
  { name: 'FLUX.1 Pro', vendor: 'BlackForestAI', category: '文生图', description: 'FLUX.1 专业版文生图', tags: ['文生图', 'FLUX'] },
  { name: 'Whisper Large v3', vendor: 'OpenAI', category: '语音识别', description: 'OpenAI 语音识别模型', tags: ['ASR', 'Whisper'] },
  { name: 'BGE-M3', vendor: 'BAAI', category: 'Embedding', description: '智源开源Embedding模型', tags: ['Embedding', '向量', 'BGE'] },
]

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  for (const m of MODELS) {
    await supabase.from('models').upsert(m, { onConflict: 'vendor,name' })
  }

  return new Response(JSON.stringify({ ok: true, count: MODELS.length }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
