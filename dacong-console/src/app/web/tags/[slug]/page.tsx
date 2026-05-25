import TagPageClient from './TagPageClient';

export const dynamic = 'force-static';

export async function generateStaticParams() {
  return [{ slug: '__placeholder__' }];
}

export default function TagPage() {
  return <TagPageClient />;
}