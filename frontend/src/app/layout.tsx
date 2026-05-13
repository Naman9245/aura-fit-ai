import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "AURA FIT AI",
  description: "A futuristic AI fitness operating system.",
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
