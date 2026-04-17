-- 搜索内容 Edge Function
-- 使用 PostgreSQL 全文搜索功能

create or replace function search_content(
  search_query text,
  search_scenario text default null,
  search_is_free boolean default null,
  search_available_in_china boolean default null,
  sort_by text default 'relevance',
  result_limit int default 20,
  result_offset int default 0
)
returns table (
  id uuid,
  content_type text,
  title_zh text,
  summary_zh text,
  content_zh jsonb,
  title_en text,
  summary_en text,
  content_en jsonb,
  scenario text,
  view_count int,
  helpful_count int,
  unhelpful_count int,
  share_count int,
  published_at timestamptz,
  updated_at timestamptz,
  relevance_score float
)
language plpgsql
as $$
begin
  return query
  select
    pc.id,
    pc.content_type,
    pc.title_zh,
    pc.summary_zh,
    pc.content_zh,
    pc.title_en,
    pc.summary_en,
    pc.content_en,
    pc.scenario,
    pc.view_count,
    pc.helpful_count,
    pc.unhelpful_count,
    pc.share_count,
    pc.published_at,
    pc.updated_at,
    -- 计算相关度分数
    case
      when sort_by = 'relevance' then
        ts_rank(
          to_tsvector('simple', coalesce(pc.title_zh, '') || ' ' || coalesce(pc.summary_zh, '')),
          to_tsquery('simple', search_query)
        )
      else 0
    end as relevance_score
  from published_content pc
  where
    -- 全文搜索（中文）
    (
      to_tsvector('simple', coalesce(pc.title_zh, '') || ' ' || coalesce(pc.summary_zh, ''))
      @@ to_tsquery('simple', search_query)
      or
      -- 全文搜索（英文）
      to_tsvector('english', coalesce(pc.title_en, '') || ' ' || coalesce(pc.summary_en, ''))
      @@ to_tsquery('english', search_query)
      or
      -- 模糊匹配
      pc.title_zh ilike '%' || search_query || '%'
      or pc.summary_zh ilike '%' || search_query || '%'
      or pc.title_en ilike '%' || search_query || '%'
      or pc.summary_en ilike '%' || search_query || '%'
    )
    -- 场景筛选
    and (search_scenario is null or pc.scenario = search_scenario)
    -- 价格筛选（JSONB 查询）
    and (
      search_is_free is null
      or (pc.content_zh->'priceInfo'->>'isFree')::boolean = search_is_free
    )
    -- 访问方式筛选（JSONB 查询）
    and (
      search_available_in_china is null
      or (pc.content_zh->'accessInfo'->>'availableInChina')::boolean = search_available_in_china
    )
  order by
    case
      when sort_by = 'relevance' then relevance_score
      when sort_by = 'rating' then pc.helpful_count::float / nullif(pc.helpful_count + pc.unhelpful_count, 0)
      when sort_by = 'viewCount' then pc.view_count::float
      else pc.published_at::text::float
    end desc
  limit result_limit
  offset result_offset;
end;
$$;

-- 创建索引以提高搜索性能
create index if not exists idx_published_content_search_zh
on published_content
using gin(to_tsvector('simple', title_zh || ' ' || coalesce(summary_zh, '')));

create index if not exists idx_published_content_search_en
on published_content
using gin(to_tsvector('english', coalesce(title_en, '') || ' ' || coalesce(summary_en, '')));

-- JSONB 索引
create index if not exists idx_published_content_zh_gin
on published_content
using gin(content_zh);

create index if not exists idx_published_content_en_gin
on published_content
using gin(content_en);

-- 注释
comment on function search_content is '全文搜索内容，支持中英文、筛选、排序';
