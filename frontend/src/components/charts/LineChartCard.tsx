"use client";

import {
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { motion } from "framer-motion";

interface LineChartCardProps {
  title: string;
  data: Array<{ name: string; value: number }>;
}

export default function LineChartCard({ title, data }: LineChartCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="glass-card"
    >
      <div className="flex items-center justify-between">
        <h3 className="text-base font-semibold">{title}</h3>
        <span className="text-xs text-white/50">Last 7 days</span>
      </div>
      <div className="mt-6 h-40">
        <ResponsiveContainer width="100%" height="100%" minHeight={160}>
          <LineChart data={data}>
            <XAxis dataKey="name" tick={{ fill: "#8b93b3" }} axisLine={false} />
            <YAxis hide domain={[0, "dataMax + 10"]} />
            <Tooltip
              contentStyle={{
                background: "rgba(5,8,22,0.85)",
                border: "1px solid rgba(255,255,255,0.1)",
                borderRadius: "12px",
              }}
            />
            <Line
              type="monotone"
              dataKey="value"
              stroke="#FF7A00"
              strokeWidth={3}
              dot={false}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </motion.div>
  );
}
