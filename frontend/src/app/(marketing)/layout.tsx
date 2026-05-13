import AmbientBackground from "@/components/layout/AmbientBackground";
import PageTransition from "@/components/layout/PageTransition";

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <PageTransition>
      <div className="relative min-h-screen">
        <AmbientBackground />
        {children}
      </div>
    </PageTransition>
  );
}
