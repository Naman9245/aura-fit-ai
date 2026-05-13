import LineChartCard from "@/components/charts/LineChartCard";
import Topbar from "@/components/layout/Topbar";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

const weightData = [
  { name: "Mon", value: 74 },
  { name: "Tue", value: 73.6 },
  { name: "Wed", value: 73.8 },
  { name: "Thu", value: 73.2 },
  { name: "Fri", value: 73.1 },
  { name: "Sat", value: 72.9 },
  { name: "Sun", value: 72.7 },
];

export default function ProgressAnalyticsPage() {
  return (
    <div className="space-y-10">
      <Topbar title="Progress Analytics" subtitle="Premium insights" />
      <section className="grid gap-6 lg:grid-cols-2">
        <LineChartCard title="Weight history" data={weightData} />
        <LineChartCard title="Calorie history" data={weightData} />
      </section>
      <section className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
        <Card className="glass-card space-y-4">
          <h3 className="text-lg font-semibold">Body transformation</h3>
          <p className="text-sm text-white/60">
            Upload before/after photos to build a cinematic timeline of your
            progress.
          </p>
          <div className="flex items-center gap-3">
            <Button>Upload before</Button>
            <Button variant="ghost">Upload after</Button>
          </div>
        </Card>
        <Card className="glass-card space-y-4">
          <h3 className="text-lg font-semibold">Consistency score</h3>
          <p className="text-4xl font-semibold">92%</p>
          <p className="text-sm text-white/60">
            Keep your streak for 4 more days to unlock a new badge.
          </p>
        </Card>
      </section>
    </div>
  );
}
