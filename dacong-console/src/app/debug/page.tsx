'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { createSupabaseClient } from '@/utils/supabase/client';

// Error boundary component
class ErrorBoundary extends React.Component<
  { children: React.ReactNode; fallback: React.ReactNode },
  { hasError: boolean; error: Error | null }
> {
  constructor(props: any) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}

export default function DebugPage() {
  const [posts, setPosts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [debug, setDebug] = useState<string[]>([]);
  const [clientReady, setClientReady] = useState(false);

  const addDebug = useCallback((msg: string) => {
    const timestamp = new Date().toISOString().split('T')[1].slice(0, 8);
    setDebug(prev => [...prev, `[${timestamp}] ${msg}`]);
    console.log('[Debug]', msg);
  }, []);

  useEffect(() => {
    addDebug('useEffect fired');
    setClientReady(true);

    async function fetch() {
      try {
        addDebug('Creating client...');
        const supabase = createSupabaseClient();
        addDebug('Client created');

        addDebug('Getting session...');
        const { data: sessionData } = await supabase.auth.getSession();
        addDebug('Session: ' + (sessionData?.session ? 'has session' : 'no session'));

        addDebug('Querying posts...');
        const result = await supabase
          .from('posts')
          .select('id, title, status, created_at')
          .eq('status', 'approved')
          .limit(5);

        addDebug('Got result - status: ' + result.status);
        addDebug('Error: ' + (result.error ? result.error.message : 'none'));
        addDebug('Data length: ' + (result.data?.length || 0));

        if (result.data) {
          setPosts(result.data);
        }
        if (result.error) {
          setError(result.error.message);
        }
      } catch (e: any) {
        addDebug('CATCH ERROR: ' + e.message);
        setError(e.message);
      } finally {
        setLoading(false);
      }
    }

    fetch();
  }, [addDebug]);

  return (
    <ErrorBoundary
      fallback={
        <div className="p-8 text-red-600">
          <h1>Error in Debug Page</h1>
          <p>Check console for error details</p>
        </div>
      }
    >
      <div className="p-8">
        <h1>Debug Page</h1>
        <p>Loading: {loading ? 'yes' : 'no'}</p>
        <p>Error: {error || 'none'}</p>
        <p>Posts count: {posts.length}</p>
        <p>Client ready: {clientReady ? 'yes' : 'no'}</p>

        {posts.length > 0 && (
          <>
            <h2>Posts:</h2>
            <pre style={{ maxHeight: 300, overflow: 'auto' }}>
              {JSON.stringify(posts, null, 2)}
            </pre>
          </>
        )}

        <hr />
        <h2>Debug Log ({debug.length} entries):</h2>
        <pre style={{
          whiteSpace: 'pre-wrap',
          fontSize: 11,
          background: '#f5f5f5',
          padding: 10,
          maxHeight: 500,
          overflow: 'auto'
        }}>
          {debug.length === 0 ? '(no debug entries yet)' : debug.join('\n')}
        </pre>
      </div>
    </ErrorBoundary>
  );
}
