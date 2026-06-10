# Decision Scenarios 4–5 — Marketing Cloud Reference

> Scenarios 1–3 are in SKILL.md. Load this file for Triggered Send and AMPscript debugging gotchas. Moved from SKILL.md body to keep body ≤ ~4,500 words.

---

### Scenario 4 — Triggered Send Definition left paused after edit

**Situation:** A developer updates the copy in a transactional order-confirmation email (fixing a typo in the footer). They save the email in Content Builder and mark the ticket done. The next day, the support team reports no confirmation emails have gone out since the edit.

**Competent move:** After editing any email used by a Triggered Send Definition, the TSD must be **stopped, then republished (restarted)** to pick up the new email version. The TSD holds a reference to the published email at the time it was last started. Editing the email in Content Builder does not automatically propagate into an active TSD. The developer should have stopped the TSD, confirmed the updated email is associated, then restarted it.

**Tempting-but-wrong:** Assuming that saving the email in Content Builder automatically updates the live TSD. It does not. The TSD keeps sending the pre-edit version of the email until it is republished. Some developers also try pausing (not stopping) the TSD — messages queue during pause and flush when resumed, but the email version is still not refreshed until a full stop-and-restart cycle.

**Verify:** In Email Studio → Triggered Sends, open the TSD and confirm its status is *Active* and the associated email reflects the current version. Send a test trigger via the API or a test script and confirm the received email contains the updated copy.

---

### Scenario 5 — AMPscript Lookup() returning blank without error

**Situation:** A welcome email uses AMPscript to look up a "gift tier" label from a reference DE (`GiftTiers`) based on the subscriber's most recent gift amount. Some recipients receive an email where the gift tier line is completely blank, but no error bounce or send failure is logged.

**Competent move:** `Lookup()` returns an empty string when the lookup key finds no matching row — it does not halt rendering or produce an error. Add an `IF Empty()` guard: if the lookup returns empty, render a safe fallback string (e.g. "supporter") instead of a blank line. Investigate why those subscribers have no matching row in `GiftTiers` — they may have a gift amount that falls outside the DE's tier ranges, or a data type mismatch between the subscriber field and the DE's key column.

**Tempting-but-wrong:** Concluding that "no error = the lookup worked" and searching for a rendering bug in the HTML instead. The blank is not a rendering bug — the AMPscript ran successfully and returned an empty string exactly as designed. Without an `IF Empty()` guard, blank returns are invisible in Test Sends when the test subscriber happens to have a matching row.

**Verify:** In Subscriber Preview, select a subscriber who received the blank line and inspect the rendered email. Then open the `GiftTiers` DE and query for that subscriber's gift amount value — a missing or mismatched row confirms the lookup miss. Add the guard, re-preview with the same subscriber, and confirm the fallback renders.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
