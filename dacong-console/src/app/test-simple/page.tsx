'use client';

import { useState, useEffect } from 'react';

// 超级简单的测试 - 验证 useEffect 是否工作
export default function TestPage() {
  const [count, setCount] = useState(0);

  // 这个 useEffect 应该立即执行
  useEffect(() => {
    console.log('✅ useEffect executed - React is working!');
    console.log('✅ Page mounted successfully!');

    // 测试 setInterval - 每秒更新
    const interval = setInterval(() => {
      setCount(c => c + 1);
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  // 同时测试点击事件
  function handleClick() {
    console.log('✅ Click handler works!');
  }

  return (
    <div style={{ padding: 20, fontFamily: 'monospace' }}>
      <h1>React Test</h1>
      <p>If you see this: Component renders</p>
      <p>If console shows "useEffect executed": React works!</p>
      <p>Counter: {count} (should increment every second)</p>
      <button onClick={handleClick}>Test Click</button>
    </div>
  );
}