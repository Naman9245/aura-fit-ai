import type { NextConfig } from "next";

// The site is plain files (`npm run build` writes them to out/), published
// to GitHub Pages by .github/workflows/website.yml. On the default Pages
// address the site lives under /aura-fit-ai; the workflow passes that in,
// and it's empty on a custom domain.
const nextConfig: NextConfig = {
  output: "export",
  trailingSlash: true,
  basePath: process.env.PAGES_BASE_PATH || "",
  turbopack: {
    root: __dirname,
  },
};

export default nextConfig;
