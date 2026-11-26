// Checks the built site (out/) has what Google Play and Google sign-in
// need: a privacy policy, terms and an account deletion page, each linked
// from every page's footer. With --published, also checks the real contact
// address is in, not the placeholder.
//
//   npm run build && node scripts/check-pages.mjs [--published]
import { existsSync, readFileSync } from "node:fs";

const pages = ["privacy", "terms", "delete-account"];
const problems = [];

for (const page of ["", ...pages]) {
  const file = `out/${page ? `${page}/` : ""}index.html`;
  if (!existsSync(file)) {
    problems.push(`${file} is missing`);
    continue;
  }
  const html = readFileSync(file, "utf8");
  for (const linked of pages) {
    if (!new RegExp(`href="[^"]*/${linked}/"`).test(html)) {
      problems.push(`${file} doesn't link to /${linked}/`);
    }
  }
  if (process.argv.includes("--published") && html.includes("contact@example.com")) {
    problems.push(`${file} still has the placeholder contact address`);
  }
}

if (problems.length > 0) {
  console.error(problems.join("\n"));
  process.exit(1);
}
console.log(`All ${pages.length} pages are built and linked from every page.`);
