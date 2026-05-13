import Link from "next/link";

import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center px-6 py-16">
      <Card className="glass-card w-full max-w-lg space-y-6 p-10">
        <div>
          <p className="text-xs uppercase tracking-[0.3em] text-white/50">
            AURA FIT AI
          </p>
          <h1 className="mt-4 text-3xl font-semibold">Welcome back</h1>
          <p className="mt-2 text-sm text-white/60">
            Log in to your AI-powered fitness operating system.
          </p>
        </div>
        <div className="space-y-4">
          <Input placeholder="Email address" type="email" />
          <Input placeholder="Password" type="password" />
          <Button className="w-full">Login</Button>
          <Button variant="ghost" className="w-full">
            Continue with Google
          </Button>
        </div>
        <div className="text-sm text-white/50">
          New here?{" "}
          <Link href="/signup" className="text-aura-accent">
            Create account
          </Link>
        </div>
      </Card>
    </div>
  );
}
