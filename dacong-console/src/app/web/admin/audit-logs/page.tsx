'use client';

/**
 * 审计日志管理页面 - 管理后台查看操作日志
 */
import { useEffect, useState } from 'react';
import { useAuditLogStore, AuditLog, AuditAction, AuditResult } from '@/stores/auditLogStore';
import { useAuthStore } from '@/stores/authStore';

// 操作类型映射
const ACTION_LABELS: Record<string, string> = {
  'auth.login': '用户登录',
  'auth.logout': '用户登出',
  'auth.register': '用户注册',
  'auth.oauth': 'OAuth登录',
  'content.create': '创建内容',
  'content.read': '查看内容',
  'content.update': '更新内容',
  'content.delete': '删除内容',
  'review.create': '创建评测',
  'review.update': '更新评测',
  'review.delete': '删除评测',
  'review.publish': '发布评测',
  'favorite.add': '添加收藏',
  'favorite.remove': '移除收藏',
  'like.add': '添加点赞',
  'like.remove': '移除点赞',
  'feedback.review': '查看反馈',
  'feedback.resolve': '处理反馈',
  'feedback.archive': '归档反馈',
  'settings.update': '更新设置',
  'settings.reset': '重置设置',
  'api.access': 'API访问',
  'export.data': '导出数据',
  'import.data': '导入数据'
};

const RESULT_STYLES: Record<AuditResult, string> = {
  success: 'bg-green-100 text-green-800',
  failure: 'bg-red-100 text-red-800',
  partial: 'bg-yellow-100 text-yellow-800'
};

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
}

