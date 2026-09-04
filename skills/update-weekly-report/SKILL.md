---
name: update-weekly-report
description: Write or refresh a Customer Success Weekly Report in DAXONET Notes from the Tracker — creates the week's doc if it does not exist, otherwise rewrites the existing one, including any change the user asks for by name.
argument-hint: "[person] [Friday's date, e.g. 28 August 2026] [what to change]"
disable-model-invocation: true
---

Own the weekly report under **Customer Success Weekly Report / \<person\>** for one week: create it if that week has no doc yet, otherwise rewrite the one that is there.

Which of the two happens is never asked — it follows from whether the doc exists. Naming a week and a change ("in the 28 August report, add the Luvata RAF fix") is an update, not a new doc.

## Roster

Everything person-specific lives here.

| Say | Report by | Tracker id | Tracker display name | Notes folder id |
|---|---|---|---|---|
| `junphang`, `jp`, `jun`, `gan` | Gan Jun Phang | 194 | Jun Phang Gan | `5ba25e9d-ee37-47ee-bab0-d0b5336908ca` |
| `qianying`, `qy`, `chin` | Chin Qianying | 190 | Qianying Chin | `5df1ddcf-0f77-4dae-a91a-5260467734b2` |
| `zhenwei`, `zw`, `wong` | Wong Zhen Wei | 174 | Zhen Wei Wong | `d45ea1bf-20a0-46ba-868c-4147612f6b75` |
| `khor`, `wk`, `weakee` | Khor Wea Kee | 60 | WK Khor | `58f0f8f1-dcd4-41dc-a8a5-a632963300bb` |
| `jayshree`, `jay` | Jayshree | 89 | Jayshree A/P Samugam | `91c9b5ed-bfec-4c55-abd8-37d04c7160c9` |

All five folders sit in collection `e2fe74e9-2a93-4a8e-ae9f-901dc54457b2`. Match the argument case-insensitively against the aliases. If a name is given but matches nobody, stop and ask rather than guessing.

With no name given, the default is **whoever is running the skill** — call `get_current_user` and match its name against the `Tracker display name` column. This skill is shared across the team, so never fall back to a fixed person; if the current user matches no row, ask.

Khor's reports title as `<d month yyyy> — CS Manager Weekly Report (Khor)`, and some older ones sit in a nested *Weekly Update* subfolder (`5f083e2e-9b96-4b73-aaaf-350b5671bccc`). For Khor, append that suffix to the title and still create in the folder root.

## Steps

0. **Resolve the person.** From the roster above. Done when you have the row: report-by name, Tracker id, folder id.

1. **Fix the week, then look for the doc.** The report is titled after the **Friday** of the target week — default the Friday of the current week; "last week" or an explicit date overrides. Title format `d month yyyy` (`7 August 2026`) — no leading zero, month spelled out. Report Period is Mon–Fri of that week.

   Search with `list_documents`, `collectionId: "e2fe74e9-2a93-4a8e-ae9f-901dc54457b2"`, query = that Friday's date. Two traps, either of which edits the wrong person's report:

   - **Filter by folder.** The search covers the whole collection and the same title exists in several folders — "7 August 2026" is a real doc under Jun Phang, Zhen Wei *and* Khor. Keep only hits whose `parentDocumentId` is the person's folder id, or a subfolder of it.
   - **Accept the other spellings.** Titles are not uniform: `14 Aug 2026` alongside `14 August 2026`, and Khor's carry the suffix above. Match on the resolved Friday, allowing an abbreviated month and a trailing suffix.

   Done when you know which branch you are on: a matching doc under that person's folder means **update** — hold its id and current text; nothing matching means **create**.

