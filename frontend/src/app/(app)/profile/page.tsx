import Topbar from "@/components/layout/Topbar";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function ProfilePage() {
  return (
    <div className="space-y-10">
      <Topbar title="Profile" subtitle="Your biometrics" />
      <Card className="glass-card space-y-6">
        <div className="grid gap-4 md:grid-cols-2">
          <Input placeholder="First name" />
          <Input placeholder="Last name" />
          <Input placeholder="Email" type="email" />
          <Input placeholder="Phone" type="tel" />
          <Input placeholder="Current weight" />
          <Input placeholder="Height" />
        </div>
        <Button>Save profile</Button>
      </Card>
    </div>
  );
}
