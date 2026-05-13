import { Camera, Scan, UploadCloud } from "lucide-react";

import Topbar from "@/components/layout/Topbar";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

const detectedItems = [
  { item: "Chicken Breast", kcal: 220 },
  { item: "Jasmine Rice", kcal: 300 },
  { item: "Avocado", kcal: 140 },
];

export default function MealScannerPage() {
  return (
    <div className="space-y-10">
      <Topbar
        title="AI Food Analyzer"
        subtitle="Gemini Vision scanning"
      />
      <section className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
        <Card className="glass-card relative overflow-hidden">
          <div className="absolute inset-0 rounded-3xl border border-aura-accent/20" />
          <div className="absolute left-1/2 top-1/2 h-72 w-72 -translate-x-1/2 -translate-y-1/2 rounded-full border border-aura-accent/40 opacity-60" />
          <div className="absolute left-1/2 top-1/2 h-40 w-40 -translate-x-1/2 -translate-y-1/2 rounded-full border border-aura-accent/50 opacity-60 pulse-glow" />
          <div className="absolute inset-x-10 top-1/2 h-[2px] -translate-y-1/2 bg-gradient-to-r from-transparent via-aura-accent to-transparent opacity-70 animate-[scan_3s_linear_infinite]" />
          <div className="relative space-y-6">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-xl font-semibold">Scan your meal</h2>
                <p className="text-sm text-white/60">
                  Drop an image or capture with your camera.
                </p>
              </div>
              <Scan className="text-aura-accent" />
            </div>
            <div className="flex flex-col items-center justify-center gap-4 rounded-2xl border border-dashed border-white/20 bg-white/5 px-6 py-12 text-sm text-white/60">
              <UploadCloud className="h-10 w-10 text-aura-accent" />
              Drag and drop an image here
              <div className="flex gap-3">
                <Button size="sm">Upload</Button>
                <Button size="sm" variant="ghost">
                  <Camera size={14} />
                  Camera
                </Button>
              </div>
            </div>
          </div>
        </Card>
        <Card className="glass-card space-y-4">
          <h3 className="text-lg font-semibold">Detected items</h3>
          <div className="space-y-3">
            {detectedItems.map((item) => (
              <div
                key={item.item}
                className="flex items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm"
              >
                <span>{item.item}</span>
                <span className="text-aura-accent">{item.kcal} kcal</span>
              </div>
            ))}
          </div>
          <Button className="w-full">Save meal log</Button>
        </Card>
      </section>
    </div>
  );
}