2. **Pull the Tracker.** Use the roster's Tracker id — always the number, never `assigned_to_id: "me"`, which silently reports on whoever owns the API token instead of the person asked for.
   - `list_issues` with `assigned_to_id: "<tracker id>"`, `status_id: "*"`, `sort: "updated_on:desc"` — keep issues touched inside the week.
   - `list_time_entries` with `user_id: <tracker id>`, `from`/`to` = the Mon/Fri dates — the load-bearing signal for what was actually worked and for how long.
   - `get_issue` on each in-week issue for description, journals and attachments.

   Done when every in-week issue and time entry is accounted for, with hours per day totalled.

   For a peer, `list_issues` can under-return — the token only sees projects it is a member of, while their time entries still show. Hours with no matching issue mean a visibility gap, not idle time: say so rather than writing the week up as quiet, and never retire a line from an existing doc just because the issue list did not return it.

3. **On the update branch, diff against the doc.** Compare the tracker pull line by line against what the doc already claims. Done when every difference is named: issues the doc misses, statuses that moved, hours that changed, closures that landed, and priorities from last week's SMART tables that are now finished or slipped.

   If the user named specific changes, treat those as required edits on top of the refresh — apply them, and say so when reporting back.

4. **Ask before inventing.** Where the tracker is too thin to fill a section — no root-cause note, no closure, off-tracker work, unstated next-week goals — ask with `AskUserQuestion` (multiple choice plus notes). Never fabricate accomplishments, and never invent a date, deadline or figure to make a section look complete: write the measure without it, or ask. Say plainly in the report when a week is light or only partly executed. Done when every remaining gap is either answered or explicitly flagged in the doc.

5. **Write the whole report, never a patch.** On both branches the output is the full document in the layout below.

   Updating is a fresh write of the whole thing, not an append: re-summarise the tracker pull together with what the doc already says, then decide what to **drop** as well as what to add — merge overlapping bullets, retire items the tracker no longer supports, replace weaker items with better-matched ones. Sections stay within the template's counts (3–5 accomplishments, 2–4 learned, 2–4 challenges, 3–5 SMART goals); if a new item earns a place and the section is full, something older leaves.

   Done when no section has grown past its limit and every surviving line still earns its spot.

6. **Save it.**
   - **Update** — `update_document` on the id from step 1, `text` = the full revised markdown.
   - **Create** — `create_document` with `parentDocumentId` = the roster's folder id, `title` from step 1, `text` = the report.

   Done when the tool returns success.

7. **Report back.** Give the user the doc URL, name whose report it is, say whether it was created or rewritten, list what changed if it was rewritten, and name anything you asked about or left for them to top up.

## Layout

Follow the team template exactly — the five folders sit side by side in the same collection and all use it.

```
:::info
Project: Customer Success Weekly Report

Report by: <roster "Report by" name>

Report date: <Friday, d month yyyy>

Report Period: Mon <d mmm yyyy> - Fri <d mmm yyyy>

Scope: <clients / projects touched>
:::
```

Blank lines between the info-box fields are load-bearing — without them the importer joins all five into one paragraph.

Report Period is the plain Mon–Fri week and nothing else — no "(actuals logged to …)" or similar qualifier, even when the week is only partly executed. Say that in the body instead, where it belongs.

Then, in order, each as `## **Heading**` followed by its `#### **[...]**` template hint kept verbatim:

- **Execution Summary** — one prose paragraph, 3–5 sentences, outcomes and figures rather than a task list.
- **Key Accomplishments** — bullets, each opening with a bold `Client #issue — what landed.` lead-in, quantified where the tracker supports it.
- **What Was Learned** — bullets with bold lead-ins; insight plus what to carry forward.
- **Challenges and Things to Avoid** — bullets prefixed 🔴 / 🟡 / 🟢 by severity, each closing with an italic `*Action:*` clause naming the concrete next move.
- **Next Week's Priorities** — one SMART table per goal (see below).
- **Additional Notes/Attachments** — tracker references with status/hours, attached documents, affected records (PO, invoice, item numbers).

### SMART tables

Per goal: a blank line, then the bold goal label, then the table.

```
**Goal 1 — <goal>**

| Criteria | Detail |
|---|---|
| **S**pecific | … |
| **M**easurable | … |
| **A**chievable | … |
| **R**elevant | … |
| **T**ime-bound | … |
```

The blank line above each goal label is deliberate breathing room. Full words with the first letter bold. The goal stays **above** the table — markdown has no colspan, so a merged full-width header row is not reachable through the API.
