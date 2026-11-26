// Facts the website states in more than one place, kept here so the pages
// can't disagree.

/** Where people write for help, to use their privacy rights, or to ask
 * for their account to be deleted. The deploy job sets it from the
 * CONTACT_EMAIL repository variable; it's never published without one. */
export const contactEmail =
  process.env.NEXT_PUBLIC_CONTACT_EMAIL || "contact@example.com";

/** When the privacy policy, terms and deletion page last changed. */
export const policiesUpdated = "26 November 2026";

export const appName = "AURA FIT AI";
