-- =============================================
-- 示例数据 - DaCong 快讯平台
-- 在 Supabase SQL Editor 中运行此脚本
-- =============================================

-- 插入示例 posts 数据
INSERT INTO posts (title, content, source, source_url, views, likes, comments_count, status, created_at)
VALUES
  ('36氪独家 | 字节跳动完成新一轮融资，估值达3000亿美元', '据36氪独家获悉，字节跳动已完成新一轮融资，本轮融资金额超40亿美元，投资方包括多家顶级VC。本轮融资后，字节跳动估值达到3000亿美元，成为全球估值最高的未上市科技公司之一。', '36kr', 'https://36kr.com/p/1234567890', 15420, 892, 156, 'approved', NOW() - INTERVAL '2 hours'),

  ('虎嗅深度 | AI大模型竞争进入下半场，垂直行业应用成新战场', '随着ChatGPT掀起的大模型浪潮逐渐平息，各大科技公司开始将目光转向垂直行业应用。医疗、法律、金融等领域成为新的竞争焦点。业内专家认为，垂直模型的商业化路径更加清晰，有望率先实现规模化盈利。', 'huxiu', 'https://www.huxiu.com/article/1234567.html', 8934, 456, 89, 'approved', NOW() - INTERVAL '5 hours'),

  ('融资快讯 | B2B供应链平台「融链科技」完成2亿元B轮融资', 'B2B供应链服务平台融链科技今日宣布完成2亿元人民币B轮融资，由红杉中国领投，老股东跟投。融链科技主要服务于制造业，提供从原材料采购到物流配送的全链条数字化解决方案。', '36kr', 'https://36kr.com/p/1234567891', 5621, 234, 45, 'approved', NOW() - INTERVAL '8 hours'),

  ('虎嗅早报 | 阿里云宣布全面降价，最高降幅达40%', '阿里云今日宣布对其核心云产品进行全面降价，其中对象存储OSS最高降幅达40%，云服务器ECS降幅20%。这是阿里云年内第三次大幅降价，业内人士认为这是应对竞争加剧的策略调整。', 'huxiu', 'https://www.huxiu.com/article/1234568.html', 12456, 678, 123, 'approved', NOW() - INTERVAL '12 hours'),

  ('36氪创投日报 | 今日国内融资事件汇总（2024-03-15）', '今日国内共发生融资事件42起，融资总额约28亿元。值得关注的是，硬科技领域继续保持高热度，共获得12起融资。此外，新能源汽车产业链上下游企业表现活跃。', '36kr', 'https://36kr.com/p/1234567892', 7823, 345, 67, 'approved', NOW() - INTERVAL '1 day'),

  ('独家 | 京东战投部换帅，前阿里战投负责人加盟', '据知情人士透露，京东集团战投部门近期完成人事调整，前阿里资本合伙人张明（化名）已正式加盟，出任战投负责人。业内人士分析，这一人事变动或意味着京东将在投资策略上有更大动作。', '36kr', 'https://36kr.com/p/1234567893', 21567, 1203, 234, 'approved', NOW() - INTERVAL '1 day 6 hours'),

  ('虎嗅观察 | 拼多多Temu加速全球化，欧美市场GMV突破50亿美元', '拼多多旗下跨境电商平台Temu最新数据显示，其欧美市场GMV已突破50亿美元大关。上线仅一年半，Temu已覆盖全球40多个国家和地区，成为出海最成功的中国电商平台。', 'huxiu', 'https://www.huxiu.com/article/1234569.html', 18934, 867, 178, 'approved', NOW() - INTERVAL '2 days'),

  ('行业报告 | 2024年中国SaaS市场预计突破1500亿元', '艾瑞咨询发布的最新报告显示，2024年中国SaaS市场规模预计将达到1500亿元，同比增长25%。其中，协同办公CRM等通用型SaaS仍是市场主力，但垂直行业SaaS增速更为迅猛。', '36kr', 'https://36kr.com/p/1234567894', 6234, 289, 56, 'approved', NOW() - INTERVAL '2 days 12 hours'),

  ('快讯 | 美团外卖宣布即时配送网络升级，覆盖全国2800个县', '美团外卖今日宣布完成即时配送网络重大升级，目前已覆盖全国2800个县级行政区，覆盖率超过95%。升级后的配送网络可将平均送达时间缩短至28分钟。', 'huxiu', 'https://www.huxiu.com/article/1234570.html', 9456, 423, 89, 'approved', NOW() - INTERVAL '3 days'),

  ('36氪首发 | 工业互联网平台「智造云」获数千万元A轮融资', '工业互联网解决方案提供商智造云宣布完成数千万元A轮融资，由GGV纪源资本领投。智造云主要面向中小制造企业提供产线数字化改造服务，目前已服务超过500家企业客户。', '36kr', 'https://36kr.com/p/1234567895', 4567, 198, 34, 'approved', NOW() - INTERVAL '4 days');

-- 插入示例 trending_cache 数据
-- 基于 posts 数据创建热榜
DO $$
DECLARE
  hot_post RECORD;
  new_post RECORD;
  rank_num INTEGER := 1;
BEGIN
  FOR hot_post IN
    SELECT p.id, p.likes, p.views, p.comments_count,
           (p.likes * 3 + p.views * 0.1 + p.comments_count * 2) as score
    FROM posts p
    WHERE p.status = 'approved'
    ORDER BY score DESC
    LIMIT 20
  LOOP
    INSERT INTO trending_cache (post_id, list_type, score, rank, updated_at)
    VALUES (hot_post.id, 'hot', hot_post.score, rank_num, NOW())
    ON CONFLICT (list_type, rank) DO UPDATE SET
      post_id = EXCLUDED.post_id,
      score = EXCLUDED.score,
      updated_at = NOW();
    rank_num := rank_num + 1;
  END LOOP;

  -- 创建最新榜
  rank_num := 1;
  FOR new_post IN
    SELECT id, created_at
    FROM posts
    WHERE status = 'approved'
    ORDER BY created_at DESC
    LIMIT 20
  LOOP
    INSERT INTO trending_cache (post_id, list_type, score, rank, updated_at)
    VALUES (new_post.id, 'new', 1, rank_num, NOW())
    ON CONFLICT (list_type, rank) DO UPDATE SET
      post_id = EXCLUDED.post_id,
      updated_at = NOW();
    rank_num := rank_num + 1;
  END LOOP;
END $$;

-- 验证数据
SELECT 'Posts count:' as info, COUNT(*) as count FROM posts
UNION ALL
SELECT 'Approved posts:', COUNT(*) FROM posts WHERE status = 'approved'
UNION ALL
SELECT 'Trending hot:', COUNT(*) FROM trending_cache WHERE list_type = 'hot'
UNION ALL
SELECT 'Trending new:', COUNT(*) FROM trending_cache WHERE list_type = 'new';