import AmbientBackground from "@/components/layout/AmbientBackground";
import PageTransition from "@/components/layout/PageTransition";
import Sidebar from "@/components/layout/Sidebar";

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <PageTransition>
      <div className="relative min-h-screen bg-aura-black text-white">
        <AmbientBackground />
        <div className="mx-auto flex max-w-7xl gap-6 px-6 pb-12 pt-10">
          <Sidebar />
          <main className="flex-1 space-y-10">{children}</main>
        </div>
      </div>
    </PageTransition>
  );
}
