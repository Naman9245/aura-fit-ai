import RingChart from "@/components/charts/RingChart";
import LineChartCard from "@/components/charts/LineChartCard";
import Topbar from "@/components/layout/Topbar";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";

const rings = [
  { label: "Calories", value: 72, unit: "kcal" },
  { label: "Protein", value: 65, unit: "g" },
  { label: "Hydration", value: 80, unit: "L" },
  { label: "Steps", value: 58, unit: "steps" },
];

const lineData = [
  { name: "Mon", value: 72 },
  { name: "Tue", value: 80 },
  { name: "Wed", value: 68 },
  { name: "Thu", value: 90 },
  { name: "Fri", value: 84 },
  { name: "Sat", value: 96 },
  { name: "Sun", value: 88 },
];

export default function DashboardPage() {
  return (
    <div className="space-y-10">
      <Topbar title="Good Evening, Nova 👋" subtitle="AURA FIT AI" />
      <section className="grid gap-6 xl:grid-cols-[1.4fr_0.6fr]">
        <Card className="glass-card space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-semibold">Daily performance</h2>
              <p className="text-sm text-white/60">
                Live AI monitoring of your energy systems.
              </p>
            </div>
            <Badge>AI Synced</Badge>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {rings.map((ring) => (
              <RingChart key={ring.label} {...ring} />
            ))}
          </div>
        </Card>
        <Card className="glass-card space-y-6">
          <h3 className="text-lg font-semibold">AI insights</h3>
          <div className="space-y-4 text-sm text-white/70">
            <p>Recovery score is trending high. Strength focus recommended.</p>
            <p>Protein intake is 18g below target. Add lean protein snack.</p>
            <p>Hydration is strong. Maintain 3.1L to hit daily goal.</p>
          </div>
        </Card>
      </section>
      <section className="grid gap-6 md:grid-cols-2">
        <LineChartCard title="Calorie consistency" data={lineData} />
        <LineChartCard title="Protein adherence" data={lineData} />
      </section>
    </div>
  );
}
