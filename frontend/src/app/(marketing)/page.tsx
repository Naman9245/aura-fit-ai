import Link from "next/link";
import { ArrowUpRight, Play, Sparkles } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

const features = [
  {
    title: "Cinematic Onboarding",
    description: "A guided, Apple-grade flow that calibrates every metric to you.",
  },
  {
    title: "Adaptive Training OS",
    description: "Live workouts, recovery, and nutrition updated in real time.",
  },
  {
    title: "Vision Food Scan",
    description: "Gemini Vision analysis with floating macros and calorie overlays.",
  },
  {
    title: "AI Coach",
    description: "Personal assistant that understands your data, goals, and habits.",
  },
];

export default function Home() {
  return (
    <main className="relative overflow-hidden">
      <section className="mx-auto flex min-h-screen max-w-6xl flex-col items-center justify-center gap-12 px-6 pb-20 pt-24 text-center">
        <Badge className="glass-panel text-white/80">
          AURA FIT AI • 2032 Fitness OS
        </Badge>
        <div className="space-y-6">
          <h1 className="text-gradient text-4xl font-semibold leading-tight sm:text-6xl">
            THE FUTURE OF PERSONAL FITNESS
          </h1>
          <p className="mx-auto max-w-2xl text-base text-white/70 sm:text-lg">
            An AI-powered operating system for your body, nutrition, and
            performance. Built with premium glassmorphism, cinematic onboarding,
            and futuristic intelligence.
          </p>
        </div>
        <div className="flex flex-wrap items-center justify-center gap-4">
          <Button size="lg" className="glow-border">
            Launch Dashboard <ArrowUpRight size={18} />
          </Button>
          <Button variant="ghost" size="lg">
            <Play size={18} /> Watch Demo
          </Button>
        </div>
        <div className="grid w-full gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="glass-card flex flex-col gap-6 text-left">
            <div className="flex items-center gap-3 text-sm text-white/70">
              <Sparkles size={18} className="text-aura-accent" />
              Premium AI dashboard preview
            </div>
            <div className="grid gap-4 md:grid-cols-2">
              {features.map((feature) => (
                <Card
                  key={feature.title}
                  className="rounded-2xl border border-white/10 bg-white/5 p-4"
                >
                  <h3 className="text-base font-semibold text-white">
                    {feature.title}
                  </h3>
                  <p className="mt-2 text-sm text-white/60">
                    {feature.description}
                  </p>
                </Card>
              ))}
            </div>
            <div className="flex flex-wrap gap-3">
              <Badge variant="outline">AI Fitness Rings</Badge>
              <Badge variant="outline">Holographic UI</Badge>
              <Badge variant="outline">Realtime Insights</Badge>
            </div>
          </div>
          <div className="flex flex-col gap-4">
            <Card className="glass-card floating">
              <div className="flex items-center justify-between">
                <p className="text-sm text-white/60">Active Energy</p>
                <span className="text-xs text-aura-accent-soft">+12%</span>
              </div>
              <p className="mt-4 text-3xl font-semibold">2,340 kcal</p>
              <div className="mt-6 h-2 w-full rounded-full bg-white/10">
                <div className="h-2 w-4/5 rounded-full bg-aura-accent" />
              </div>
            </Card>
            <Card className="glass-card floating-slow">
              <p className="text-sm text-white/60">Recovery Intelligence</p>
              <p className="mt-4 text-xl font-semibold">Ready to push • 92%</p>
              <p className="mt-2 text-xs text-white/50">
                AI recommends a strength focus today.
              </p>
            </Card>
            <Card className="glass-card">
              <p className="text-sm text-white/60">Assistant</p>
              <p className="mt-3 text-base text-white/80">
                “Can I eat pizza tonight?”
              </p>
              <p className="mt-2 text-xs text-white/50">
                You still have 540 kcal and 32g protein remaining.
              </p>
            </Card>
          </div>
        </div>
        <div className="flex flex-wrap items-center justify-center gap-4 text-sm text-white/50">
          <span>Trusted by 42k athletes</span>
          <span>•</span>
          <span>Glassmorphism UI</span>
          <span>•</span>
          <span>Gemini Vision Food Scan</span>
        </div>
        <Link
          href="/login"
          className="text-sm uppercase tracking-[0.3em] text-white/40"
        >
          Enter the system
        </Link>
      </section>
    </main>
  );
}
