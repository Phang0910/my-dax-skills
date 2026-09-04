---
name: update-ES-weekly-sheet
description: Fill a week's column in the ES Weekly Update team tracker (.xlsx) from the Tracker — split open issues across the status rows and write the per-ticket cell notes.
argument-hint: "[person] [week-ending date, e.g. 11 September 2026]"
disable-model-invocation: true
---

Update one week's column on one person's sheet in **ES Weekly Update_Customer Success Team.xlsx**. The counts go in the cells; the ticket list goes in an Excel **cell note** attached to each cell.

**Always ask who the sheet is for** — never assume. Default week is the one containing today.

## The file

`C:\Users\jp.gan\DAXONET GROUP\Enterprise Solution - 08 Resources\ES Weekly Update_Customer Success Team.xlsx`

A SharePoint team-site sync from `/sites/EnterpriseSolution/Shared Documents/General/08 Resources/`. Team-site syncs land under `C:\Users\jp.gan\DAXONET GROUP\`, **not** under `OneDrive - DAXONET GROUP\`.

## Roster

One sheet per person, in workbook order:

| Tab | Part | Name in A4 |
|---|---|---|
| `Khor` | `sheet1.xml` | **Dimitri Ong** — the tab name and the person disagree |
| `Jayshree` | `sheet2.xml` | Jayshree |
| `Zhen Wei` | `sheet3.xml` | Zhen Wei |
| `Qianying` | `sheet4.xml` | Qianying |
| `Jun Phang` | `sheet5.xml` | Jun Phang |

Address sheets by **tab name** — that is what officecli paths take. Re-read the table from the file rather than trusting this copy; tabs get renamed.

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

Rows 10-14 are the only rows this skill writes without being asked. Leave a row **blank**, not `0`, when it has nothing — that is the house style.

## Note format

The author is the sheet's owner, and the text repeats that name as its first line, then one ticket per entry separated by a **blank line**. Read the exact spelling off an existing note on that sheet — on Jun Phang's it is `Gan Jun Phang`, not the tab name:

```
Gan Jun Phang:
19317 [UAS] - Database storage reduction

19093 [Nichias] - Create batch job for stuck PR
```

`<id> [Customer] - <short description>`. Reuse the wording already used for that ticket in earlier weeks rather than pasting the Tracker subject verbatim.

## Steps

0. **Pre-flight.** All four, in order — each has burned a previous run.

   - **File present and synced.** `ls` the folder. A `.url` file of ~180 bytes means someone made a single-file shortcut instead of syncing the folder — only a *folder* shortcut/Sync gives real content. Stop and say so.
   - **`officecli --version`.** Required — see *Why officecli is mandatory* below. If missing, install it and re-check: `irm https://d.officecli.ai/install.ps1 | iex` (a new terminal may be needed).
   - **Excel not holding the file.** If a write later fails with *Device or resource busy* / `PermissionError`, run `Stop-Process -Name EXCEL -Force` immediately — do not ask permission, the user has standing approval. Use `-Force`, not `CloseMainWindow`, which can raise a save dialog that hangs the call. Say afterwards that unsaved Excel edits were discarded.
   - **Back up.** Copy the file to the scratchpad before touching it.

   Done when all four pass.

1. **Ask who the sheet is for.** Read the tab names out of the workbook, then ask with `AskUserQuestion` — one option per person, `Jun Phang` listed first as the likely answer. Skip the question only when the invocation already names someone (`/update-ES-weekly-sheet Qianying`); if a name is given that matches no tab, stop and ask rather than guessing.

   Do not silently default to Jun Phang. Done when you have a tab name.

2. **Resolve the week column.** The target week is **the week containing today**, and its column is that week's **Friday**. Today 3 Sep 2026 (a Thursday) → Friday 4 Sep → the column whose row 2 is `September` and row 3 is `4`.

   Override only when the user says so — "last week", "next week", or an explicit date. An explicit date resolves to the Friday of *that* date's week, so "8 Sep 2026" also means the 11 Sep column.

   Find the column by reading rows 2-3 of the target sheet: row 2 carries the month on its first week only, so carry the last non-empty month forward while scanning right. Never count columns from memory — the month blocks are 3-5 weeks wide.

   Done when you can state the column letter, its date, and which rule picked it (default vs. override). Say it back to the user before writing, so a wrong week is caught before it lands.

