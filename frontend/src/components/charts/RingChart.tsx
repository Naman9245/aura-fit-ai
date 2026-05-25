"use client";

import { useSyncExternalStore } from "react";
import { motion } from "framer-motion";
import { RadialBar, RadialBarChart, ResponsiveContainer } from "recharts";

interface RingChartProps {
  value: number;
  label: string;
  unit: string;
  accent?: string;
}

export default function RingChart({ value, label, unit, accent }: RingChartProps) {
  const data = [{ name: label, value }];
  const isClient = useSyncExternalStore(
    () => () => undefined,
    () => true,
    () => false,
  );

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.6 }}
      className="glass-card flex flex-col items-center justify-center gap-3"
    >
      <div className="relative h-32 w-32">
        {isClient ? (
          <ResponsiveContainer width="100%" height="100%" minHeight={128} minWidth={128}>
            <RadialBarChart
              data={data}
              innerRadius="75%"
              outerRadius="100%"
              startAngle={90}
              endAngle={-270}
            >
              <RadialBar
                dataKey="value"
                cornerRadius={999}
                fill={accent ?? "#FF7A00"}
                background={{ fill: "rgba(255,255,255,0.08)" }}
              />
            </RadialBarChart>
          </ResponsiveContainer>
        ) : (
          <div className="h-full w-full rounded-full bg-white/[0.03]" />
        )}
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <p className="text-xl font-semibold text-white">{value}%</p>
          <p className="text-xs text-white/50">{unit}</p>
        </div>
      </div>
      <p className="text-sm text-white/70">{label}</p>
    </motion.div>
  );
}
