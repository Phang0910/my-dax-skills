---
name: update-ES-weekly-sheet
description: Fill a week's column in the ES Weekly Update team tracker (.xlsx) from the Tracker — split open issues across the status rows and write the per-ticket cell notes. Claude Code only; it edits the workbook on the user's own machine.
argument-hint: "[person] [week-ending date, e.g. 11 September 2026]"
disable-model-invocation: true
---

Update one week's column on one person's sheet in **ES Weekly Update_Customer Success Team.xlsx**. The counts go in the cells; the ticket list goes in an Excel **cell note** attached to each cell.

Defaults: the sheet belonging to **whoever runs the skill**, and the week **containing today**. An argument overrides either.

## Claude Code only — check this first

Writing an Excel cell note needs `officecli`, a binary on the user's own machine, plus shell and Python against their real filesystem. Chat and Cowork execute code in a sandbox on Anthropic's servers, which can reach neither. This skill cannot run there.

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
find "$HOME" -maxdepth 4 -name "ES Weekly Update_Customer Success Team.xlsx" -not -name '~$*' 2>/dev/null
```

Sub-second. Use `$HOME` (`/c/Users/<name>`), not `$USERPROFILE` — the latter is a Windows path and yields mixed separators like `C:\Users\x/DAXONET GROUP/...`.

Search rather than assemble a path, because three things vary and a wrong guess makes the skill claim "not synced" and push someone through setup they already did:

- **the username**, obviously;
- **which root** — `⋯ → Sync` gives `~/DAXONET GROUP/Enterprise Solution - 08 Resources/`, while *Add shortcut to OneDrive* gives `~/OneDrive - DAXONET GROUP/...`. Both are live and correct; accept whichever exists;
- **the sync location**, which OneDrive lets the user move, and which gets a numeric suffix if a folder of that name already exists.

Two hits to reject:

- **`ES Weekly Update_Customer Success Team.xlsx.url`, ~180 bytes** — someone ran *Add shortcut* on the **file** instead of syncing the **folder**. It has no content; treat it as not found and delete it once the real folder is synced.
- **A copy in `~/Downloads`** — not usable. It is detached from SharePoint: edits there reach nobody, and it goes stale the moment a colleague saves. If that is all there is, treat it as not found, run the setup below, and tell the user to delete the stray copy so it cannot be picked up later.

### If `find` comes back empty (first run on a machine)

The workbook must be **synced**, so the edit reaches SharePoint through OneDrive. This is one click — never a tour of SharePoint's settings.

Give exactly this, and nothing more:

> Open this link, click the **⋯** at the right of the toolbar, then **Sync**. Say yes to "This site is trying to open Microsoft OneDrive", and close the "We're syncing your files" box.
> https://daxonet0.sharepoint.com/sites/EnterpriseSolution/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FEnterpriseSolution%2FShared%20Documents%2FGeneral%2F08%20Resources

**Sync**, not *Add shortcut to OneDrive*. Both work, but Sync is what the team actually uses, and it lands the folder in its own root — `~/DAXONET GROUP/Enterprise Solution - 08 Resources/` — whereas a shortcut lands under `~/OneDrive - DAXONET GROUP/`. The `find` catches either, so never re-do a setup that already worked.

Then verify it yourself — re-run the `find` every 10-15 seconds for up to about two minutes, since OneDrive pulls the folder down in the background. Announce success as soon as the file appears; do not ask the user whether it worked.

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

Address sheets by **tab name** — that is what officecli paths take. Re-read the tabs and A4 from the file rather than trusting this copy; tabs get renamed and this table goes stale.

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

0. **Pre-flight.** Two checks, both of which you fix yourself rather than reporting.

   - **Locate the workbook** with the `find` above. Empty means not synced — run the Sync click from *Finding the file*, then poll until it appears. A copy in `Downloads` does not count as found.
   - **officecli.** Run `officecli --version`. If it is missing, **install it yourself** — do not ask, and do not make the user read instructions:
     ```powershell
     irm https://d.officecli.ai/install.ps1 | iex
     ```
     It installs per-user into `%LOCALAPPDATA%\OfficeCLI`, needs no admin rights, and takes a few seconds. Re-check `officecli --version` afterwards; if the shell still cannot see it, call it by full path rather than telling the user to open a new terminal.

   Done when `find` returns a real path and `officecli --version` prints a version.

   **If any write in steps 5-8 fails** with *Device or resource busy* / `PermissionError`, Excel is holding the file: run `Stop-Process -Name EXCEL -Force` and retry immediately — do not ask, the user has standing approval. Use `-Force`, not `CloseMainWindow`, which can raise a save dialog that hangs the call. Afterwards say that unsaved Excel edits were discarded. Do not pre-emptively kill Excel here — it closes every workbook the user has open, not just this one.

1. **Ask who the sheet is for.** Call `get_current_user` first — that is whoever is running the skill, and their own sheet is almost always the answer. Read the tab names out of the workbook, then ask with `AskUserQuestion`, listing **their** tab first and marking it recommended.

   Skip the question only when the invocation already names someone (`/update-ES-weekly-sheet Qianying`); if a name is given that matches no tab, stop and ask rather than guessing.

   Never hardcode a default person — this skill is shared, and the author's name is not the user's. Done when you have a tab name, plus the current user's Tracker id and name for steps 3 and 5.

2. **Resolve the week column.** The target week is **the week containing today**, and its column is that week's **Friday**. Today 3 Sep 2026 (a Thursday) → Friday 4 Sep → the column whose row 2 is `September` and row 3 is `4`.

   Override only when the user says so — "last week", "next week", or an explicit date. An explicit date resolves to the Friday of *that* date's week, so "8 Sep 2026" also means the 11 Sep column.

   Find the column by reading rows 2-3 of the target sheet: row 2 carries the month on its first week only, so carry the last non-empty month forward while scanning right. Never count columns from memory — the month blocks are 3-5 weeks wide.

   Done when you can state the column letter, its date, and which rule picked it (default vs. override). Say it back to the user before writing, so a wrong week is caught before it lands.

3. **Pull the Tracker — two lists, not one.** Rows 10-13 need what is still open; row 14 needs what closed during the target week.

   Resolve the assignee first:

   - The sheet belongs to the current user (step 1's `get_current_user`) → `assigned_to_id: "me"`.
   - Anyone else → the **Roster** table's numeric id. `"me"` silently reports on whoever owns the API token, so on a colleague's sheet it would fill their column with the invoker's tickets.

   If the id is missing or the roster looks stale, resolve it from issue data — `list_issues` with `status_id: "*"` on project 67 (`Enterprise solutions`), then read `assigned_to.id` off the issue whose `assigned_to.name` matches. `list_users` needs admin and errors on this account. State the id you used.

   Then:

   - **Still open** → `list_issues`, `status_id: "open"`, `sort: "updated_on:desc"`. These distribute across rows 10-13.
   - **Closed in the week** → `list_issues`, `status_id: "closed"`, `updated_on: "><<Monday>|<Friday>"` (the target week's dates). This is row 14. The filter is on *updated*, not closed, so a ticket closed earlier and edited this week can slip in — check each one's journals before counting it.

   **Always exclude issue 19060 "General Tasks"** — it is a standing bucket, never counted.

   Done when both lists are in hand, 19060 is out, and the column's arithmetic holds:

   ```
   row 6 (Mon open) + row 7 (inbound) = row 15 (rows 10..13) + row 14 (closed)
   ```

   Row 6 is a formula carrying last week's remainder, so with the two counts known you can derive the inbound figure — `row 7 = row 15 + row 14 - row 6` — and offer it rather than asking. If it comes out negative, the sheet and the Tracker have diverged: say so and ask before writing.

   A colleague's list can under-return: the token only sees projects it belongs to. If the totals fall short, say so rather than writing a low number.

   **A past week cannot be reconstructed this way.** Tracker reports status *now*, so on a "last week" override the buckets reflect today, not that Friday. Say so and have the user give the numbers, rather than presenting today's split as history.

4. **Confirm every Subtask.** Redmine offers subtasks (`tracker.name == "Subtask"`) only *In Progress: Internal* and *In Progress: Customer* — there is no *In Review* status, so a subtask sitting in review still reads as in-progress.

   For each open Subtask, ask the user which of the four rows it really belongs to (In Progress Internal/Customer, In Review Internal/Customer). Non-subtask trackers — Support, Task, Bug — carry real statuses; use them as-is and do not ask.

   Done when every subtask has a user-confirmed row. **Do not write anything before this.**

5. **Write the cells and notes.** First take **two** copies of the live file, back to back, into the scratchpad: `work.xlsx` to edit and `baseline.xlsx` to compare against in step 7. Both must be taken now, not earlier — a copy from the start of the session is missing whatever colleagues saved since, and pushing it back would erase their work (see *Traps*).

   Edit `work.xlsx`:

   ```
   officecli set work.xlsx "/<Sheet>/<Col><Row>" --prop value=<n>
   officecli add work.xlsx "/<Sheet>" --type comment \
     --prop ref=<Col><Row> --prop author="<sheet owner>" --prop text="<note>"
   ```

   Use one call per change. `officecli batch` is all-or-nothing: one failed item silently discards the whole batch while still reporting the others as `"succeeded"`. If you do use it, assert `"failed": 0`.

   To clear a cell, use `xlsx_notes.py fix` (step 6) rather than setting an empty value. To delete a note, find its index with `officecli query work.xlsx comment` (match the `Sheet: ref` preview) and `officecli remove work.xlsx "/<Sheet>/comment[N]"`.

6. **Repair and validate.** officecli reorders `<ignoredErrors>` after `<legacyDrawing>`, which is invalid and makes Excel offer to "repair" the workbook. Always run:

   ```
   python xlsx_notes.py fix work.xlsx fixed.xlsx [<Sheet>!<cell-to-blank> ...]
   officecli validate fixed.xlsx       # must print "Validation passed"
   ```

   It also drops `xl/calcChain.xml`. That is fine — Excel recalculates on open, which is why row 15 still shows a stale cached value on disk. **Never** hand-patch `calcPr fullCalcOnLoad`: the obvious regex strips the `x:` namespace prefix and corrupts `workbook.xml`.

   Done when validate is clean.

7. **Verify before copying over.** Compare the fixed copy against **`baseline.xlsx` from step 5** — not against any earlier backup, whose counts would differ for reasons that have nothing to do with your edit. Count **by local XML tag name**, never with a text grep:

   ```python
   L = lambda t: t.split('}')[-1]
   # count elements where L(tag) == 'f'        -> formulas, must be unchanged
   # count elements where L(tag) == 'comment'  -> notes, must be old + new
   ```

   officecli writes namespaced `<x:f>` and `<x:comment>`, so `grep -o '<f>'` reports "all formulas destroyed" when nothing is wrong. That false alarm has already triggered one needless restore.

   Also confirm the other four people's sheets still hold their data (spot-check their row 6). Done when formulas match and only your notes were added.

8. **Write back and hand off.** `cp` the fixed copy onto the synced path — OneDrive uploads it from there.

   Then tell the user to **wait for the OneDrive tray icon to go green before opening Excel**. Opening mid-sync gives a "no access" error and invites the revert in *Traps*.

   Finish by listing the exact cells and notes written, so they can eyeball one and stop.

## Why officecli is mandatory

An Excel note is not one XML edit. It needs an entry in `xl/comments*.xml`, a matching `<v:shape>` in the sheet's VML drawing, and a consistent author table — get any of it wrong and the red triangle never appears. Reading notes needs none of that, so `xlsx_notes.py read` handles it with stdlib alone. Writing them does. Install officecli rather than hand-rolling the VML.

## Traps

- **The SharePoint connector cannot see cell notes.** `read_resource` returns values and formulas only. Read notes from the local file with `xlsx_notes.py read`. Never conclude "there are no notes" from a connector read.
- **OneDrive can silently revert your write.** Five people edit this workbook. If a colleague saves between your write and the upload, OneDrive cannot merge .xlsx — the server copy wins and your edit vanishes from disk. Symptom: the user opens the file and sees the change, closes it, reopens, and it is gone. Keep the write window short, and after the tray icon settles re-read the cells you wrote; if they are gone, re-apply the delta to the file as it now stands.
- **Therefore: always re-copy the live file immediately before editing.** Applying a staged full-file snapshot from earlier in the session overwrites colleagues' work that landed in between. Apply only the delta, on top of whatever is on disk now.
- **Sync may be missing from the SharePoint toolbar.** With only item-level access, `⋯` offers nothing but `Alert me`, and the parent folder throws "Unknown render failure". That is a permissions problem, not a workaround problem: the user needs adding to the Enterprise Solution site. Never substitute a downloaded copy — it is detached from SharePoint, so the edit reaches nobody.

- **This skill is used by the whole Customer Success team, not just its author.** Never mention another person's machine, username, or home directory, and never paste a `C:\Users\<someone-else>\...` path at the user. Resolve every path from `$HOME` on the machine you are running on.

- **Keep setup to one action.** Anything a teammate must do by hand is one sentence with one link and one button. No numbered SharePoint UI tours, no "tick this, then expand that". If a check fails, do the fix yourself where you can (officecli) and ask for the single click where you cannot (`⋯` → **Sync**). Then verify it worked rather than asking them to confirm.
