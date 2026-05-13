import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

const steps = [
  "Choose your goal",
  "Training environment",
  "Body metrics",
  "Activity level",
  "Targets & nutrition",
];

export default function OnboardingPage() {
  return (
    <div className="mx-auto flex min-h-screen max-w-5xl flex-col gap-10 px-6 py-16">
      <div>
        <Badge variant="outline">Cinematic onboarding</Badge>
        <h1 className="mt-4 text-4xl font-semibold">Your AI fitness blueprint</h1>
        <p className="mt-3 text-base text-white/60">
          Five immersive steps that teach AURA FIT AI how to personalize your
          program, nutrition, and recovery.
        </p>
      </div>
      <div className="grid gap-6 lg:grid-cols-[0.4fr_0.6fr]">
        <Card className="glass-card space-y-4">
          {steps.map((step, index) => (
            <div
              key={step}
              className="flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm"
            >
              <span className="flex h-8 w-8 items-center justify-center rounded-full bg-aura-accent/20 text-aura-accent">
                {index + 1}
              </span>
              {step}
            </div>
          ))}
        </Card>
        <Card className="glass-card space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            <Input placeholder="Goal (Gain Muscle, Lose Fat, etc.)" />
            <Input placeholder="Workout location" />
            <Input placeholder="Experience level" />
            <Input placeholder="Age" type="number" />
            <Input placeholder="Weight (kg)" type="number" />
            <Input placeholder="Height (cm)" type="number" />
            <Input placeholder="Activity level" />
            <Input placeholder="Target weight" type="number" />
          </div>
          <Button className="w-full">Generate my AI plan</Button>
        </Card>
      </div>
    </div>
  );
}
