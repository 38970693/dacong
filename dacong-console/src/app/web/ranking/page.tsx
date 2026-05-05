'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import { createSupabaseClient } from '@/utils/supabase/client';

// raw_data 表的 metadata 结构
interface ModelMetadata {
  elo_rating?: number;
  vote_count?: number;
  category?: string;
  organization?: string;
  [key: string]: unknown;
}

// raw_data 表数据类型
interface RawDataModel {
  id: string;
  title: string;
  metadata: ModelMetadata;
}

// 分类配置
const categories = [
  { key: '全部', label: '全部' },
  { key: '综合', label: '综合' },
  { key: '编程', label: '编程' },
  { key: '数学', label: '数学' },
  { key: '视觉', label: '视觉' },
  { key: '中英文', label: '中英文' },
];

// 公司域名映射（用于获取公司 logo）
const companyDomains: Record<string, string> = {
  'openai': 'openai.com',
  'google': 'google.com',
  'anthropic': 'anthropic.com',
  'meta': 'meta.com',
  'deepseek': 'deepseek.com',
  'mistral': 'mistral.ai',
  'xai': 'x.ai',
  'amazon': 'amazon.com',
  'alibaba': 'alibaba.com',
  'tencent': 'tencent.com',
  'xiaomi': 'xiaomi.com',
  'microsoft': 'microsoft.com',
  'zai': 'zhipuai.cn',
  'nvidia': 'nvidia.com',
  'cohere': 'cohere.ai',
  'moonshot': 'moonshot.cn',
  'stepfun': 'stepfun.com',
  'ibm': 'ibm.com',
  'baidu': 'baidu.com',
  'minimax': 'minimax.io',
  'meituan': 'meituan.com',
  'ant-group': 'antgroup.com',
  'byteDance': 'bytedance.com',
  'huawei': 'huawei.com',
  'oppo': 'oppo.com',
  'vivo': 'vivo.com',
};

// 模型名关键词到公司域名的映射（优先匹配模型名获取对应公司 logo）
const modelToCompany: Record<string, string> = {
  'claude': 'anthropic.com',
  'gpt': 'openai.com',
  'chatgpt': 'openai.com',
  'o1': 'openai.com',
  'o3': 'openai.com',
  'gemini': 'google.com',
  'llama': 'meta.com',
  'deepseek': 'deepseek.com',
  'mistral': 'mistral.ai',
  'grok': 'x.ai',
  'qwen': 'alibaba.com',
  'yi': '01.ai',
  'glm': 'chatglm.cn',
  'ernie': 'baidu.com',
  'command': 'cohere.ai',
  'moonshot': 'moonshot.cn',
  'stepfun': 'stepfun.com',
  'minimax': 'minimax.io',
  'step': 'stepfun.com',
  'muse': 'meta.com',
};

// Google Favicon 服务获取公司 logo
function getCompanyLogoUrl(modelName?: string, organization?: string): string | null {
  // 1. 优先根据模型名关键词获取对应公司 logo
  if (modelName) {
    const lower = modelName.toLowerCase();
    for (const [keyword, domain] of Object.entries(modelToCompany)) {
      if (lower.includes(keyword)) {
        return `https://www.google.com/s2/favicons?domain=${domain}&sz=64`;
      }
    }
  }

  // 2. 其次使用公司域名获取 logo
  if (organization) {
    const domain = companyDomains[organization.toLowerCase()];
    if (domain) {
      return `https://www.google.com/s2/favicons?domain=${domain}&sz=64`;
    }
  }

  return null;
}

// 获取公司首字母作为备选图标
function getCompanyInitial(organization?: string): string {
  if (!organization) return '?';
  return organization.charAt(0).toUpperCase();
}

// Logo 组件：使用公司 logo（优先模型对应公司，其次使用组织名）
function ModelLogo({ modelName, organization, size = 'normal' }: { modelName?: string; organization?: string; size?: 'small' | 'normal' | 'large' }) {
  const logoUrl = getCompanyLogoUrl(modelName, organization);
  const initial = getCompanyInitial(organization);

  const sizeClasses = {
    small: 'w-8 h-8 text-xs',
    normal: 'w-10 h-10 text-sm',
    large: 'w-14 h-14 text-lg',
  };

  if (logoUrl) {
    return (
      <img
        src={logoUrl}
        alt={organization || 'logo'}
        className={`${sizeClasses[size]} rounded-lg object-cover bg-white border border-[var(--border)]`}
        onError={(e) => {
          const target = e.target as HTMLImageElement;
          target.style.display = 'none';
          const fallback = target.nextElementSibling as HTMLElement;
          if (fallback) fallback.style.display = 'flex';
        }}
      />
    );
  }

  return (
    <div
      className={`${sizeClasses[size]} rounded-lg bg-[var(--background)] border border-[var(--border)] flex items-center justify-center font-bold text-[var(--text-muted)]`}
      style={{ display: 'flex' }}
    >
      {initial}
    </div>
  );
}

