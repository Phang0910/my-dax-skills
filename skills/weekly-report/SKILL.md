---
name: weekly-report
description: Draft this week's Customer Success Weekly Report in DAXONET Notes from the Tracker.
argument-hint: "[your name] [Friday's date of the week, e.g. 28 August 2026]"
disable-model-invocation: true
---

Create a new doc under **Customer Success Weekly Report / \<person\>** and write that person's weekly report into it, sourced from the Tracker.

## Roster

Everything person-specific lives here. Sibling skill `update-weekly-report` reads this table too — keep it the only copy.

| Say | Report by | Tracker id | Tracker display name | Notes folder id |
|---|---|---|---|---|
| `junphang`, `jp`, `jun`, `gan` | Gan Jun Phang | 194 | Jun Phang Gan | `5ba25e9d-ee37-47ee-bab0-d0b5336908ca` |
| `qianying`, `qy`, `chin` | Chin Qianying | 190 | Qianying Chin | `5df1ddcf-0f77-4dae-a91a-5260467734b2` |
| `zhenwei`, `zw`, `wong` | Wong Zhen Wei | 174 | Zhen Wei Wong | `d45ea1bf-20a0-46ba-868c-4147612f6b75` |
| `khor`, `wk`, `weakee` | Khor Wea Kee | 60 | WK Khor | `58f0f8f1-dcd4-41dc-a8a5-a632963300bb` |
| `jayshree`, `jay` | Jayshree | 89 | Jayshree A/P Samugam | `91c9b5ed-bfec-4c55-abd8-37d04c7160c9` |

All five folders sit in collection `e2fe74e9-2a93-4a8e-ae9f-901dc54457b2`. Match the argument case-insensitively against the aliases. If the name is given but matches nobody, stop and ask rather than guessing.

With no name given, the default is **whoever is running the skill** — call `get_current_user` and match its name against the `Tracker display name` column. This skill is shared across the team, so never fall back to a fixed person; if the current user matches no row, ask.

Khor's own last two reports title as `<d month yyyy> — CS Manager Weekly Report (Khor)` and some of his older ones sit in a nested *Weekly Update* subfolder — for Khor, append that suffix to the title and still create in the folder root.

## Steps

1. **Fix the person and the week.** Resolve the person from the roster. The report is titled after the **Friday** of the target week (default: the Friday of the current week; an argument like "last week" or an explicit date overrides). Title format `d month yyyy` — `7 August 2026`, no leading zero, month spelled out. Report Period is Mon–Fri of that week. Done when you have the roster row, the Friday date and the Mon/Fri boundaries as absolute dates.

2. **Pull the Tracker.** Use the roster's Tracker id — always the number, never `assigned_to_id: "me"`, which silently reports on whoever owns the API token instead of the person asked for.
   - `list_issues` with `assigned_to_id: "<tracker id>"`, `status_id: "*"`, `sort: "updated_on:desc"` — keep issues touched inside the week.
   - `list_time_entries` with `user_id: <tracker id>`, `from`/`to` = the Mon/Fri dates — this is the load-bearing signal for what was actually worked and for how long.
   - `get_issue` on each in-week issue for description, journals and attachments.
   Done when every in-week issue and time entry is accounted for, with hours per day totalled.

   For a peer, `list_issues` can under-return — the token only sees projects it is a member of, while their time entries still show. If the issue list looks thin against the logged hours, that is a visibility gap, not a light week: say so instead of writing the week up as quiet.

3. **Ask before inventing.** Where the tracker is too thin to fill a section — no root-cause note, no closure, off-tracker work, unstated next-week goals — ask with `AskUserQuestion` (multiple choice plus notes). Never fabricate accomplishments, and say plainly in the report when a week is light or only partly executed. Done when every remaining gap is either answered or explicitly flagged in the doc.

4. **Create the doc.** `create_document` with `parentDocumentId` = the roster's folder id, `title` from step 1, and `text` in the layout below. Done when the tool returns a URL.

5. **Report back.** Give the user the doc URL, name whose report it is, and name anything you flagged, asked about, or left for them to top up.

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