3. **Pull the Tracker.** `list_issues` with `status_id: "open"`, `sort: "updated_on:desc"`, and the assignee resolved as follows:

   - The invoker's own sheet (`Jun Phang`, id **194**) → `assigned_to_id: "me"`.
   - Anyone else → their **numeric id**. `"me"` silently reports on whoever owns the API token, so on a colleague's sheet it would fill their column with the invoker's tickets.

   `list_users` needs admin and will fail, so resolve a colleague's id from issue data instead: `list_issues` with `status_id: "*"` and a project they work on, then read `assigned_to.id` off the issue whose `assigned_to.name` matches. State the id you resolved before using it.

   **Always exclude issue 19060 "General Tasks"** — it is a standing bucket, never counted.

   A colleague's list can also under-return: the token only sees projects it belongs to. If the count falls short of row 6, say so rather than writing a low number.

   Done when the remaining open count equals the target column's row 6, which is the previous week's carry-over. If they disagree, say so and ask before writing — the sheet and the Tracker have diverged.

4. **Confirm every Subtask.** Redmine offers subtasks (`tracker.name == "Subtask"`) only *In Progress: Internal* and *In Progress: Customer* — there is no *In Review* status, so a subtask sitting in review still reads as in-progress.

   For each open Subtask, ask the user which of the four rows it really belongs to (In Progress Internal/Customer, In Review Internal/Customer). Non-subtask trackers — Support, Task, Bug — carry real statuses; use them as-is and do not ask.

   Done when every subtask has a user-confirmed row. **Do not write anything before this.**

5. **Write the cells and notes.** Copy the **current** file to the scratchpad and edit that copy — never re-push a snapshot taken earlier in the session (see *Traps*).

   ```
   officecli set <copy> "/<Sheet>/<Col><Row>" --prop value=<n>
   officecli add <copy> "/<Sheet>" --type comment \
     --prop ref=<Col><Row> --prop author="<sheet owner>" --prop text="<note>"
   ```

   Use one call per change. `officecli batch` is all-or-nothing: one failed item silently discards the whole batch while still reporting the others as `"succeeded"`. If you do use it, assert `"failed": 0`.

   To clear a cell, use `xlsx_notes.py fix` (step 6) rather than setting an empty value. To delete a note, find its index with `officecli query <file> comment` (match the `Sheet: ref` preview) and `officecli remove <file> "/<Sheet>/comment[N]"`.

6. **Repair and validate.** officecli reorders `<ignoredErrors>` after `<legacyDrawing>`, which is invalid and makes Excel offer to "repair" the workbook. Always run:

   ```
   python xlsx_notes.py fix <copy> <fixed> [<Sheet>!<cell-to-blank> ...]
   officecli validate <fixed>          # must print "Validation passed"
   ```

   It also drops `xl/calcChain.xml`. That is fine — Excel recalculates on open, which is why row 15 still shows a stale cached value on disk. **Never** hand-patch `calcPr fullCalcOnLoad`: the obvious regex strips the `x:` namespace prefix and corrupts `workbook.xml`.

   Done when validate is clean.

7. **Verify before copying over.** Compare the fixed copy against the backup, **by local XML tag name**, never with a text grep:

   ```python
   L = lambda t: t.split('}')[-1]
   # count elements where L(tag) == 'f'        -> formulas, must be unchanged
   # count elements where L(tag) == 'comment'  -> notes, must be old + new
   ```

   officecli writes namespaced `<x:f>` and `<x:comment>`, so `grep -o '<f>'` reports "all formulas destroyed" when nothing is wrong. That false alarm has already triggered one needless restore.

   Also confirm the other four people's sheets still hold their data (spot-check their row 6). Done when formulas match and only your notes were added.

8. **Copy over, then hand off.** `cp` the fixed copy onto the real path. Tell the user to **wait for the OneDrive tray icon to go green before opening Excel**, then confirm the cells. Opening mid-sync gives a "no access" error and invites the conflict in *Traps*.

## Why officecli is mandatory

An Excel note is not one XML edit. It needs an entry in `xl/comments*.xml`, a matching `<v:shape>` in the sheet's VML drawing, and a consistent author table — get any of it wrong and the red triangle never appears. Reading notes needs none of that, so `xlsx_notes.py read` handles it with stdlib alone. Writing them does. Install officecli rather than hand-rolling the VML.

## Traps

- **The SharePoint connector cannot see cell notes.** `read_resource` returns values and formulas only. Read notes from the local file with `xlsx_notes.py read`. Never conclude "there are no notes" from a connector read.
- **OneDrive can silently revert your write.** Five people edit this workbook. If a colleague saves between your write and the upload, OneDrive cannot merge .xlsx — the server copy wins and your edit vanishes from disk. Symptom: the user opens the file and sees the change, closes it, reopens, and it is gone. Mitigate by keeping the write window short and verifying afterwards.
- **Therefore: always re-copy the live file immediately before editing.** Applying a staged full-file snapshot from earlier in the session overwrites colleagues' work that landed in between. Apply only the delta, on top of whatever is on disk now.
- **Sync / Add-shortcut may be missing from the SharePoint toolbar.** If the user only has item-level access to the file, the parent folder throws "Unknown render failure" and the folder-level buttons never appear. They need library access first; downloading is the only fallback.