export default function AuditLogsPage() {
  const { user } = useAuthStore();
  const { logs, isLoading, error, totalCount, fetchLogs } = useAuditLogStore();
  const [filters, setFilters] = useState({
    action: '',
    targetType: '',
    result: '',
    startDate: '',
    endDate: ''
  });
  const [page, setPage] = useState(0);
  const pageSize = 20;

  useEffect(() => {
    // TODO: 检查用户是否是管理员
    // if (user?.role !== 'admin') return;
    loadLogs();
  }, [page, filters]);

  async function loadLogs() {
    await fetchLogs({
      action: filters.action as AuditAction || undefined,
      targetType: filters.targetType || undefined,
      result: filters.result as AuditResult || undefined,
      startDate: filters.startDate || undefined,
      endDate: filters.endDate || undefined,
      limit: pageSize,
      offset: page * pageSize
    });
  }

  function handleFilterChange(key: string, value: string) {
    setFilters(prev => ({ ...prev, [key]: value }));
    setPage(0);
  }

  const totalPages = Math.ceil(totalCount / pageSize);

  return (
    <div className="max-w-7xl mx-auto p-6">
      {/* 页面标题 */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-[var(--foreground)]">审计日志</h1>
        <p className="text-[var(--text-muted)] mt-1">
          共 {totalCount} 条记录
        </p>
      </div>

      {/* 筛选器 */}
      <div className="bg-[var(--card-bg)] rounded-lg p-4 mb-6 border border-[var(--border)]">
        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <div>
            <label className="block text-sm font-medium text-[var(--text-secondary)] mb-1">
              操作类型
            </label>
            <select
              value={filters.action}
              onChange={(e) => handleFilterChange('action', e.target.value)}
              className="w-full px-3 py-2 rounded-md bg-[var(--background)] border border-[var(--border)] text-[var(--foreground)]"
            >
              <option value="">全部</option>
              {Object.entries(ACTION_LABELS).map(([value, label]) => (
                <option key={value} value={value}>{label}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-[var(--text-secondary)] mb-1">
              目标类型
            </label>
            <select
              value={filters.targetType}
              onChange={(e) => handleFilterChange('targetType', e.target.value)}
              className="w-full px-3 py-2 rounded-md bg-[var(--background)] border border-[var(--border)] text-[var(--foreground)]"
            >
              <option value="">全部</option>
              <option value="post">帖子</option>
              <option value="review">评测</option>
              <option value="user">用户</option>
              <option value="feedback">反馈</option>
              <option value="settings">设置</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-[var(--text-secondary)] mb-1">
              结果
            </label>
            <select
              value={filters.result}
              onChange={(e) => handleFilterChange('result', e.target.value)}
              className="w-full px-3 py-2 rounded-md bg-[var(--background)] border border-[var(--border)] text-[var(--foreground)]"
            >
              <option value="">全部</option>
              <option value="success">成功</option>
              <option value="failure">失败</option>
              <option value="partial">部分成功</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-[var(--text-secondary)] mb-1">
              开始日期
            </label>
            <input
              type="date"
              value={filters.startDate}
              onChange={(e) => handleFilterChange('startDate', e.target.value)}
              className="w-full px-3 py-2 rounded-md bg-[var(--background)] border border-[var(--border)] text-[var(--foreground)]"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-[var(--text-secondary)] mb-1">
              结束日期
            </label>
            <input
              type="date"
              value={filters.endDate}
              onChange={(e) => handleFilterChange('endDate', e.target.value)}
              className="w-full px-3 py-2 rounded-md bg-[var(--background)] border border-[var(--border)] text-[var(--foreground)]"
            />
          </div>
        </div>
      </div>

      {/* 日志列表 */}
      {isLoading ? (
        <div className="text-center py-12 text-[var(--text-muted)]">
          加载中...
        </div>
      ) : error ? (
        <div className="bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 p-4 rounded-lg">
          {error}
        </div>
      ) : logs.length === 0 ? (
        <div className="text-center py-12 text-[var(--text-muted)]">
          暂无日志记录
        </div>
      ) : (
        <>
          <div className="bg-[var(--card-bg)] rounded-lg border border-[var(--border)] overflow-hidden">
            <table className="w-full">
              <thead className="bg-[var(--background)]">
                <tr>
                  <th className="px-4 py-3 text-left text-sm font-medium text-[var(--text-secondary)]">时间</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-[var(--text-secondary)]">操作</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-[var(--text-secondary)]">目标</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-[var(--text-secondary)]">用户</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-[var(--text-secondary)]">结果</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-[var(--text-secondary)]">详情</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[var(--border)]">
                {logs.map((log) => (
                  <tr key={log.id} className="hover:bg-[var(--background)]/50">
                    <td className="px-4 py-3 text-sm text-[var(--text-secondary)]">
                      {formatDate(log.created_at)}
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-sm font-medium text-[var(--foreground)]">
                        {ACTION_LABELS[log.action] || log.action}
                      </span>
                      <div className="text-xs text-[var(--text-muted)]">{log.action}</div>
                    </td>
                    <td className="px-4 py-3 text-sm text-[var(--foreground)]">
                      {log.target_type && (
                        <span className="inline-block px-2 py-1 rounded bg-[var(--primary-light)] text-[var(--primary)] mr-1">
                          {log.target_type}
                        </span>
                      )}
                      {log.target_id && (
                        <span className="text-[var(--text-muted)]">#{log.target_id.slice(0, 8)}</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm text-[var(--foreground)]">
                      {log.user_email || log.user_id?.slice(0, 8) || '匿名'}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-1 rounded text-xs font-medium ${RESULT_STYLES[log.result]}`}>
                        {log.result === 'success' ? '成功' : log.result === 'failure' ? '失败' : '部分'}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm">
                      {log.detail && (
                        <button
                          onClick={() => alert(JSON.stringify(log.detail, null, 2))}
                          className="text-[var(--primary)] hover:underline"
                        >
                          查看
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* 分页 */}
          {totalPages > 1 && (
            <div className="flex justify-center items-center gap-2 mt-6">
              <button
                onClick={() => setPage(p => Math.max(0, p - 1))}
                disabled={page === 0}
                className="px-3 py-1 rounded bg-[var(--card-bg)] border border-[var(--border)] disabled:opacity-50"
              >
                上一页
              </button>
              <span className="text-sm text-[var(--text-secondary)]">
                第 {page + 1} / {totalPages} 页
              </span>
              <button
                onClick={() => setPage(p => Math.min(totalPages - 1, p + 1))}
                disabled={page >= totalPages - 1}
                className="px-3 py-1 rounded bg-[var(--card-bg)] border border-[var(--border)] disabled:opacity-50"
              >
                下一页
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}