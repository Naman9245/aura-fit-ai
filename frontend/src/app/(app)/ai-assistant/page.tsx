import { Sparkles } from "lucide-react";

import Topbar from "@/components/layout/Topbar";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Textarea } from "@/components/ui/textarea";

const messages = [
  {
    role: "assistant",
    content:
      "Good evening. Your recovery score is 88. You can add a strength focus today.",
  },
  {
    role: "user",
    content: "Can I eat pizza tonight?",
  },
  {
    role: "assistant",
    content:
      "Yes — you still have 540 kcal remaining. Pair with a protein side to stay on target.",
  },
];

export default function AIAssistantPage() {
  return (
    <div className="space-y-10">
      <Topbar title="AI Fitness Assistant" subtitle="Ask anything" />
      <section className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
        <Card className="glass-card flex flex-col gap-4">
          <div className="flex items-center gap-2 text-sm text-white/60">
            <Sparkles className="text-aura-accent" size={16} />
            AURA AI is online
          </div>
          <div className="flex-1 space-y-4">
            {messages.map((message, index) => (
              <div
                key={`${message.role}-${index}`}
                className={`rounded-2xl px-4 py-3 text-sm ${
                  message.role === "assistant"
                    ? "bg-white/5 text-white/80"
                    : "bg-aura-accent/10 text-white"
                }`}
              >
                {message.content}
              </div>
            ))}
          </div>
          <div className="space-y-3">
            <Textarea placeholder="Ask AURA AI anything..." />
            <Button className="w-full">Send message</Button>
          </div>
        </Card>
        <Card className="glass-card space-y-4">
          <h3 className="text-lg font-semibold">Quick actions</h3>
          <div className="space-y-3 text-sm text-white/70">
            <p>• Suggest a pre-workout meal</p>
            <p>• Analyze today’s macro split</p>
            <p>• Generate a recovery protocol</p>
            <p>• Update calorie target for the weekend</p>
          </div>
        </Card>
      </section>
    </div>
  );
}
