---
name: update-ES-weekly-sheet
description: Fill a week's column in the ES Weekly Update team tracker (.xlsx) from the Tracker — split open issues across the status rows, balance the column's tally, and write the per-ticket cell notes. Claude Code only; it edits the workbook on the user's own machine.
argument-hint: "[person] [week-ending date, e.g. 11 September 2026]"
disable-model-invocation: true
---

Update one week's column on one person's sheet in **ES Weekly Update_Customer Success Team.xlsx**. The counts go in the cells; the ticket list goes in an Excel **cell note** attached to each cell.

Defaults: the sheet belonging to **whoever runs the skill**, and the week **containing today**. An argument overrides either.

## Claude Code only — check this first

Writing goes through the user's own **desktop Excel** (PowerShell driving it over COM), and reading last week's notes needs Python against their real filesystem. Chat and Cowork execute code in a sandbox on Anthropic's servers, which can reach neither. This skill cannot run there.

Before anything else:

```bash
ls "$HOME" >/dev/null 2>&1 && echo shell-ok
```

If there is no shell tool at all, or it cannot see the user's home directory, stop and say:

> This one needs Claude Code — it edits the workbook on your own machine, which Chat and Cowork can't reach. Open Claude Code and run `/update-ES-weekly-sheet` there.

Then stop. Do not offer a partial route: the SharePoint connector can read the sheet's numbers but can neither read nor write its cell notes, so there is nothing useful to do without a shell.

## Finding the file

The workbook lives in SharePoint at `/sites/EnterpriseSolution/Shared Documents/General/08 Resources/`. **Never hardcode a local path.** Locate it:

```bash
ls -1 "$HOME"/*/*"08 Resources"/"ES Weekly Update_Customer Success Team.xlsx" "$HOME"/*/*/*"08 Resources"/"ES Weekly Update_Customer Success Team.xlsx" 2>/dev/null
```

A glob, not `find`: output-rewriting hooks (RTK) have turned a working `find` into empty output on a machine where the file was synced. No `||` chaining either, for the same reason.

The tidiest way to run this is with Claude Code **opened in the synced folder itself**, which puts the workbook in the session's own directory and settles any question of what it can reach. Worth mentioning once the user is set up; the lookup covers them either way.

Sub-second. Use `$HOME` (`/c/Users/<name>`), not `$USERPROFILE` — the latter is a Windows path and yields mixed separators like `C:\Users\x/DAXONET GROUP/...`.

Search rather than assemble a path, because three things vary and a wrong guess makes the skill claim "not synced" and push someone through setup they already did:

- **the username**, obviously;
- **which root** — `⋯ → Sync` gives `~/DAXONET GROUP/Enterprise Solution - 08 Resources/`, while *Add shortcut to OneDrive* gives `~/OneDrive - DAXONET GROUP/...`. Both are live and correct; accept whichever exists;
- **the sync location**, which OneDrive lets the user move, and which gets a numeric suffix if a folder of that name already exists.

Two hits to reject:

- **`ES Weekly Update_Customer Success Team.xlsx.url`, ~180 bytes** — someone ran *Add shortcut* on the **file** instead of syncing the **folder**. It has no content; treat it as not found and delete it once the real folder is synced.
- **A copy in `~/Downloads`** — not usable. It is detached from SharePoint: edits there reach nobody, and it goes stale the moment a colleague saves. If that is all there is, treat it as not found, run the setup below, and tell the user to delete the stray copy so it cannot be picked up later.

### If the lookup comes back empty (first run on a machine)

The workbook must be **synced**, so the edit reaches SharePoint through OneDrive. This is one click — never a tour of SharePoint's settings.

Give exactly this, and nothing more:

> Open this link, click the **⋯** at the right of the toolbar, then **Sync**. Say yes to "This site is trying to open Microsoft OneDrive", and close the "We're syncing your files" box.
> https://daxonet0.sharepoint.com/sites/EnterpriseSolution/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FEnterpriseSolution%2FShared%20Documents%2FGeneral%2F08%20Resources

**Sync**, not *Add shortcut to OneDrive*. Both work, but Sync is what the team actually uses, and it lands the folder in its own root — `~/DAXONET GROUP/Enterprise Solution - 08 Resources/` — whereas a shortcut lands under `~/OneDrive - DAXONET GROUP/`. The lookup catches either, so never re-do a setup that already worked.

Then verify it yourself — re-run the lookup every 10-15 seconds for up to about two minutes, since OneDrive pulls the folder down in the background. Announce success as soon as the file appears; do not ask the user whether it worked.

If it still has not appeared:

