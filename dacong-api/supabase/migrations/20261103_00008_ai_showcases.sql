CREATE TABLE public.ai_showcases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('work','idea')),
  title text NOT NULL CHECK (length(btrim(title)) BETWEEN 1 AND 80),
  summary text NOT NULL CHECK (length(btrim(summary)) BETWEEN 1 AND 300),
  content text NOT NULL DEFAULT '' CHECK (length(content) <= 5000),
  creator_name text NOT NULL CHECK (length(btrim(creator_name)) BETWEEN 1 AND 40),
  demo_url text CHECK (demo_url IS NULL OR (length(demo_url) <= 2000 AND demo_url ~ '^https://[^[:space:]]+$')),
  source_url text CHECK (source_url IS NULL OR (length(source_url) <= 2000 AND source_url ~ '^https://[^[:space:]]+$')),
  status text NOT NULL DEFAULT 'published' CHECK (status IN ('published','withdrawn')),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (kind <> 'work' OR demo_url IS NOT NULL)
);
CREATE INDEX ai_showcases_feed ON public.ai_showcases(status, created_at DESC, id DESC);
ALTER TABLE public.ai_showcases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.ai_showcases FROM anon, authenticated;
GRANT SELECT ON public.ai_showcases TO anon, authenticated;
GRANT INSERT(user_id,kind,title,summary,content,creator_name,demo_url,source_url) ON public.ai_showcases TO authenticated;
GRANT UPDATE(status) ON public.ai_showcases TO authenticated;
CREATE POLICY showcase_read ON public.ai_showcases FOR SELECT USING (status='published');
CREATE POLICY showcase_owner_read ON public.ai_showcases FOR SELECT TO authenticated USING (user_id=auth.uid());
CREATE POLICY showcase_share ON public.ai_showcases FOR INSERT TO authenticated WITH CHECK (user_id=auth.uid() AND status='published');
CREATE POLICY showcase_withdraw ON public.ai_showcases FOR UPDATE TO authenticated USING (user_id=auth.uid()) WITH CHECK (user_id=auth.uid());
