-- 每日 02:00 UTC 触发 compute-rising-stars，生成 GitHub 飙升榜快照
--
-- ⚠️ 这不是 migration，不要放进 migrations/ 目录自动执行。
--    请先在 Supabase Dashboard → SQL Editor 中把下面两个占位符替换掉再运行：
--      <SUPABASE_URL>        例如 https://twrxnqrisplmetbceyqm.supabase.co
--      <SERVICE_ROLE_KEY>    项目 Settings → API → service_role key
--
-- 时间说明：02:00 早于 03:00 的每日全量汇总，用的是前一日已落库的
--          repository_metrics 时间序列，避免读到半途写入的数据。
--
-- 依赖扩展：pg_cron（调度）、pg_net（HTTP 调用）。首次使用需先启用：
--   create extension if not exists pg_cron;
--   create extension if not exists pg_net;

select cron.schedule(
  'compute-rising-stars-daily',
  '0 2 * * *',
  $$
  select net.http_post(
    url := '<SUPABASE_URL>/functions/v1/compute-rising-stars',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer <SERVICE_ROLE_KEY>"}'::jsonb,
    body := '{}'::jsonb
  )
  $$
);

-- 查看已注册的定时任务：
--   select jobid, jobname, schedule, active from cron.job;
--
-- 暂停 / 恢复 / 删除：
--   select cron.unschedule('compute-rising-stars-daily');
