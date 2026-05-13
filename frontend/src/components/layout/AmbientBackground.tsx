export default function AmbientBackground() {
  return (
    <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
      <div className="absolute inset-0 grid-lines opacity-40" />
      <div className="absolute left-[10%] top-[15%] h-64 w-64 rounded-full bg-aura-accent/20 blur-[120px]" />
      <div className="absolute right-[8%] top-[10%] h-80 w-80 rounded-full bg-white/10 blur-[140px]" />
      <div className="absolute bottom-[5%] left-[20%] h-72 w-72 rounded-full bg-aura-accent-soft/20 blur-[160px]" />
      <div className="absolute inset-0">
        <div className="absolute left-[20%] top-[30%] h-2 w-2 rounded-full bg-white/40 blur-[1px] floating" />
        <div className="absolute left-[60%] top-[20%] h-1.5 w-1.5 rounded-full bg-white/30 blur-[1px] floating-slow" />
        <div className="absolute left-[70%] top-[60%] h-2 w-2 rounded-full bg-white/30 blur-[1px] floating" />
        <div className="absolute left-[35%] top-[70%] h-1.5 w-1.5 rounded-full bg-white/20 blur-[1px] floating-slow" />
      </div>
    </div>
  );
}
