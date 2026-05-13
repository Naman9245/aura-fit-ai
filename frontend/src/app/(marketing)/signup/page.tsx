import Link from "next/link";

import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function SignupPage() {
  return (
    <div className="flex min-h-screen items-center justify-center px-6 py-16">
      <Card className="glass-card w-full max-w-xl space-y-6 p-10">
        <div>
          <p className="text-xs uppercase tracking-[0.3em] text-white/50">
            AURA FIT AI
          </p>
          <h1 className="mt-4 text-3xl font-semibold">
            Create your AI profile
          </h1>
          <p className="mt-2 text-sm text-white/60">
            Start your cinematic onboarding journey.
          </p>
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          <Input placeholder="First name" />
          <Input placeholder="Last name" />
          <Input placeholder="Email address" type="email" />
          <Input placeholder="Password" type="password" />
        </div>
        <Button className="w-full">Create account</Button>
        <Button variant="ghost" className="w-full">
          Sign up with Google
        </Button>
        <div className="text-sm text-white/50">
          Already have access?{" "}
          <Link href="/login" className="text-aura-accent">
            Log in
          </Link>
        </div>
      </Card>
    </div>
  );
}