export default function RankingPage() {
  const [activeCategory, setActiveCategory] = useState('全部');
  const [searchQuery, setSearchQuery] = useState('');
  const [models, setModels] = useState<RawDataModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [displayCount, setDisplayCount] = useState(50); // 默认显示50条
  const [loadingMore, setLoadingMore] = useState(false);

  // 分页获取数据
  const fetchModels = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const supabase = createSupabaseClient();

      // 按 metadata.created_at 降序获取所有数据
      const { data, error: fetchError } = await supabase
        .from('raw_data')
        .select('id, title, metadata')
        .eq('source', 'lm_arena')
        .eq('data_type', 'model')
        .order('created_at', { ascending: false });

      if (fetchError) {
        throw fetchError;
      }

      // 前端排序：按 elo_rating 降序
      const sortedData = (data || []).sort((a, b) => {
        const eloA = a.metadata?.elo_rating || 0;
        const eloB = b.metadata?.elo_rating || 0;
        return eloB - eloA;
      });

      // 去重：保留每个模型的最高 ELO 记录
      const uniqueMap = new Map<string, typeof sortedData[0]>();
      for (const item of sortedData) {
        const key = item.title;
        if (!uniqueMap.has(key)) {
          uniqueMap.set(key, item);
        }
      }
      const uniqueData = Array.from(uniqueMap.values());

      setModels(uniqueData);
      setDisplayCount(50); // 重置显示数量
    } catch (err) {
      console.error('Fetch models error:', err);
      setError('获取数据失败');
      // 降级到模拟数据
      setModels(getMockModels());
    } finally {
      setLoading(false);
    }
  }, []);

  // 加载更多
  const loadMore = useCallback(() => {
    if (loadingMore) return;
    setLoadingMore(true);
    // 模拟加载延迟
    setTimeout(() => {
      setDisplayCount((prev) => prev + 50);
      setLoadingMore(false);
    }, 300);
  }, [loadingMore]);

  // 监听滚动实现无限滚动
  useEffect(() => {
    const handleScroll = () => {
      const scrollTop = window.scrollY;
      const windowHeight = window.innerHeight;
      const docHeight = document.documentElement.scrollHeight;

      // 滚动到底部附近时加载更多
      if (scrollTop + windowHeight >= docHeight - 200) {
        if (displayCount < models.length && !loadingMore && !loading) {
          loadMore();
        }
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [displayCount, models.length, loadingMore, loading, loadMore]);

  useEffect(() => {
    fetchModels();
  }, [fetchModels]);
  const filteredModels = models.filter((model) => {
    // 分类过滤
    if (activeCategory !== '全部') {
      const modelCategory = model.metadata?.category;
      if (modelCategory !== activeCategory) {
        return false;
      }
    }

    // 搜索过滤
    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      return model.title.toLowerCase().includes(query);
    }

    return true;
  });

  // 显示的数据（根据 displayCount 限制）
  const displayedModels = filteredModels.slice(0, displayCount);

  // 获取前3名
  const top3 = displayedModels.slice(0, 3);
  const restList = displayedModels.slice(3);

  // 获取模型排名（基于过滤后的索引）
  const getRank = (index: number, isTop3: boolean) => {
    return isTop3 ? index + 1 : index + 4;
  };

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
          <span>🏆</span>
          <span>AI 模型榜单</span>
        </h1>
        <p className="text-xs text-[var(--text-muted)] hidden md:block">LMArena 客观评测 · 实时更新</p>
      </div>

      {/* 搜索栏 */}
      <div className="px-4 md:px-5 py-3 border-b border-[var(--border)]">
        <div className="relative">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="搜索模型..."
            className="w-full px-4 py-2.5 pl-10 bg-white border border-[var(--border)] rounded-xl text-sm focus:outline-none focus:border-[var(--primary)] focus:ring-2 focus:ring-[var(--primary)]/10 transition-all"
          />
          <svg
            className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[var(--text-muted)]"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
      </div>

      {/* 分类筛选 */}
      <div className="px-4 md:px-5 py-3 border-b border-[var(--border)] overflow-x-auto">
        <div className="flex gap-2">
          {categories.map((cat) => (
            <button
              key={cat.key}
              onClick={() => setActiveCategory(cat.key)}
              className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all shrink-0 ${
                activeCategory === cat.key
                  ? 'bg-[var(--foreground)] text-white'
                  : 'bg-white border border-[var(--border)] text-[var(--text-secondary)] hover:border-[var(--foreground)]'
              }`}
            >
              {cat.label}
            </button>
          ))}
        </div>
      </div>

      {/* TOP 3 冠军卡片 */}
      {loading ? (
        <div className="p-8 flex items-center justify-center">
          <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : error ? (
        <div className="p-8 text-center text-red-500">{error}</div>
      ) : top3.length > 0 ? (
        <div className="p-4 md:p-5 border-b border-[var(--border)]">
          <div className="grid grid-cols-3 gap-2 md:gap-4">
            {top3.map((model, idx) => (
              <Link
                key={model.id}
                href={`/web/model/${model.id}`}
                className={`relative p-3 md:p-4 rounded-2xl border transition-all ${
                  idx === 0
                    ? 'bg-gradient-to-br from-amber-50 to-orange-50 border-amber-200 hover:shadow-lg cursor-pointer'
                    : idx === 1
                    ? 'bg-gradient-to-br from-gray-50 to-slate-50 border-gray-200 hover:shadow-lg cursor-pointer'
                    : 'bg-gradient-to-br from-amber-50 to-yellow-50 border-amber-100 hover:shadow-lg cursor-pointer'
                }`}
              >
                {/* 排名标签 */}
                <div className={`absolute -top-2 -right-2 w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${
                  idx === 0
                    ? 'bg-amber-500 text-white'
                    : idx === 1
                    ? 'bg-gray-400 text-white'
                    : 'bg-amber-600 text-white'
                }`}>
                  {getRank(idx, true)}
                </div>

                {/* Logo */}
                <div className="mb-2">
                  <ModelLogo modelName={model.title} organization={model.metadata?.organization} size="large" />
                </div>

                {/* 名称 */}
                <h3 className="font-bold text-[var(--foreground)] text-xs md:text-sm leading-tight line-clamp-2">
                  {model.title}
                </h3>

                {/* ELO 分数 */}
                <div className="mt-2 flex items-baseline gap-1">
                  <span className={`text-lg md:text-2xl font-bold ${
                    idx === 0 ? 'text-amber-600' : 'text-[var(--foreground)]'
                  }`}>
                    {Math.round(model.metadata?.elo_rating || 0)}
                  </span>
                  <span className="text-xs text-[var(--text-muted)]">ELO</span>
                </div>

                {/* 投票数 */}
                <p className="text-xs text-[var(--text-muted)] mt-1">
                  {model.metadata?.vote_count || 0} 票
                </p>
              </Link>
            ))}
          </div>
        </div>
      ) : (
        <div className="p-8 text-center text-[var(--text-muted)]">暂无数据</div>
      )}

      {/* 完整榜单 */}
      <div className="divide-y divide-[var(--border)]">
        {loading ? (
          <div className="p-8 text-center text-[var(--text-muted)]">加载中...</div>
        ) : restList.length === 0 ? (
          <div className="p-8 text-center text-[var(--text-muted)]">
            {searchQuery ? '未找到匹配的模型' : '暂无数据'}
          </div>
        ) : (
          restList.map((model, idx) => (
            <Link
              key={model.id}
              href={`/web/model/${model.id}`}
              className="px-4 md:px-5 py-3 md:py-4 hover:bg-[var(--background)] transition-colors flex items-center gap-3 cursor-pointer block"
            >
              {/* 排名 */}
              <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm shrink-0 ${
                getRank(idx, false) <= 5 ? 'bg-[var(--primary-light)] text-[var(--primary)]' : 'bg-[var(--background)] text-[var(--text-muted)]'
              }`}>
                {getRank(idx, false)}
              </div>

              {/* Logo */}
              <ModelLogo modelName={model.title} organization={model.metadata?.organization} size="small" />

              {/* 信息 */}
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold text-[var(--foreground)] text-sm line-clamp-1">
                  {model.title}
                </h3>
                <div className="flex items-center gap-2 mt-0.5">
                  <span className="px-1.5 py-0.5 bg-[var(--background)] text-[var(--text-muted)] text-xs rounded">
                    {model.metadata?.category || '综合'}
                  </span>
                  <span className="text-xs text-[var(--text-muted)]">
                    {model.metadata?.vote_count || 0} 票
                  </span>
                </div>
              </div>

              {/* ELO 分数 */}
              <div className="text-right shrink-0">
                <div className="text-lg font-bold text-[var(--foreground)]">
                  {Math.round(model.metadata?.elo_rating || 0)}
                </div>
                <div className="text-xs text-[var(--text-muted)]">ELO</div>
              </div>
            </Link>
          ))
        )}
      </div>

      {/* 加载更多按钮/状态 */}
      {!loading && !loadingMore && filteredModels.length > displayCount && (
        <div className="p-4 text-center">
          <button
            onClick={loadMore}
            className="px-6 py-2 bg-[var(--background)] border border-[var(--border)] rounded-full text-sm text-[var(--text-secondary)] hover:border-[var(--foreground)] transition-colors"
          >
            加载更多 ({displayCount}/{filteredModels.length})
          </button>
        </div>
      )}

      {/* 加载中状态 */}
      {!loading && loadingMore && (
        <div className="p-4 flex items-center justify-center gap-2 text-sm text-[var(--text-muted)]">
          <div className="w-4 h-4 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
          加载中...
        </div>
      )}

      {/* 已加载全部 */}
      {!loading && !loadingMore && displayCount >= filteredModels.length && filteredModels.length > 50 && (
        <div className="p-4 text-center text-xs text-[var(--text-muted)]">
          已加载全部 {filteredModels.length} 个模型
        </div>
      )}

      {/* 数据来源说明 */}
      <div className="p-6 md:p-8 text-center text-xs text-[var(--text-muted)]">
        <p>数据来源：LMArena</p>
        <button
          onClick={fetchModels}
          className="mt-2 text-[var(--primary)] hover:underline"
        >
          刷新数据
        </button>
      </div>
    </div>
  );
}

