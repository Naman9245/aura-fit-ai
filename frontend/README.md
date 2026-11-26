# AURA FIT AI: the website

The landing page, plus the three pages Google Play and Google sign-in need: `/privacy/`, `/terms/` and `/delete-account/`. It's built as plain files (`out/`) and published to GitHub Pages by `.github/workflows/website.yml`.

```bash
npm ci
npm run dev            # http://localhost:3000
npm run lint
npm run build          # writes out/
npm run check:pages    # the three pages exist and every page links them
```

The contact address on the pages comes from `NEXT_PUBLIC_CONTACT_EMAIL`, which the deploy job sets from the `CONTACT_EMAIL` repository variable. Without it, builds show a placeholder, and the deploy job doesn't run. Facts the pages share (the contact address, when the policies last changed) live in `src/lib/site.ts`.

The privacy policy describes what the app actually does. When the app starts keeping something new, or sends data somewhere new, update it in the same pull request.
