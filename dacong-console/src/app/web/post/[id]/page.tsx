import PostDetailClient from './PostDetailClient';

export const dynamic = 'force-static';

export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

export default function PostDetailPage() {
  return <PostDetailClient />;
}