"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion } from "framer-motion";
import {
  Activity,
  Brain,
  Flame,
  LayoutDashboard,
  LineChart,
  Settings,
  User,
} from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { label: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { label: "Meal Scanner", href: "/meal-scanner", icon: Flame },
  { label: "Workout Planner", href: "/workout-planner", icon: Activity },
  { label: "Progress Analytics", href: "/progress-analytics", icon: LineChart },
  { label: "AI Assistant", href: "/ai-assistant", icon: Brain },
  { label: "Profile", href: "/profile", icon: User },
  { label: "Settings", href: "/settings", icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <motion.aside
      initial={{ x: -20, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ duration: 0.6 }}
      className="sticky top-6 hidden h-[calc(100vh-3rem)] w-72 flex-col gap-6 rounded-[32px] border border-white/10 bg-white/5 p-6 backdrop-blur-2xl lg:flex"
    >
      <div className="flex items-center gap-3">
        <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-aura-accent text-aura-black font-semibold">
          A
        </div>
        <div>
          <p className="text-sm uppercase tracking-[0.3em] text-white/50">
            Aura Fit AI
          </p>
          <p className="text-lg font-semibold">Operating System</p>
        </div>
      </div>
      <nav className="flex flex-1 flex-col gap-2">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "group flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-medium transition",
                isActive
                  ? "bg-white/10 text-white shadow-[0_0_30px_rgba(255,122,0,0.18)]"
                  : "text-white/70 hover:text-white hover:bg-white/5"
              )}
            >
              <span
                className={cn(
                  "flex h-9 w-9 items-center justify-center rounded-xl border border-white/10 text-aura-accent transition",
                  isActive
                    ? "bg-aura-accent/15 border-aura-accent/40"
                    : "group-hover:border-aura-accent/30"
                )}
              >
                <Icon size={18} />
              </span>
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-white/10 to-transparent p-4 text-xs text-white/70">
        Need help? Ask the AI assistant for instant guidance anytime.
      </div>
    </motion.aside>
  );
}