- **`⋯` only offers `Alert me` / `Manage my alerts`** — no Sync, no Add shortcut. They have item-level access to the file but not the library (opening the parent `General` folder confirms it: "Unknown render failure"). No amount of clicking will work. Tell them to ask an Enterprise Solution site owner to add them to the site, then re-run. Do not offer a download as a substitute.
- **The file is there but shows 0 bytes / "Available when online"** — Files On-Demand has not hydrated it yet. Reading it pulls the content down; just read it and carry on.

## Roster

One sheet per person, in workbook order. The Tracker id is who step 3 pulls issues for.

| Tab | Part | Name in A4 | Tracker id |
|---|---|---|---|
| `Khor` | `sheet1.xml` | Dimitri Ong | **ask** — see below |
| `Jayshree` | `sheet2.xml` | Jayshree | 89 |
| `Zhen Wei` | `sheet3.xml` | Zhen Wei | 174 |
| `Qianying` | `sheet4.xml` | Qianying | 190 |
| `Jun Phang` | `sheet5.xml` | Jun Phang | 194 |

Address sheets by **tab name** — that is what `es_write.ps1`'s `sheet` takes. Re-read the tabs and A4 from the file rather than trusting this copy; tabs get renamed and this table goes stale.

**The `Khor` tab is unresolved.** Its A4 reads `Dimitri Ong`, and Tracker holds both as separate people — `WK Khor` is 60, `Dimitri Ong` is 79. One of the two labels is wrong, and picking the wrong id fills a manager's column with someone else's tickets. If that tab is chosen, ask which person it is and use the id they name; never infer it from the tab name or from A4.

This roster is the ES **workbook's**, and it is not the same set as the roster in `../update-weekly-report/SKILL.md` — that one covers Khor Wea Kee and has no Dimitri. Keep the ids consistent with it where the same person appears in both.

## Sheet layout

Row 2 = month, row 3 = week-ending day. Columns run `B` (10 Apr) → `AM` (25 Dec); derive the column by reading rows 2-3, never by counting from memory.

| Row | Meaning | Writable? |
|---|---|---|
| 6 | (A1) Open as on Monday | **no** — formula, carries the previous week's row 15 |
| 7 | (A2) Inbound this week | yes |
| 10 | (B1) In Progress – Internal | yes |
| 11 | (B2) In Progress – Customer | yes |
| 12 | (B3) In Review – Internal | yes |
| 13 | (B4) In Review – Customer | yes |
| 14 | (B5) Closed This Week | yes |
| 15 | Remaining = SUM(10:13) | **no** — formula |
| 17 | (C1) Open next week | **no** — formula |
| 18 | (C2) Close next week | yes — a commitment number, only the user sets it |
| 20-22 | (D1-D3) Billable mandays | yes |

Rows 7 and 10-14 are the only rows this skill writes without being asked. Leave a row **blank**, not `0`, when it has nothing — that is the house style.

## Note format

The author is the sheet's owner, and the text repeats that name as its first line, then one ticket per entry separated by a **blank line**. Read the exact spelling off an existing note on that sheet — on Jun Phang's it is `Gan Jun Phang`, not the tab name:

```
Gan Jun Phang:
19317 [UAS] - Database storage reduction

19093 [Nichias] - Create batch job for stuck PR
```

`<id> [Customer] - <short description>`. Reuse the wording already used for that ticket in earlier weeks, from `context`'s *known wording* list, rather than pasting the Tracker subject verbatim.

## Steps

**Fast path — about six tool calls end to end.** Batch independent calls in one message:

1. **One shell call** for the lookup, a scratchpad copy, and `context` (step 0), sent **with** `get_current_user` (step 1);
2. **both `list_issues` calls together** (step 3);
3. **one `AskUserQuestion`** carrying every subtask (step 4; up to 4 per call);
4. **one `es_write.ps1` run** (step 6), whose read-back is the check.

Do not write ad-hoc scripts to read the sheet. `context` already prints everything steps 1-5 need.

0. **Pre-flight and context, in one shell call.** Lookup, copy, read:

   ```bash
   F=$(ls -1 "$HOME"/*/*"08 Resources"/"ES Weekly Update_Customer Success Team.xlsx" "$HOME"/*/*/*"08 Resources"/"ES Weekly Update_Customer Success Team.xlsx" 2>/dev/null | head -1)
   cp "$F" "<scratchpad>/es.xlsx" && py -I "<skill dir>/xlsx_notes.py" context "<scratchpad>/es.xlsx" "<tab>" [YYYY-MM-DD]
   ```

   - **Read a copy, never the synced file itself.** While OneDrive is syncing, a direct open fails with `PermissionError`; `cp` still works.
   - **`py`, not `python`.** `python` may be the Microsoft Store stub that only prints "Python was not found". Fall back to `python` only if `py` is missing.
   - **Empty lookup** means not synced: run the Sync click from *Finding the file*, then poll. A copy in `Downloads` does not count as found.

   `context` prints:
   - the tabs and A4;
   - the target column for the date (default today), with last week's column beside it for rows 6-18;
   - both columns' notes;
   - the latest wording for every ticket noted in the last 8 weeks.

   If the tab is unknown it lists the real ones. Desktop Excel needs no check here; step 6's script finds or opens it.

   **Never kill Excel and never write the synced file directly.** Excel is the write path; the file on disk is only read.

