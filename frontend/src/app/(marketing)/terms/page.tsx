import type { Metadata } from "next";
import Link from "next/link";

import LegalPage from "@/components/legal/LegalPage";
import { appName, contactEmail } from "@/lib/site";

export const metadata: Metadata = {
  title: "Terms of use · AURA FIT AI",
  description: "The rules for using AURA FIT AI.",
};

export default function TermsPage() {
  return (
    <LegalPage
      title="Terms of use"
      intro={`By using ${appName} you agree to these terms. They're short, and the most important one comes first.`}
    >
      <h2>Not medical advice</h2>
      <p>
        {appName} gives general estimates of calories and nutrients to help
        you track your food. It doesn&apos;t diagnose, treat or prevent any
        condition. Talk to a doctor or a registered dietitian before changing
        your diet, and especially if you are pregnant, have diabetes, an
        eating disorder or any other medical condition.
      </p>

      <h2>Estimates can be wrong</h2>
      <p>
        Food values come from public food data and recipe calculations, and
        AI logging is a guess you should check. Portions, oil and recipes vary
        from kitchen to kitchen. Check what the app shows before you save it.
      </p>

      <h2>Who can use it</h2>
      <p>You must be 18 or older.</p>

      <h2>Your account</h2>
      <ul>
        <li>Keep your sign-in safe; you&apos;re responsible for what happens in your account.</li>
        <li>Your data is yours. Our <Link href="/privacy/">privacy policy</Link> says what we do with it.</li>
        <li>You can <Link href="/delete-account/">delete your account</Link> at any time.</li>
      </ul>

      <h2>Fair use</h2>
      <p>
        Don&apos;t misuse the app or its AI: no attempts to get around daily
        limits, reach other people&apos;s data, overload the service, or use
        it for anything unlawful. We may suspend an account that does.
      </p>

      <h2>The service</h2>
      <p>
        {appName} is free while it&apos;s in testing. It is provided as it
        is, and it may change, pause or stop. As far as the law allows, we
        aren&apos;t liable for losses that come from using it or from
        estimates in it.
      </p>

      <h2>Law</h2>
      <p>These terms are governed by the laws of India.</p>

      <h2>Contact</h2>
      <p>
        Questions: <a href={`mailto:${contactEmail}`}>{contactEmail}</a>.
      </p>
    </LegalPage>
  );
}
