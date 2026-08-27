---
name: weekly-report
description: Draft this week's Customer Success Weekly Report in DAXONET Notes from the Tracker.
argument-hint: "[Friday's date of the week, e.g. 28 August 2026]"
disable-model-invocation: true
---

Create a new doc under **Customer Success Weekly Report / Jun Phang** and write Gan Jun Phang's weekly report into it, sourced from the Tracker.

## Steps

1. **Fix the week.** The report is titled after the **Friday** of the target week (default: the Friday of the current week; an argument like "last week" or an explicit date overrides). Title format `d month yyyy` — `7 August 2026`, no leading zero, month spelled out. Report Period is Mon–Fri of that week. Done when you have the Friday date and the Mon/Fri boundaries as absolute dates.

2. **Pull the Tracker.** Gan Jun Phang is Tracker user id **194**.
   - `list_issues` with `assigned_to_id: "me"`, `status_id: "*"`, `sort: "updated_on:desc"` — keep issues touched inside the week.
   - `list_time_entries` with `user_id: 194`, `from`/`to` = the Mon/Fri dates — this is the load-bearing signal for what was actually worked and for how long.
   - `get_issue` on each in-week issue for description, journals and attachments.
   Done when every in-week issue and time entry is accounted for, with hours per day totalled.

3. **Ask before inventing.** Where the tracker is too thin to fill a section — no root-cause note, no closure, off-tracker work, unstated next-week goals — ask with `AskUserQuestion` (multiple choice plus notes). Never fabricate accomplishments, and say plainly in the report when a week is light or only partly executed. Done when every remaining gap is either answered or explicitly flagged in the doc.

4. **Create the doc.** `create_document` with `parentDocumentId: "5ba25e9d-ee37-47ee-bab0-d0b5336908ca"` (the *Jun Phang* folder inside collection `e2fe74e9-2a93-4a8e-ae9f-901dc54457b2`), `title` from step 1, and `text` in the layout below. Done when the tool returns a URL.

5. **Report back.** Give the user the doc URL and name anything you flagged, asked about, or left for them to top up.

## Layout

Follow the team template exactly — peers' reports (Chin Qianying, Wong Zhen Wei, Khor Wea Kee) sit beside yours in the same collection.

```
:::info
Project: Customer Success Weekly Report

Report by: Gan Jun Phang

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
