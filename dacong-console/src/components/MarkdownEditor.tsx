'use client';

/**
 * MarkdownEditor - Markdown 编辑器组件
 * 基于 @uiw/react-md-editor，提供实时预览和代码高亮
 */
import { useState, useEffect } from 'react';
import '@uiw/react-md-editor/markdown-editor.css';

// 定义 MDEditor 组件的类型
interface MDEditorComponent {
  value: string;
  onChange?: (val: string | undefined) => void;
  height?: number;
  preview?: 'edit' | 'preview' | 'live';
  textareaProps?: { placeholder?: string };
  toolbarBottom?: boolean;
  className?: string;
  [key: string]: unknown;
}

interface MarkdownEditorProps {
  value: string;
  onChange?: (value: string) => void;
  placeholder?: string;
  minHeight?: number;
  disabled?: boolean;
  className?: string;
}

export function MarkdownEditor({
  value,
  onChange,
  placeholder = '在此输入 Markdown 内容...',
  minHeight = 400,
  disabled = false,
  className,
}: MarkdownEditorProps) {
  // 动态导入以避免 SSR 问题
  const [MDEditor, setMDEditor] = useState<typeof import('@uiw/react-md-editor').default | null>(null);
  const [isPreviewOnly, setIsPreviewOnly] = useState(false);

  useEffect(() => {
    import('@uiw/react-md-editor').then((mod) => {
      setMDEditor(() => mod.default);
    });
  }, []);

  if (!MDEditor) {
    return (
      <div
        className={`border border-[var(--border)] rounded-xl bg-white dark:bg-[var(--background-secondary)] flex items-center justify-center`}
        style={{ minHeight }}
      >
        <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className={className}>
      <div
        className={`markdown-editor-wrapper ${
          disabled ? 'opacity-60 pointer-events-none' : ''
        }`}
      >
        <MDEditor
          value={value}
          onChange={(val) => onChange?.(val || '')}
          height={minHeight}
          preview={isPreviewOnly ? 'preview' : 'live'}
          textareaProps={{
            placeholder,
          }}
          toolbarBottom={false}
          className={
            '!bg-white dark:!bg-[var(--background-secondary)] ' +
            'border border-[var(--border)] rounded-xl overflow-hidden ' +
            '[&_.w-md-editor-toolbar]:!bg-[var(--background)] ' +
            '[&_.w-md-editor-text-input]:!min-h-[300px] ' +
            '[&_.wmde-markdown]:!bg-white dark:[&_.wmde-markdown]:!bg-[var(--background-secondary)]'
          }
        />
      </div>
      <div className="mt-2 flex items-center gap-4 text-xs text-[var(--text-muted)]">
        <span>支持 Markdown 语法</span>
        <button
          type="button"
          onClick={() => setIsPreviewOnly(!isPreviewOnly)}
          className="hover:text-[var(--primary)] transition-colors"
        >
          {isPreviewOnly ? '显示编辑器' : '仅预览'}
        </button>
      </div>
    </div>
  );
}
