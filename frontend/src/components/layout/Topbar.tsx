"use client";

import { motion } from "framer-motion";
import { Bell, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";

interface TopbarProps {
  title: string;
  subtitle?: string;
}

export default function Topbar({ title, subtitle }: TopbarProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="flex flex-wrap items-center justify-between gap-4"
    >
      <div>
        <p className="text-sm text-white/60">{subtitle}</p>
        <h1 className="text-3xl font-semibold tracking-tight text-white">
          {title}
        </h1>
      </div>
      <div className="flex items-center gap-3">
        <Button variant="ghost" className="rounded-2xl">
          <Bell size={16} />
          Alerts
        </Button>
        <Button className="rounded-2xl">
          <Sparkles size={16} />
          New Scan
        </Button>
      </div>
    </motion.div>
  );
}
