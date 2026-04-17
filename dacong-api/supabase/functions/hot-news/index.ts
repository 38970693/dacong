// Edge Function: hot-news
// 处理快讯：去重 + AI关键词过滤 + 更新 trending_keywords
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const AI_KEYWORDS = [
  'LLM', 'GPT', 'Claude', 'Gemini', 'Llama', 'Mistral',
  '文心', '通义', '智谱', '盘古', '混元', '天工',
  'Stable Diffusion', 'Midjourney', 'DALL-E', 'FLUX',
  'Whisper', 'TTS', 'STT', 'Embedding', '向量',
  'RAG', 'Agent', 'AI Agent', 'Copilot',
]

function isAI(title: string): boolean {
  const lower = title.toLowerCase()
  return AI_KEYWORDS.some(k => lower.includes(k.toLowerCase()))
}

Deno.serve(async (req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  const { items } = await req.json()

  const inserted: number[] = []
  for (const item of items ?? []) {
    const ai = isAI(item.title ?? '')
    const { data, error } = await supabase.from('hot_news_raw').insert({
      source: item.source ?? 'HN',
      title: item.title,
      url: item.url,
      summary: item.summary ?? '',
      author: item.author ?? '',
      score: item.score ?? 0,
      is_ai_related: ai,
    }).select('id')

    if (!error && data?.[0]) inserted.push(data[0].id)
  }

  return new Response(JSON.stringify({ ok: true, inserted: inserted.length }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
