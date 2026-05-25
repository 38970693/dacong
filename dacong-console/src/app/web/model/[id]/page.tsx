import ModelDetailClient from './ModelDetailClient';

export const dynamic = 'force-static';

export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

export default function ModelDetailPage() {
  return <ModelDetailClient />;
}