import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AURA FIT AI",
  description:
    "Log Indian meals in under a minute, with safe daily targets that show their maths.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="min-h-full bg-aura-black text-aura-foreground">
        {children}
      </body>
    </html>
  );
}
