-- 配置 AI_NEWS_TRANSLATION_PROVIDER=mymemory（免 Key）或 ANTHROPIC_API_KEY 并验证翻译后执行。
-- 复用 deploy-cron-ai-news.sql 已配置的 Vault 凭据。
SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname = 'translate-ai-news-quarter-hourly';
SELECT cron.schedule(
  'translate-ai-news-quarter-hourly',
  '7,22,37,52 * * * *',
  $$
  SELECT net.http_post(
    url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'project_url') || '/functions/v1/translate-ai-news',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
  $$
);
