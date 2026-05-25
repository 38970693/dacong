import ReviewDetailClient from './ReviewDetailClient';

export const dynamic = 'force-static';

export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

export default function ReviewDetailPage() {
  return <ReviewDetailClient />;
}