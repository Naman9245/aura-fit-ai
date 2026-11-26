import Link from "next/link";

/** The footer on every page, with the links Google Play asks for. */
export default function SiteFooter() {
  return (
    <footer className="border-t border-white/10 px-6 py-8">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 text-xs uppercase tracking-[0.16em] text-zinc-500 sm:flex-row sm:items-center sm:justify-between">
        <span>AURA FIT AI © 2026</span>
        <nav className="flex flex-wrap gap-5">
          <Link href="/privacy/" className="transition hover:text-white">
            Privacy
          </Link>
          <Link href="/terms/" className="transition hover:text-white">
            Terms
          </Link>
          <Link href="/delete-account/" className="transition hover:text-white">
            Delete your account
          </Link>
        </nav>
      </div>
    </footer>
  );
}
