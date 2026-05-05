'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { createSupabaseClient } from '@/utils/supabase/client';

// raw_data 表的 metadata 结构
interface ModelMetadata {
  elo_rating?: number;
  vote_count?: number;
  category?: string;
  organization?: string;
  description?: string;
  url?: string;
  [key: string]: unknown;
}

// 模型数据类型
interface ModelData {
  id: string;
  title: string;
  metadata: ModelMetadata;
}

export default function ModelDetailPage() {
  const params = useParams();
  const modelId = params.id as string;
  const [model, setModel] = useState<ModelData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchModel() {
      if (!modelId) return;

      setLoading(true);
      setError(null);

      try {
        const supabase = createSupabaseClient();
        const { data, error: fetchError } = await supabase
          .from('raw_data')
          .select('id, title, metadata')
          .eq('id', modelId)
          .single();

        if (fetchError) {
          throw fetchError;
        }

        setModel(data);
      } catch (err) {
        console.error('Fetch model error:', err);
        setError('获取模型详情失败');
        // 降级到模拟数据
        setModel({
          id: modelId,
          title: decodeURIComponent(modelId),
          metadata: {
            elo_rating: 1250,
            vote_count: 1234,
            category: '综合',
            organization: 'Unknown',
            description: '这是模型 ' + modelId + ' 的描述信息',
          },
        });
      } finally {
        setLoading(false);
      }
    }

    fetchModel();
  }, [modelId]);

  // 返回按钮
  const handleBack = () => {
    window.history.back();
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (error || !model) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-4">
        <p className="text-red-500">{error || '模型不存在'}</p>
        <Link href="/web/ranking" className="text-[var(--primary)] hover:underline">
          返回榜单
        </Link>
      </div>
    );
  }

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <div className="flex items-center gap-3">
          <button
            onClick={handleBack}
            className="w-8 h-8 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-secondary)] hover:bg-[var(--primary-light)] hover:text-[var(--primary)] transition-all"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2 flex-1 min-w-0">
            <span>🏆</span>
            <span className="truncate">{model.title}</span>
          </h1>
        </div>
      </div>

      {/* 模型详情内容 */}
      <div className="p-4 md:p-5">
        {/* 主信息卡片 */}
        <div className="bg-white rounded-2xl p-5 md:p-6 border border-[var(--border)] shadow-sm">
          {/* 头部信息 */}
          <div className="flex items-start gap-4 mb-6">
            {/* Logo */}
            <div className="w-16 h-16 md:w-20 md:h-20 rounded-2xl bg-[var(--background)] border border-[var(--border)] flex items-center justify-center text-2xl md:text-3xl font-bold text-[var(--primary)]">
              {model.metadata?.organization?.charAt(0)?.toUpperCase() || '?'}
            </div>

            <div className="flex-1 min-w-0">
              <h2 className="text-xl md:text-2xl font-bold text-[var(--foreground)] mb-2">
                {model.title}
              </h2>
              <div className="flex flex-wrap items-center gap-2">
                {model.metadata?.category && (
                  <span className="px-2 py-1 bg-[var(--primary-light)] text-[var(--primary)] text-xs rounded-full font-medium">
                    {model.metadata.category}
                  </span>
                )}
                {model.metadata?.organization && (
                  <span className="px-2 py-1 bg-[var(--background)] text-[var(--text-secondary)] text-xs rounded-full">
                    {model.metadata.organization}
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* 核心指标 */}
          <div className="grid grid-cols-2 gap-4 mb-6">
            {/* ELO 评分 */}
            <div className="p-4 bg-gradient-to-br from-amber-50 to-orange-50 rounded-xl border border-amber-100">
              <p className="text-xs text-[var(--text-muted)] mb-1">ELO 评分</p>
              <p className="text-3xl font-bold text-amber-600">
                {Math.round(model.metadata?.elo_rating || 0)}
              </p>
            </div>

            {/* 投票数 */}
            <div className="p-4 bg-[var(--background)] rounded-xl border border-[var(--border)]">
              <p className="text-xs text-[var(--text-muted)] mb-1">得票数</p>
              <p className="text-3xl font-bold text-[var(--foreground)]">
                {model.metadata?.vote_count || 0}
              </p>
            </div>
          </div>

          {/* 描述 */}
          {model.metadata?.description && (
            <div className="mb-6">
              <h3 className="text-sm font-semibold text-[var(--foreground)] mb-2">模型简介</h3>
              <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
                {model.metadata.description}
              </p>
            </div>
          )}

          {/* 操作按钮 */}
          <div className="flex flex-col gap-3">
            {model.metadata?.url && (
              <a
                href={model.metadata.url}
                target="_blank"
                rel="noopener noreferrer"
                className="w-full py-3 bg-[var(--primary)] text-white rounded-xl text-center font-semibold hover:bg-[var(--primary-dark)] transition-all"
              >
                访问官网 →
              </a>
            )}
            <Link
              href="/web/ranking"
              className="w-full py-3 bg-[var(--background)] text-[var(--foreground)] border border-[var(--border)] rounded-xl text-center font-semibold hover:border-[var(--foreground)] transition-all"
            >
              返回榜单
            </Link>
          </div>
        </div>

        {/* 相关信息卡片 */}
        <div className="mt-4 p-4 bg-white rounded-2xl border border-[var(--border)] shadow-sm">
          <h3 className="text-sm font-semibold text-[var(--foreground)] mb-3">相关推荐</h3>
          <div className="space-y-3">
            <Link
              href="/web/forum"
              className="flex items-center gap-3 p-3 rounded-xl bg-[var(--background)] hover:bg-[var(--primary-light)] transition-colors"
            >
              <span className="text-2xl">✍️</span>
              <div>
                <p className="font-medium text-[var(--foreground)] text-sm">写评测</p>
                <p className="text-xs text-[var(--text-muted)]">分享你的使用体验</p>
              </div>
            </Link>
            <Link
              href="/web/ranking"
              className="flex items-center gap-3 p-3 rounded-xl bg-[var(--background)] hover:bg-[var(--primary-light)] transition-colors"
            >
              <span className="text-2xl">📊</span>
              <div>
                <p className="font-medium text-[var(--foreground)] text-sm">查看完整榜单</p>
                <p className="text-xs text-[var(--text-muted)]">对比更多模型</p>
              </div>
            </Link>
          </div>
        </div>

        {/* 数据来源 */}
        <div className="mt-6 text-center text-xs text-[var(--text-muted)]">
          <p>数据来源：LMArena · 更新于 {new Date().toLocaleDateString('zh-CN')}</p>
        </div>
      </div>
    </div>
  );
}