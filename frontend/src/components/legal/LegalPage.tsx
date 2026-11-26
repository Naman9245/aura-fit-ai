import Link from "next/link";

import { policiesUpdated } from "@/lib/site";

import SiteFooter from "./SiteFooter";

/** A plain, readable page for the privacy policy, terms and the account
 * deletion steps. */
export default function LegalPage({
  title,
  intro,
  children,
}: {
  title: string;
  intro: string;
  children: React.ReactNode;
}) {
  return (
    <main className="min-h-screen bg-black text-zinc-100">
      <header className="border-b border-white/10 px-6 py-4">
        <div className="mx-auto max-w-3xl">
          <Link href="/" className="text-xl font-semibold tracking-[0.2em]">
            AURA
          </Link>
        </div>
      </header>
      <article className="legal mx-auto max-w-3xl px-6 py-12">
        <h1 className="text-3xl font-semibold sm:text-4xl">{title}</h1>
        <p className="mt-2 text-sm text-zinc-400">
          Last updated {policiesUpdated}
        </p>
        <p className="mt-6 text-lg text-zinc-200">{intro}</p>
        {children}
      </article>
      <SiteFooter />
    </main>
  );
}
