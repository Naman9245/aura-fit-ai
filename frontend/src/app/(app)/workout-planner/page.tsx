import { Dumbbell, Timer } from "lucide-react";

import Topbar from "@/components/layout/Topbar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

const workouts = [
  {
    title: "Strength Prime",
    level: "Intermediate",
    calories: 420,
    exercises: 6,
  },
  {
    title: "Home Mobility Flow",
    level: "Beginner",
    calories: 240,
    exercises: 5,
  },
  {
    title: "Hypertrophy Surge",
    level: "Advanced",
    calories: 520,
    exercises: 8,
  },
];

export default function WorkoutPlannerPage() {
  return (
    <div className="space-y-10">
      <Topbar title="Workout Planner" subtitle="Adaptive AI sessions" />
      <section className="grid gap-6 lg:grid-cols-3">
        {workouts.map((workout) => (
          <Card key={workout.title} className="glass-card space-y-4">
            <div className="flex items-center justify-between">
              <Badge variant="outline">{workout.level}</Badge>
              <span className="text-xs text-white/50">
                {workout.calories} kcal
              </span>
            </div>
            <h3 className="text-lg font-semibold">{workout.title}</h3>
            <div className="flex items-center justify-between text-sm text-white/60">
              <span className="flex items-center gap-2">
                <Dumbbell size={16} /> {workout.exercises} exercises
              </span>
              <span className="flex items-center gap-2">
                <Timer size={16} /> 45 mins
              </span>
            </div>
            <Button variant="ghost" className="w-full">
              View workout
            </Button>
          </Card>
        ))}
      </section>
    </div>
  );
}
