-- 检查 posts 表结构
SELECT 
  column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'posts';
