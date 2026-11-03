// @vitest-environment jsdom
import React from 'react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { ShowcaseFeed, ShowcaseForm } from './Showcases';

const mock = vi.hoisted(() => ({ getUser: vi.fn(), from: vi.fn(), push: vi.fn() }));
vi.mock('@/utils/supabase/client', () => ({ createSupabaseClient: () => ({ auth: { getUser: mock.getUser }, from: mock.from }) }));
vi.mock('next/navigation', () => ({ useRouter: () => ({ push: mock.push }) }));
afterEach(() => { cleanup(); vi.resetAllMocks(); });
function fill() {
  fireEvent.change(screen.getByLabelText('标题'), { target: { value: 'AI 小作品' } });
  fireEvent.change(screen.getByLabelText('一句话介绍'), { target: { value: '帮助写作' } });
  fireEvent.change(screen.getByLabelText('体验地址（必填）'), { target: { value: 'https://example.com' } });
  fireEvent.change(screen.getByLabelText('分享者昵称'), { target: { value: '测试分享者' } });
  fireEvent.click(screen.getByRole('button', { name: '发布分享' }));
}
describe('showcase publishing', () => {
  it('asks anonymous users to log in without writing content', async () => {
    mock.getUser.mockResolvedValue({ data: { user: null }, error: null });
    render(<ShowcaseForm />); fill();
    expect(await screen.findByRole('alert')).toBeTruthy();
    expect(mock.from).not.toHaveBeenCalled();
    expect(screen.getByLabelText('标题')).toHaveProperty('value', 'AI 小作品');
  });
  it('publishes with the authenticated owner and opens the new detail page', async () => {
    mock.getUser.mockResolvedValue({ data: { user: { id: 'owner' } }, error: null });
    const insert = vi.fn().mockReturnValue({ select: () => ({ single: async () => ({ data: { id: 'work-id' }, error: null }) }) });
    mock.from.mockReturnValue({ insert });
    render(<ShowcaseForm />); fill();
    await waitFor(() => expect(mock.push).toHaveBeenCalledWith('/web/works/work-id'));
    expect(insert).toHaveBeenCalledWith(expect.objectContaining({ user_id: 'owner', kind: 'work', demo_url: 'https://example.com/' }));
  });
  it('shows an invitation instead of fictitious works when the gallery is empty', async () => {
    const query = { select: vi.fn(), eq: vi.fn(), order: vi.fn(), range: vi.fn().mockResolvedValue({ data: [], error: null }) };
    query.select.mockReturnValue(query); query.eq.mockReturnValue(query); query.order.mockReturnValue(query); mock.from.mockReturnValue(query);
    render(<ShowcaseFeed />);
    expect(await screen.findByText('这里期待你的第一个分享')).toBeTruthy();
    expect(query.eq).toHaveBeenCalledWith('status', 'published');
  });
});