1. **Ask who the sheet is for.** `get_current_user` is whoever is running the skill, and their own sheet is almost always the answer. Ask with `AskUserQuestion` over the tabs `context` printed, listing **their** tab first and marking it recommended.

   Skip the question only when the invocation already names someone (`/update-ES-weekly-sheet Qianying`); if a name is given that matches no tab, stop and ask rather than guessing.

   Never hardcode a default person — this skill is shared, and the author's name is not the user's. Done when you have a tab name, plus the current user's Tracker id and name for steps 3 and 5.

2. **Resolve the week column.** The target week is **the week containing today**, and its column is that week's **Friday**. Today 3 Sep 2026 (a Thursday) → Friday 4 Sep → the column whose row 2 is `September` and row 3 is `4`.

   Override only when the user says so — "last week", "next week", or an explicit date. An explicit date resolves to the Friday of *that* date's week, so "8 Sep 2026" also means the 11 Sep column.

   `context` resolves this from rows 2-3, carrying row 2's month forward, since it only appears on a block's first week. Pass the override date as its last argument. Never count columns from memory — the month blocks are 3-5 weeks wide.

   Done when you can state the column letter, its date, and which rule picked it (default vs. override). Say it back to the user before writing, so a wrong week is caught before it lands.

3. **Pull the Tracker — two lists, not one.** Rows 10-13 need what is still open; row 14 needs what closed during the target week.

   Resolve the assignee first:

   - The sheet belongs to the current user (step 1's `get_current_user`) → `assigned_to_id: "me"`.
   - Anyone else → the **Roster** table's numeric id. `"me"` silently reports on whoever owns the API token, so on a colleague's sheet it would fill their column with the invoker's tickets.

   If the id is missing or the roster looks stale, resolve it from issue data — `list_issues` with `status_id: "*"` on project 67 (`Enterprise solutions`), then read `assigned_to.id` off the issue whose `assigned_to.name` matches. `list_users` needs admin and errors on this account. State the id you used.

   Then:

   - **Still open** → `list_issues`, `status_id: "open"`, `sort: "updated_on:desc"`. These distribute across rows 10-13.
   - **Closed in the week** → `list_issues`, `status_id: "closed"`, `sort: "updated_on:desc"`, `limit: 15`, then keep those updated since **last Friday**. Do not pass `updated_on`: the connector ignores it and returns every closed issue ever. This is row 14. *Updated* is not *closed*, so a ticket closed earlier and edited this week can slip in. Any that `context` shows in last week's row 10-13 notes is a genuine closure; check journals only for the rest.

   **Always exclude issue 19060 "General Tasks"** — it is a standing bucket, never counted.

   Done when both lists are in hand and 19060 is out. Step 5 balances them.

   A colleague's list can under-return: the token only sees projects it belongs to. If the totals fall short, say so rather than writing a low number.

   **A past week cannot be reconstructed this way.** Tracker reports status *now*, so on a "last week" override the buckets reflect today, not that Friday. Say so and have the user give the numbers, rather than presenting today's split as history.

4. **Confirm every Subtask.** Redmine offers subtasks (`tracker.name == "Subtask"`) only *In Progress: Internal* and *In Progress: Customer* — there is no *In Review* status, so a subtask sitting in review still reads as in-progress.

   For each open Subtask, ask the user which of the four rows it really belongs to (In Progress Internal/Customer, In Review Internal/Customer). Non-subtask trackers — Support, Task, Bug — carry real statuses; use them as-is and do not ask.

   Done when every subtask has a user-confirmed row. **Do not write anything before this.**

5. **Tally.** The column's arithmetic is a gate, not a sanity check:

   ```
   row 6 (open Monday) + row 7 (inbound) = rows 10-13 (still open) + row 14 (closed this week)
   ```

   Only a **closure** takes a ticket out of the total — nothing else reduces it. Row 6 is a formula carrying last week's remainder, so with the two Tracker counts in hand the inbound figure is derived, never asked for:

   ```
   row 7 = (rows 10..13) + row 14 - row 6
   ```

   It must come out **>= 0**. A negative row 7 means the B side is short: tickets that should still be counted landed in neither Tracker list. Track them down yourself rather than handing the discrepancy back — two causes, both recoverable:

   - **Closed on last Friday.** A ticket closed on the previous week's Friday falls outside that week's `updated_on` window and inside nobody's. Count it as **closed in the current week** (row 14), not the previous one.
   - **Untouched for a week.** Usually a Subtask. It is still open, but nothing moved it, so it dropped out of the pull. It stays in its row 10-13 bucket — quiet is not closed.

   Find them in **last week's cell notes**, which `context` already printed by id. Every ticket named there must show up this week in a row 10-13 bucket, in row 14, or as a closure you can point at in an earlier week. What is left over is the leak; put it back in the row it belongs to.

   **19060 "General Tasks" is out on both sides** — it never updates and never counts.

   Done when the tally balances with a non-negative row 7, or you can name the ticket that breaks it and have said so before writing.

6. **Write through Excel.** Put the column's changes in a spec file (UTF-8 JSON) in the scratchpad: the derived inbound in **row 7**, the counts in rows 10-14, and a note per row that has tickets. `null` blanks a cell or removes its note; a row left out is not touched.

   ```json
   {"sheet": "Jun Phang", "col": "AC", "day": 16,
    "values": {"7": 3, "10": 3, "11": 1, "12": 1, "13": null, "14": 5},
    "notes":  {"10": "Gan Jun Phang:\n19829 [MMM] - User access checklist\n\n19816 [VSTECS] - ...",
               "13": null}}
   ```

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File es_write.ps1 <spec.json>
   ```

   The script attaches to the running Excel, or opens the workbook from its SharePoint URL, and writes into the **live, co-authored** workbook. It refuses, and writes nothing, unless the workbook is editable with **AutoSave on**, and unless row 3 of `col` reads `day`, which catches a wrong week. It prints each written row back with its note's ticket count.

   If it refuses:
   - **AutoSave off / read-only** — the workbook was opened from a local or downloaded copy, or offline. Ask the user to close it and re-run; the script then opens it from SharePoint itself.
   - **`Call was rejected by callee` / `0x800AC472`** — a cell is in edit mode or a dialog is up in Excel. Ask the user to press Esc, then re-run. The writes are idempotent.

   The note's author is Excel's user name (`Application.UserName`), which on the user's own sheet is the owner. On a colleague's sheet it is the invoker; the text's first line still names the owner.

7. **Verify.** Re-check the **tally** on the values you wrote, adding them up yourself: `row 6 + row 7` must equal `rows 10+11+12+13 + row 14`.

   The script's read-back comes from the live co-authored workbook, so it is the check. Do not wait for the upload or poll SharePoint. Co-authoring syncs the changed cells in the background, the user can keep working in Excel throughout, and there is no read-only window to guard against.

   Finish by listing the exact cells and notes written, so they can eyeball one and stop.

## Why write through Excel

Five people edit this workbook. Replacing the `.xlsx` on the synced path made OneDrive re-upload the whole file. It cannot merge `.xlsx`, so a colleague's save during that upload silently dropped one side, and opening Excel before it finished latched the window read-only. Writing through a co-authoring Excel session sends only the changed cells and merges colleagues' concurrent edits, the same as a person typing. Excel also writes notes correctly (comments part, VML shape, author table), so nothing needs repairing afterwards.

## Traps

- **The SharePoint connector cannot see cell notes.** `read_resource` returns values and formulas only. Read notes from the local file with `xlsx_notes.py read`. Never conclude "there are no notes" from a connector read.
- **Never copy a file onto the synced path.** That is the old write route, and both of its failures come back with it: a colleague's concurrent save silently reverts one side, and Excel opened mid-upload stays read-only. All writes go through `es_write.ps1`.
- **A note's `TextFrame.AutoSize` throws `0x800A03EC` on a co-authored workbook.** The script leaves note sizing alone for that reason; do not add it back.
- **Sync may be missing from the SharePoint toolbar.** With only item-level access, `⋯` offers nothing but `Alert me`, and the parent folder throws "Unknown render failure". That is a permissions problem, not a workaround problem: the user needs adding to the Enterprise Solution site. Never substitute a downloaded copy — it is detached from SharePoint, so the edit reaches nobody.

- **This skill is used by the whole Customer Success team, not just its author.** Never mention another person's machine, username, or home directory, and never paste a `C:\Users\<someone-else>\...` path at the user. Resolve every path from `$HOME` on the machine you are running on.

- **Keep setup to one action.** Anything a teammate must do by hand is one sentence with one link and one button. No numbered SharePoint UI tours, no "tick this, then expand that". If a check fails, do the fix yourself where you can and ask for the single click where you cannot (`⋯` → **Sync**). Then verify it worked rather than asking them to confirm.