// 模拟数据（用于开发/降级）
function getMockModels(): RawDataModel[] {
  return [
    { id: '1', title: 'Claude 3.5 Sonnet', metadata: { elo_rating: 1332, vote_count: 24567, category: '综合' } },
    { id: '2', title: 'GPT-4 Turbo', metadata: { elo_rating: 1315, vote_count: 31234, category: '综合' } },
    { id: '3', title: 'Gemini 1.5 Pro', metadata: { elo_rating: 1298, vote_count: 18765, category: '综合' } },
    { id: '4', title: 'Llama 3.1 405B', metadata: { elo_rating: 1275, vote_count: 15678, category: '开源' } },
    { id: '5', title: 'Qwen 2.5 72B', metadata: { elo_rating: 1268, vote_count: 12345, category: '开源' } },
    { id: '6', title: 'GPT-4o', metadata: { elo_rating: 1289, vote_count: 28976, category: '综合' } },
    { id: '7', title: 'Claude 3 Opus', metadata: { elo_rating: 1267, vote_count: 9876, category: '综合' } },
    { id: '8', title: 'Mistral Large 2', metadata: { elo_rating: 1245, vote_count: 7654, category: '综合' } },
    { id: '9', title: 'Deepseek V2.5', metadata: { elo_rating: 1234, vote_count: 5432, category: '开源' } },
    { id: '10', title: 'Command R+', metadata: { elo_rating: 1212, vote_count: 4567, category: '中英文' } },
    { id: '11', title: 'Yi-Large', metadata: { elo_rating: 1205, vote_count: 3456, category: '中英文' } },
    { id: '12', title: 'GLM-4', metadata: { elo_rating: 1198, vote_count: 2345, category: '中英文' } },
    { id: '13', title: 'CodeLlama 70B', metadata: { elo_rating: 1189, vote_count: 6789, category: '编程' } },
    { id: '14', title: 'WizardCoder 33B', metadata: { elo_rating: 1176, vote_count: 4567, category: '编程' } },
    { id: '15', title: 'Gemini 1.5 Flash', metadata: { elo_rating: 1245, vote_count: 8901, category: '综合' } },
    { id: '16', title: 'Qwen 2.5 Coder 32B', metadata: { elo_rating: 1168, vote_count: 3456, category: '编程' } },
    { id: '17', title: 'InternLM2.5 20B', metadata: { elo_rating: 1156, vote_count: 2345, category: '数学' } },
    { id: '18', title: 'Mathstral 7B', metadata: { elo_rating: 1148, vote_count: 1234, category: '数学' } },
    { id: '19', title: 'LLaVA 1.6 34B', metadata: { elo_rating: 1234, vote_count: 5678, category: '视觉' } },
    { id: '20', title: 'Qwen-VL 72B', metadata: { elo_rating: 1225, vote_count: 4567, category: '视觉' } },
  ];
}
