export default function Loading() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="glass-card flex items-center gap-3 px-8 py-6 text-sm text-white/70">
        <div className="h-3 w-3 animate-pulse rounded-full bg-aura-accent" />
        Syncing your AI dashboard...
      </div>
    </div>
  );
}
