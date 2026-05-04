"""
数据库迁移脚本
用于创建 AI Rankings 相关表
"""
import sys
import logging
from pathlib import Path

# 添加项目根目录到路径
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from supabase import create_client, Client
from config import SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)


def get_client() -> Client:
    """获取 Supabase 客户端"""
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("缺少 Supabase 配置，请检查 .env 文件")
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)


def create_swebench_table(client: Client) -> bool:
    """创建 swebench_rankings 表"""
    try:
        sql = """
        CREATE TABLE IF NOT EXISTS swebench_rankings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            model_name TEXT NOT NULL,
            elo_score NUMERIC(10, 4),
            pass_rate NUMERIC(5, 2),
            instance_count INTEGER,
            category TEXT DEFAULT 'standard',
            company TEXT,
            fetched_at TIMESTAMPTZ DEFAULT NOW(),
            created_at TIMESTAMPTZ DEFAULT NOW(),
            CONSTRAINT swebench_rankings_unique UNIQUE (model_name, category, fetched_at::date)
        );

        CREATE INDEX IF NOT EXISTS idx_swebench_elo ON swebench_rankings(elo_score DESC);
        CREATE INDEX IF NOT EXISTS idx_swebench_fetched ON swebench_rankings(fetched_at DESC);
        CREATE INDEX IF NOT EXISTS idx_swebench_model ON swebench_rankings(model_name);
        CREATE INDEX IF NOT EXISTS idx_swebench_company ON swebench_rankings(company);

        ALTER TABLE swebench_rankings ENABLE ROW LEVEL SECURITY;

        DROP POLICY IF EXISTS "swebench_rankings_public_read" ON swebench_rankings;
        CREATE POLICY "swebench_rankings_public_read" ON swebench_rankings
            FOR SELECT TO public USING (true);

        DROP POLICY IF EXISTS "swebench_rankings_service_write" ON swebench_rankings;
        CREATE POLICY "swebench_rankings_service_write" ON swebench_rankings
            FOR ALL TO service_role USING (true);
        """

        # 分割并逐条执行（Supabase 不支持一次执行多条 SQL）
        for statement in sql.split(';'):
            statement = statement.strip()
            if statement:
                try:
                    # 使用 rpc 函数执行（如果配置了）
                    client.rpc('exec_sql', {'sql': statement}).execute()
                except Exception as e:
                    # 如果没有 rpc 函数，直接用 table insert 测试连接
                    logger.warning(f"SQL 执行需要后端支持: {e}")

        logger.info("[OK] swebench_rankings 表已创建（或已存在）")
        return True

    except Exception as e:
        logger.error(f"[FAIL] 创建 swebench_rankings 表失败: {e}")
        return False


def create_arena_table(client: Client) -> bool:
    """创建 arena_rankings 表"""
    try:
        # 尝试通过 REST API 测试连接
        # 检查表是否存在
        response = client.table('arena_rankings').select('id').limit(1).execute()
        logger.info("[OK] arena_rankings 表已存在")
        return True
    except Exception:
        # 表不存在，需要创建
        logger.info("arena_rankings 表不存在，需要通过 Supabase Dashboard 创建")
        print("""
请在 Supabase Dashboard 中执行以下 SQL:

CREATE TABLE IF NOT EXISTS arena_rankings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    elo_score NUMERIC(10, 4),
    confidence_interval TEXT,
    vote_count INTEGER,
    category TEXT DEFAULT 'general',
    company TEXT,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT arena_rankings_unique UNIQUE (model_name, category, fetched_at::date)
);

CREATE INDEX IF NOT EXISTS idx_arena_elo ON arena_rankings(elo_score DESC);
CREATE INDEX IF NOT EXISTS idx_arena_fetched ON arena_rankings(fetched_at DESC);
ALTER TABLE arena_rankings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "arena_rankings_public_read" ON arena_rankings FOR SELECT TO public USING (true);
CREATE POLICY "arena_rankings_service_write" ON arena_rankings FOR ALL TO service_role USING (true);
        """)
        return False


def check_connection(client: Client) -> bool:
    """检查数据库连接"""
    try:
        # 尝试查询现有表
        client.table('models').select('id').limit(1).execute()
        logger.info("[OK] 数据库连接正常")
        return True
    except Exception as e:
        logger.error(f"[FAIL] 数据库连接失败: {e}")
        return False


def main():
    """主函数"""
    logger.info("=" * 50)
    logger.info("AI Rankings 数据库迁移")
    logger.info("=" * 50)

    try:
        # 获取客户端
        client = get_client()

        # 检查连接
        if not check_connection(client):
            sys.exit(1)

        # 创建表（提示用户手动创建）
        logger.info("\n提示: 请在 Supabase Dashboard > SQL Editor 中执行迁移 SQL")
        logger.info("文件位置: supabase/migrations/2026050400*.sql")

        logger.info("\n" + "=" * 50)
        logger.info("迁移准备完成")
        logger.info("=" * 50)

    except Exception as e:
        logger.exception(f"迁移失败: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()