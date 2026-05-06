/**
 * 审计日志 Store - 管理操作日志
 */
import { create } from 'zustand';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';
const supabase = createClient(supabaseUrl, supabaseKey);

export type AuditAction =
  | 'auth.login' | 'auth.logout' | 'auth.register' | 'auth.oauth'
  | 'content.create' | 'content.read' | 'content.update' | 'content.delete'
  | 'review.create' | 'review.update' | 'review.delete' | 'review.publish'
  | 'favorite.add' | 'favorite.remove' | 'like.add' | 'like.remove'
  | 'feedback.review' | 'feedback.resolve' | 'feedback.archive'
  | 'settings.update' | 'settings.reset'
  | 'api.access' | 'export.data' | 'import.data';

export type AuditResult = 'success' | 'failure' | 'partial';

export interface AuditLog {
  id: string;
  user_id: string | null;
  user_email: string | null;
  user_ip: string | null;
  user_agent: string | null;
  action: AuditAction;
  target_type: string | null;
  target_id: string | null;
  detail: Record<string, unknown> | null;
  result: AuditResult;
  request_method: string | null;
  request_path: string | null;
  request_params: Record<string, unknown> | null;
  response_code: number | null;
  created_at: string;
}

export interface AuditLogFilter {
  userId?: string;
  action?: AuditAction;
  targetType?: string;
  targetId?: string;
  result?: AuditResult;
  startDate?: string;
  endDate?: string;
  limit?: number;
  offset?: number;
}

interface AuditLogState {
  logs: AuditLog[];
  isLoading: boolean;
  error: string | null;
  totalCount: number;
}

interface AuditLogStore extends AuditLogState {
  fetchLogs: (filter?: AuditLogFilter) => Promise<void>;
  createLog: (log: Omit<AuditLog, 'id' | 'created_at'>) => Promise<boolean>;
  clear: () => void;
}

export const useAuditLogStore = create<AuditLogStore>((set) => ({
  logs: [],
  isLoading: false,
  error: null,
  totalCount: 0,

  fetchLogs: async (filter?: AuditLogFilter) => {
    set({ isLoading: true, error: null });
    try {
      let query = supabase
        .from('audit_logs')
        .select('*', { count: 'exact' })
        .order('created_at', { ascending: false });

      if (filter?.userId) {
        query = query.eq('user_id', filter.userId);
      }
      if (filter?.action) {
        query = query.eq('action', filter.action);
      }
      if (filter?.targetType) {
        query = query.eq('target_type', filter.targetType);
      }
      if (filter?.targetId) {
        query = query.eq('target_id', filter.targetId);
      }
      if (filter?.result) {
        query = query.eq('result', filter.result);
      }
      if (filter?.startDate) {
        query = query.gte('created_at', filter.startDate);
      }
      if (filter?.endDate) {
        query = query.lte('created_at', filter.endDate);
      }

      const limit = filter?.limit || 50;
      const offset = filter?.offset || 0;
      query = query.range(offset, offset + limit - 1);

      const { data, error, count } = await query;

      if (error) throw error;

      set({
        logs: (data as AuditLog[]) || [],
        totalCount: count || 0,
        isLoading: false
      });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to fetch logs',
        isLoading: false
      });
    }
  },

  createLog: async (logData) => {
    try {
      const { error } = await supabase
        .from('audit_logs')
        .insert([logData]);

      if (error) {
        console.error('创建日志失败:', error.message);
        return false;
      }
      return true;
    } catch (err) {
      console.error('创建日志出错:', err);
      return false;
    }
  },

  clear: () => {
    set({ logs: [], isLoading: false, error: null, totalCount: 0 });
  }
}));

// 便捷函数：记录操作
export async function logAction(
  action: AuditAction,
  targetType?: string,
  targetId?: string,
  detail?: Record<string, unknown>
): Promise<boolean> {
  const store = useAuditLogStore.getState();
  return store.createLog({
    user_id: null, // 需要从 authStore 获取
    user_email: null,
    user_ip: null,
    user_agent: typeof window !== 'undefined' ? window.navigator.userAgent : null,
    action,
    target_type: targetType || null,
    target_id: targetId || null,
    detail: detail || null,
    result: 'success',
    request_method: typeof window !== 'undefined' ? 'GET' : null,
    request_path: typeof window !== 'undefined' ? window.location.pathname : null,
    request_params: null,
    response_code: 200
  });
}