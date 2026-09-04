---
name: update-weekly-report
description: Refresh an existing Customer Success Weekly Report doc from the Tracker — re-pull the week, fold in what landed since, tighten the prose.
argument-hint: "[your name] [Friday's date of the week, e.g. 28 August 2026]"
disable-model-invocation: true
---

Update the weekly report that already exists under **Customer Success Weekly Report / \<person\>**, rather than writing a new one. Sibling skill `weekly-report` owns the roster and the format; this one owns the refresh.

## Steps

0. **Resolve the person.** Read the **Roster** table in `../weekly-report/SKILL.md` and match the argument against its aliases — that table is the only copy of the names, Tracker ids and folder ids. With no name given, default to **whoever is running the skill**: call `get_current_user` and match its name against the `Tracker display name` column. This skill is shared, so never fall back to a fixed person. If a name is given but matches nobody, or the current user matches no row, stop and ask. Done when you have the roster row in hand.

1. **Fix the week and find the doc.** Same week rule as `weekly-report`: the report is titled after the **Friday** of the target week (default: the Friday of the current week; an argument like "last week" or an explicit date overrides). Find it with `list_documents`, `collectionId: "e2fe74e9-2a93-4a8e-ae9f-901dc54457b2"`, query = that Friday's date.

   Two traps, both of which have to be handled or you edit the wrong person's report:
   - **Filter by folder.** `list_documents` searches the whole collection and the same title exists in several folders — "7 August 2026" is a real doc under Jun Phang, Zhen Wei *and* Khor. Keep only hits whose `parentDocumentId` is the person's folder id, or a subfolder of it (Khor has a nested *Weekly Update* folder, `5f083e2e-9b96-4b73-aaaf-350b5671bccc`).
   - **Accept the other spellings.** Titles are not uniform: `14 Aug 2026` alongside `14 August 2026`, and Khor's carry a `— CS Manager Weekly Report (Khor)` suffix. Match on the resolved Friday date, allowing an abbreviated month and a trailing suffix.

   Done when you have the document id and its current text in hand. If nothing under that person's folder matches that Friday, stop and tell the user to run `/weekly-report` first.

2. **Pull the Tracker.** Use the roster's Tracker id — always the number, never `assigned_to_id: "me"`, which silently reports on whoever owns the API token instead of the person asked for.
   - `list_issues` with `assigned_to_id: "<tracker id>"`, `status_id: "*"`, `sort: "updated_on:desc"` — keep issues touched inside the week.
   - `list_time_entries` with `user_id: <tracker id>`, `from`/`to` = the Mon/Fri dates.
   - `get_issue` on each in-week issue for description, journals and attachments.
   Done when every in-week issue and time entry is accounted for, with hours per day totalled.

   For a peer, `list_issues` can under-return — the token only sees projects it is a member of, while their time entries still show. Hours with no matching issue mean a visibility gap, not idle time; never retire a line from the doc just because the issue list did not return it.

3. **Diff against the doc.** Compare the tracker pull line by line against what the doc already claims. Done when every difference is named: issues the doc misses, statuses that moved, hours that changed, closures that landed, priorities from last week's SMART tables that are now finished or slipped.

4. **Ask before inventing.** Where the tracker is too thin to close a gap — no root-cause note, off-tracker work, next-week goals — ask with `AskUserQuestion` (multiple choice plus notes). Never invent a date, deadline or figure to make a section look complete: if neither the tracker nor the user supplies one, write the measure without it or ask. Done when every remaining gap is either answered or explicitly flagged in the doc.

5. **Rewrite the whole report, don't append to it.** An update is a fresh write of the full document, not a patch. Re-summarise the tracker pull together with what the doc already says, then decide what to **drop** as well as what to add — merge overlapping bullets, retire items the tracker no longer supports, replace weaker items with better-matched ones. Sections must stay within the template's counts (3–5 accomplishments, 2–4 learned, 2–4 challenges, 3–5 SMART goals); if a new item earns a place and the section is full, something older leaves. Done when no section has grown past its limit and every surviving line still earns its spot.

6. **Write it back.** `update_document` on the id from step 1, `text` = the full revised markdown. Keep the layout exactly as `weekly-report` defines it — read `../weekly-report/SKILL.md` for the info box (including the right `Report by:` name), headings, template hints and SMART tables. Done when the tool returns success.

7. **Report back.** Give the user the doc URL, name whose report it is, list what changed since the previous version, and name anything you asked about or left for them to top up.
