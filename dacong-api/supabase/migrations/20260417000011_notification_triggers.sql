-- 通知触发器 - 自动发送通知
-- 评论被回复时发送通知
CREATE OR REPLACE FUNCTION notify_comment_reply()
RETURNS TRIGGER AS $$
DECLARE
  parent_comment RECORD;
  content_title TEXT;
BEGIN
  -- 如果是回复评论（有parent_id）
  IF NEW.parent_id IS NOT NULL THEN
    -- 获取父评论信息
    SELECT * INTO parent_comment
    FROM comments
    WHERE id = NEW.parent_id;

    -- 获取内容标题
    SELECT title_zh INTO content_title
    FROM published_content
    WHERE id = NEW.content_id;

    -- 发送通知给父评论作者（不给自己发通知）
    IF parent_comment.user_id != NEW.user_id THEN
      INSERT INTO notifications (user_id, type, title, content, link)
      VALUES (
        parent_comment.user_id,
        'comment_reply',
        '收到新回复',
        '有人回复了你在《' || content_title || '》的评论',
        '/content/' || NEW.content_id || '?comment=' || NEW.id
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
DROP TRIGGER IF EXISTS trigger_notify_comment_reply ON comments;
CREATE TRIGGER trigger_notify_comment_reply
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION notify_comment_reply();

-- 内容被收藏时发送通知
CREATE OR REPLACE FUNCTION notify_favorite()
RETURNS TRIGGER AS $$
DECLARE
  content_record RECORD;
BEGIN
  -- 获取内容信息
  SELECT * INTO content_record
  FROM published_content
  WHERE id = NEW.content_id;

  -- 如果内容有作者（系统生成的内容可能没有user_id）
  -- 这里假设published_content表有author_id字段，如果没有则跳过
  -- 由于当前表结构没有author_id，这个触发器暂时不发送通知
  -- 可以在后续添加author_id字段后启用

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器（暂时禁用，等待author_id字段）
-- DROP TRIGGER IF EXISTS trigger_notify_favorite ON favorites;
-- CREATE TRIGGER trigger_notify_favorite
--   AFTER INSERT ON favorites
--   FOR EACH ROW
--   EXECUTE FUNCTION notify_favorite();

-- 系统公告通知函数（手动调用）
CREATE OR REPLACE FUNCTION send_system_announcement(
  p_title TEXT,
  p_content TEXT,
  p_link TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
  affected_count INTEGER;
BEGIN
  -- 给所有用户发送系统公告
  INSERT INTO notifications (user_id, type, title, content, link)
  SELECT
    id,
    'system_announcement',
    p_title,
    p_content,
    p_link
  FROM auth.users;

  GET DIAGNOSTICS affected_count = ROW_COUNT;

  RETURN affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 注释
COMMENT ON FUNCTION notify_comment_reply() IS '评论被回复时自动发送通知';
COMMENT ON FUNCTION notify_favorite() IS '内容被收藏时自动发送通知（待启用）';
COMMENT ON FUNCTION send_system_announcement(TEXT, TEXT, TEXT) IS '发送系统公告给所有用户';

-- 使用示例：
-- SELECT send_system_announcement('系统维护通知', '系统将于今晚22:00-23:00进行维护', '/announcements/1');
