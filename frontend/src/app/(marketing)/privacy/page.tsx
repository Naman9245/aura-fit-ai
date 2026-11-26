import type { Metadata } from "next";
import Link from "next/link";

import LegalPage from "@/components/legal/LegalPage";
import { appName, contactEmail } from "@/lib/site";

export const metadata: Metadata = {
  title: "Privacy policy · AURA FIT AI",
  description: "What AURA FIT AI keeps about you, why, and how to delete it.",
};

export default function PrivacyPage() {
  return (
    <LegalPage
      title="Privacy policy"
      intro={`${appName} keeps only what it needs to work out your targets and log your food. It never sells your data and shows no ads.`}
    >
      <h2>Who we are</h2>
      <p>
        {appName} is an Android app made by an independent developer in
        India. For anything about your data, write to{" "}
        <a href={`mailto:${contactEmail}`}>{contactEmail}</a>.
      </p>

      <h2>What we keep</h2>
      <ul>
        <li>
          <strong>Your account:</strong> your email address. If you sign in
          with Google, Google also shares your name and a link to your profile
          photo. We use only the email.
        </li>
        <li>
          <strong>Your profile:</strong> birth date, sex, height, activity
          level, goal and diet type, which the app needs to work out your
          targets.
        </li>
        <li>
          <strong>Your targets and weigh-ins:</strong> the calories, protein,
          carbs, fat, water and steps targets, and the weights you enter.
        </li>
        <li>
          <strong>Your logs:</strong> the food you log (dish, portion,
          oil level, calories and macros, and when you ate it), saved meals,
          water and steps.
        </li>
        <li>
          <strong>AI use:</strong> how many AI text logs you used each day, and
          for each one whether it worked, how long it took and what it cost.
          Never the words you typed.
        </li>
        <li>
          <strong>Crash reports</strong>, unless you turn them off: where the
          app failed, the type of error, the phone model, Android version, app
          version and a random ID for the install. Never your meals, email or
          anything you typed.
        </li>
      </ul>
      <p>
        We don&apos;t collect your location, contacts, photos or anything
        from other apps.
      </p>

      <h2>Why we keep it</h2>
      <ul>
        <li>To work out safe daily targets and show how they were calculated.</li>
        <li>To keep your logs on every phone you sign in on.</li>
        <li>To limit daily AI use, so the service stays fast and affordable.</li>
        <li>To find and fix crashes.</li>
      </ul>
      <p>
        You agree to this when you create an account, under India&apos;s
        Digital Personal Data Protection Act, 2023. You can withdraw that
        consent at any time by deleting your account.
      </p>

      <h2>Where it goes</h2>
      <ul>
        <li>
          <strong>Your phone</strong> holds your data first, so the app works
          offline. Signing out removes it from the phone.
        </li>
        <li>
          <strong>Supabase</strong> stores your account and a copy of your
          data on servers in Mumbai, India.
        </li>
        <li>
          <strong>Google Gemini</strong> reads a meal you describe with AI
          logging, to turn it into foods and portions. We send only the words
          of that meal, never your name or email, and we don&apos;t store
          them. We use Gemini&apos;s paid service, under which Google
          doesn&apos;t use them to improve its products.
        </li>
        <li>
          <strong>Firebase Crashlytics</strong> (Google) receives crash
          reports and keeps them for 90 days.
        </li>
        <li>
          <strong>Our email service</strong> sends your sign-in codes.
        </li>
      </ul>
      <p>
        These companies process data only to run {appName}. Google&apos;s
        services may process it outside India. We never sell or rent your
        data, and never share it for advertising.
      </p>

      <h2>How long we keep it</h2>
      <p>
        As long as you have an account. When you delete your account,
        everything in it is deleted from our database at once. Our daily
        backups are kept for 7 days, so deleted data is gone from them within
        a week. Crash reports have no link to your account and are deleted
        after 90 days.
      </p>

      <h2>Your rights</h2>
      <ul>
        <li>
          <strong>See your data:</strong> the app exports all of it as JSON
          and CSV files (account sheet, Export my data).
        </li>
        <li>
          <strong>Correct it:</strong> edit your details, targets and logs in
          the app.
        </li>
        <li>
          <strong>Delete it:</strong> delete your account in the app, or{" "}
          <Link href="/delete-account/">ask us to</Link>.
        </li>
        <li>
          <strong>Turn off crash reports:</strong> account sheet, Send crash
          reports.
        </li>
        <li>
          <strong>Complain:</strong> write to{" "}
          <a href={`mailto:${contactEmail}`}>{contactEmail}</a>. We reply
          within 30 days. If you&apos;re not satisfied, you can go to the Data
          Protection Board of India.
        </li>
      </ul>

      <h2>Children</h2>
      <p>
        {appName} is for adults aged 18 and over. We don&apos;t knowingly keep
        data about anyone younger; if you think we do, write to us and we
        will delete it.
      </p>

      <h2>Health</h2>
      <p>
        {appName} gives general nutrition estimates, not medical advice. Talk
        to a doctor or a registered dietitian before changing your diet,
        especially if you are pregnant or have a medical condition.
      </p>

      <h2>Security</h2>
      <p>
        Data travels encrypted, and each account can reach only its own rows
        on the server. No system is perfectly secure; if a breach ever
        affects your data, we will tell you and the Data Protection Board as
        the law requires.
      </p>

      <h2>Changes</h2>
      <p>
        If this policy changes, the date at the top changes too. For a big
        change, we will tell you in the app first.
      </p>
    </LegalPage>
  );
}
