import { ShowcaseDetail } from '@/components/works/Showcases';
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  return <ShowcaseDetail id={id} />;
}
