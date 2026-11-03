-- Run with a database administrator. All fixtures are rolled back.
BEGIN;
INSERT INTO auth.users(id) VALUES ('00000000-0000-4000-8000-000000000101'),('00000000-0000-4000-8000-000000000102');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',true);
INSERT INTO public.ai_showcases(user_id,kind,title,summary,creator_name,demo_url)
VALUES ('00000000-0000-4000-8000-000000000101','work','permission-check','fixture','fixture','https://example.com');
DO $$ BEGIN
  BEGIN
    INSERT INTO public.ai_showcases(user_id,kind,title,summary,creator_name)
    VALUES ('00000000-0000-4000-8000-000000000102','idea','spoof','fixture','fixture');
    RAISE EXCEPTION 'Owner spoof accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000102',true);
DO $$ DECLARE changed integer; BEGIN
  UPDATE public.ai_showcases SET status='withdrawn' WHERE title='permission-check';
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 0 THEN RAISE EXCEPTION 'Other user can withdraw'; END IF;
END $$;
SET LOCAL ROLE anon;
DO $$ BEGIN
  IF (SELECT count(*) FROM public.ai_showcases WHERE title='permission-check') <> 1 THEN RAISE EXCEPTION 'Public read failed'; END IF;
  BEGIN
    INSERT INTO public.ai_showcases(user_id,kind,title,summary,creator_name)
    VALUES ('00000000-0000-4000-8000-000000000101','idea','anon-post','fixture','fixture');
    RAISE EXCEPTION 'Anonymous insert accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',true);
UPDATE public.ai_showcases SET status='withdrawn' WHERE title='permission-check';
DO $$ BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.ai_showcases WHERE title='permission-check' AND status='withdrawn') THEN RAISE EXCEPTION 'Owner withdrawal failed'; END IF;
END $$;
SET LOCAL ROLE anon;
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM public.ai_showcases WHERE title='permission-check') THEN RAISE EXCEPTION 'Withdrawn content leaked'; END IF;
END $$;
ROLLBACK;
