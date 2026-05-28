"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { ArrowRight, Brain, Camera, Menu, Shield, X, Zap } from "lucide-react";
import { motion } from "framer-motion";

const navLinks = [
  { label: "Home", href: "#home" },
  { label: "Why Aura", href: "#why" },
  { label: "Showcase", href: "#showcase" },
  { label: "Plans", href: "#plans" },
];

const showcaseCards = [
  {
    title: "AI Workout Engine",
    subtitle: "Adaptive volume and intensity by daily readiness.",
    image:
      "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=1200&q=80",
  },
  {
    title: "Vision Meal Scanner",
    subtitle: "Capture your plate and get macro-aware suggestions.",
    image:
      "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1200&q=80",
  },
  {
    title: "Performance Analytics",
    subtitle: "Trend lines for energy balance, lifts, and progress.",
    image:
      "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=1200&q=80",
  },
];

const stats = [
  { label: "Active Members", value: "42K+" },
  { label: "Avg Weekly Compliance", value: "84%" },
  { label: "Coach Response Time", value: "< 3 sec" },
];

export default function Home() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [slide, setSlide] = useState(0);

  useEffect(() => {
    const timer = window.setInterval(() => {
      setSlide((prev) => (prev + 1) % showcaseCards.length);
    }, 3500);

    return () => window.clearInterval(timer);
  }, []);

  return (
    <main className="min-h-screen bg-black text-zinc-100">
      <header className="fixed inset-x-0 top-0 z-50 border-b border-white/10 bg-black/60 backdrop-blur-xl">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <Link href="/" className="text-xl font-semibold tracking-[0.2em]">
            AURA
          </Link>
          <nav className="hidden items-center gap-7 md:flex">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="text-xs uppercase tracking-[0.18em] text-zinc-400 transition hover:text-white"
              >
                {link.label}
              </a>
            ))}
            <Link
              href="/login"
              className="rounded-full border border-white/20 px-4 py-2 text-xs uppercase tracking-[0.16em] transition hover:bg-white hover:text-black"
            >
              Login
            </Link>
          </nav>
          <button
            type="button"
            className="text-zinc-300 md:hidden"
            aria-label="Toggle menu"
            onClick={() => setIsMenuOpen((prev) => !prev)}
          >
            {isMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
        {isMenuOpen ? (
          <div className="border-t border-white/10 bg-black px-6 py-4 md:hidden">
            <div className="flex flex-col gap-4">
              {navLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  onClick={() => setIsMenuOpen(false)}
                  className="text-xs uppercase tracking-[0.18em] text-zinc-300"
                >
                  {link.label}
                </a>
              ))}
            </div>
          </div>
        ) : null}
      </header>

      <section
        id="home"
        className="relative flex min-h-screen items-end overflow-hidden px-6 pb-16 pt-24"
      >
        <div
          className="absolute inset-0 bg-cover bg-center"
          style={{
            backgroundImage:
              "url('https://images.unsplash.com/photo-1574680178050-55c6a6a96e0a?auto=format&fit=crop&w=1920&q=80')",
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black via-black/70 to-black/30" />
        <div className="relative mx-auto flex w-full max-w-6xl flex-col gap-8 lg:flex-row lg:items-end lg:justify-between">
          <motion.div
            initial={{ opacity: 0, y: 24 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7 }}
            className="max-w-3xl"
          >
            <p className="text-xs uppercase tracking-[0.25em] text-zinc-300">AURA FIT AI</p>
            <h1 className="mt-4 text-4xl font-semibold leading-[0.98] sm:text-6xl lg:text-7xl">
              THINK.
              <br />
              TRAIN.
              <br />
              TRANSFORM.
            </h1>
            <p className="mt-5 max-w-xl text-sm text-zinc-300 sm:text-base">
              A cinematic fitness platform with elite UX, intelligent coaching, and
              a smooth workflow from onboarding to measurable weekly progress.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link
                href="/signup"
                className="inline-flex items-center gap-2 rounded-full bg-white px-5 py-3 text-xs font-semibold uppercase tracking-[0.16em] text-black transition hover:bg-zinc-200"
              >
                Start Now <ArrowRight size={14} />
              </Link>
              <a
                href="#showcase"
                className="inline-flex items-center rounded-full border border-white/40 px-5 py-3 text-xs uppercase tracking-[0.16em] text-white transition hover:bg-white hover:text-black"
              >
                Explore Features
              </a>
            </div>
          </motion.div>
          <div className="grid w-full max-w-lg grid-cols-1 gap-3 sm:grid-cols-3 lg:grid-cols-1">
            {stats.map((item) => (
              <div key={item.label} className="rounded-xl border border-white/10 bg-black/40 p-4">
                <p className="text-xs uppercase tracking-[0.16em] text-zinc-400">{item.label}</p>
                <p className="mt-2 text-2xl font-semibold">{item.value}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="why" className="mx-auto max-w-6xl px-6 py-20">
        <div className="mb-10 flex items-end justify-between gap-5">
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-zinc-400">Why Aura</p>
            <h2 className="mt-3 text-3xl font-semibold sm:text-5xl">
              Built Like A Premium Product
            </h2>
          </div>
        </div>
        <div className="grid gap-4 md:grid-cols-3">
          <article className="rounded-2xl border border-white/10 bg-zinc-950 p-6">
            <Zap className="text-white" size={18} />
            <h3 className="mt-4 text-lg font-medium">Fast interactions</h3>
            <p className="mt-2 text-sm text-zinc-400">
              Designed for speed with reduced friction across every recurring action.
            </p>
          </article>
          <article className="rounded-2xl border border-white/10 bg-zinc-950 p-6">
            <Brain className="text-white" size={18} />
            <h3 className="mt-4 text-lg font-medium">Context-aware AI</h3>
            <p className="mt-2 text-sm text-zinc-400">
              Guidance adapts to your routine, goals, and logged behavior.
            </p>
          </article>
          <article className="rounded-2xl border border-white/10 bg-zinc-950 p-6">
            <Shield className="text-white" size={18} />
            <h3 className="mt-4 text-lg font-medium">Reliable backend</h3>
            <p className="mt-2 text-sm text-zinc-400">
              Smooth auth, stable endpoints, and clean data flow for your dashboard.
            </p>
          </article>
        </div>
      </section>

      <section id="showcase" className="mx-auto max-w-6xl px-6 py-20">
        <div className="mb-7">
          <p className="text-xs uppercase tracking-[0.2em] text-zinc-400">Showcase</p>
          <h2 className="mt-3 text-3xl font-semibold sm:text-5xl">
            Smooth Slider Experience
          </h2>
        </div>
        <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-zinc-950 p-4 sm:p-6">
          <div
            className="flex transition-transform duration-700 ease-out"
            style={{ transform: `translateX(-${slide * 100}%)` }}
          >
            {showcaseCards.map((card) => (
              <div key={card.title} className="w-full shrink-0 px-1">
                <article className="overflow-hidden rounded-xl border border-white/10">
                  <div
                    className="h-64 bg-cover bg-center sm:h-80"
                    style={{ backgroundImage: `url('${card.image}')` }}
                  />
                  <div className="bg-black p-5">
                    <h3 className="text-2xl font-semibold">{card.title}</h3>
                    <p className="mt-2 text-sm text-zinc-400">{card.subtitle}</p>
                  </div>
                </article>
              </div>
            ))}
          </div>
          <div className="mt-4 flex gap-2">
            {showcaseCards.map((card, index) => (
              <button
                key={card.title}
                type="button"
                onClick={() => setSlide(index)}
                className={`h-2 rounded-full transition-all ${
                  slide === index ? "w-10 bg-white" : "w-2 bg-zinc-500"
                }`}
                aria-label={`Slide ${index + 1}`}
              />
            ))}
          </div>
        </div>
      </section>

      <section id="plans" className="mx-auto max-w-6xl px-6 pb-24 pt-16">
        <div className="rounded-2xl border border-white/10 bg-zinc-950 p-8 sm:p-10">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.2em] text-zinc-400">Start Today</p>
              <h2 className="mt-3 text-3xl font-semibold sm:text-5xl">
                Ready To Build Your Best Shape?
              </h2>
            </div>
            <Link
              href="/signup"
              className="inline-flex items-center gap-2 rounded-full bg-white px-5 py-3 text-xs font-semibold uppercase tracking-[0.16em] text-black transition hover:bg-zinc-200"
            >
              Create Account <ArrowRight size={14} />
            </Link>
          </div>
        </div>
      </section>

      <footer className="border-t border-white/10 px-6 py-8">
        <div className="mx-auto flex max-w-6xl flex-col gap-3 text-xs uppercase tracking-[0.16em] text-zinc-500 sm:flex-row sm:items-center sm:justify-between">
          <span>Aura Fit AI</span>
          <span>Designed for consistency and performance</span>
          <span>© 2026</span>
        </div>
      </footer>

      <a
        href="#home"
        className="fixed bottom-5 right-5 z-40 inline-flex h-10 w-10 items-center justify-center rounded-full border border-white/20 bg-black/80 text-zinc-200 backdrop-blur transition hover:bg-white hover:text-black"
        aria-label="Back to top"
      >
        <Camera size={16} />
      </a>
    </main>
  );
}
