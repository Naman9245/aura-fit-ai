import Topbar from "@/components/layout/Topbar";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";

export default function SettingsPage() {
  return (
    <div className="space-y-10">
      <Topbar title="Settings" subtitle="Personalize AURA" />
      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="glass-card space-y-4">
          <h3 className="text-lg font-semibold">Account settings</h3>
          <Input placeholder="Change email" type="email" />
          <Input placeholder="Update password" type="password" />
          <Button>Save changes</Button>
        </Card>
        <Card className="glass-card space-y-4">
          <h3 className="text-lg font-semibold">AI preferences</h3>
          <Input placeholder="Goal focus" />
          <Input placeholder="Nutrition style" />
          <Button variant="ghost">Update AI profile</Button>
        </Card>
      </div>
    </div>
  );
}
