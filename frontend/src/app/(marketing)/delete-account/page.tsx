import type { Metadata } from "next";

import LegalPage from "@/components/legal/LegalPage";
import { appName, contactEmail } from "@/lib/site";

export const metadata: Metadata = {
  title: "Delete your account · AURA FIT AI",
  description: "How to delete your AURA FIT AI account and all its data.",
};

const subject = encodeURIComponent(`Delete my ${appName} account`);

export default function DeleteAccountPage() {
  return (
    <LegalPage
      title={`Delete your ${appName} account`}
      intro="Deleting your account removes it and everything in it: your profile, targets, weigh-ins, food logs, saved meals, water and steps. It can't be undone."
    >
      <h2>In the app</h2>
      <ol>
        <li>Open {appName}.</li>
        <li>On Today, tap the account button at the top right.</li>
        <li>Tap Delete account, then Delete everything.</li>
      </ol>
      <p>
        Your account is deleted at once. Export your data first (Export my
        data, on the same sheet) if you want a copy.
      </p>

      <h2>Without the app</h2>
      <p>
        Email{" "}
        <a href={`mailto:${contactEmail}?subject=${subject}`}>{contactEmail}</a>{" "}
        from the address you signed up with, with the subject &ldquo;Delete
        my {appName} account&rdquo;. We delete the account within 7 days and
        reply to confirm.
      </p>

      <h2>What happens to your data</h2>
      <ul>
        <li>Everything in your account is deleted from our database.</li>
        <li>Our daily backups keep a copy for up to 7 more days, then it&apos;s gone.</li>
        <li>
          Crash reports have no link to your account; they are deleted after
          90 days.
        </li>
        <li>
          Signing out on a phone removes your data from that phone; deleting
          the app does too.
        </li>
      </ul>
    </LegalPage>
  );
}
