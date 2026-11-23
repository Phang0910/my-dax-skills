---
name: implement-ticket
description: Build the fix for a Tracker ticket in the project's D365FO custom code — check the analysis handover, get one approval for the plan (names and objects), create everything through the d365fo-dev CLI with DAXONET naming and a custom feature switch, check the project is complete, and hand over for testing. Use when the user asks to implement, build, develop or code the fix for a ticket, usually after analyse-ticket.
argument-hint: "[ticket no]"
---

# implement-ticket

Turn the chosen fix of an analysed ticket into a code change in the project's model. Stop when the
change is built (if asked) and handed over.

**Done when** the approved objects exist in the project, the completeness check passes, and the
user has the handover below. Check-in is always the user's. Deploy and build only when the user
asks.

Next skills: `uat-testing` (test cases and the UAT handover; planned, not built yet), then
`close-ticket`.

**Terms.** A **project** is a DAXONET client engagement (one row in the project map, for example
MTM). A **VS project** is the `.rnrproj` that groups this ticket's elements.

## What the user sees

The user is a developer or a functional consultant. Do the work quietly and show only:

1. **Checkpoint questions** — the plan approval (Step 3), a sign-in, a decision. All open
   questions in one message.
2. **The handover** in Step 9.

Keep to yourself: the code you read, CLI output, file paths you checked, each build line. Between
steps, write at most one short line on what you are doing now. Never mention your own tools or
mechanics (hooks, tool names, skill files).

## Hard rules

1. **All AOT changes go through the `d365fo-dev` CLI** (`d365fo-dev <group> --help` gives the
   exact flags; the `d365fo-dev` skill covers it). Never hand-edit AOT XML or `.rnrproj` files.
2. **Nothing is created before the user approves the plan** in Step 3.
3. **Never check in.** **Build** only when asked, with `--skip-cross-references`. **Deploy** only
   when asked, with `--dry-run` first: a module's first deploy ships the whole module.
4. **Never print or save credentials.** SQL JIT access goes through `Invoke-DevSql.ps1` (Step 8).
5. **Data fixes:** write the script and its rollback only. A person runs them.
6. No `&` or other XML-special characters in any name. Use `And`.

## Step 1 — Check the handover

Take the analysis from this conversation (`analyse-ticket`'s **For the developer** block). If
there is none, read the ticket with `mcp__claude_ai_Tracker__get_issue` and use the latest analysis
in its journals. If the ticket has no analysis, stop and suggest `/my-dax-skills:analyse-ticket`.

Check the handover against the current code before you build on it. This includes a colleague's
draft fix or analysis in the journals.

- The objects and methods it names exist, and do what it says.
- The cause still holds in the latest code (someone may have changed it since).
- The chosen option is clear enough to build.

**Done when** each point is checked. A problem → tell the user in one or two lines, with what you
found, before Step 3.

## Step 2 — Preconditions

1. **Project and code.** Find the project in the project map (`C:\D365Std\CLAUDE.md`, see
   `analyse-ticket`'s `reference/code-search.md`). Get the latest custom code the same way.
2. **Active config.** `d365fo-dev config show` must point at this project's environment. Wrong →
   `config list`, then `config use <name>` when one clearly matches; otherwise ask the user.
3. **Prefix.** The project map's **Prefix** column. `ask` or missing → ask the user in Step 3's
   message, and add it to the map.
4. **Model.** The project's DAXONET model for new work: the model where recent `<Prefix>` work
   is (for example `DAXSolutionsMTM`). Confirm it in Step 3.
5. **Initials.** From the Tracker **assignee**: the first letters of the given names
   ("Jun Phang Gan" → `JP`). Confirm in Step 3.
6. **Feature framework.** `DAXCustomFeatureManagement` is referenced by the model. Missing →
   stop and ask. Never fall back to standard features.

## Step 3 — Plan and approval (one message)

Work out every object to create or modify, with names from
[`reference/conventions.md`](reference/conventions.md). Then send one message and wait:

```
Plan for #<ticket> — approve before I create anything

Project:  <VS project name>   (model <Model>, initials <XX> from Tracker)
Feature:  <feature class>
Labels:   <label file, or "none needed">

| Action | Object | Type | Why |
|--------|--------|------|-----|
| Create | … | Class | Feature switch |
| Create | … | Class extension | <what it changes, functional words> |
| Modify | … | Table extension | <what it changes> |

DB sync needed: <yes (reason) / no>

→ Approve   → Change names or objects
```

- **Create** rows are new objects. **Modify** rows are existing objects the change touches.
- If the project's prefix is `ask`, add the question to this message.
- Changes → update the plan and send it again. Nothing is created until **Approve**.

## Step 4 — Create

With the CLI, in this order, each with `--model <Model> --project <path> --json`:

1. `project new <VS project>` (skip if it exists).
2. The feature class: `project item create custom-feature --name <…> --feature-number <ticket>
   --display-name "<English text>" --module <module>`.
3. The label file, when needed (`label-file` kind). Then check the `.rnrproj` has the label `.txt`
   entry (see Guardrails).
4. New elements and extensions. Then `project item add <kind>` for existing elements you modify.

## Step 5 — Write the code

Follow [`reference/conventions.md`](reference/conventions.md), "Code".

- Chain of Command: call `next` first, then check the feature:
  `<Feature>::instance().isEnabled()`.
- A fix to an earlier feature's code also checks that parent feature.
- Each new method or changed block gets a `/// <summary>` with "Tracker #<ticket> – <why>". No
  begin/end markers.
- New user-facing text is a label in the ticket's label file.

## Step 6 — Completeness check

Run the bundled check:

```
powershell -ExecutionPolicy Bypass -File "<this skill's folder>\scripts\Test-ProjectCompleteness.ps1" -Project "<.rnrproj path>" -ModelPath "<model folder>"
```

`<model folder>` holds the model's `AxClass`, `AxTable` … folders. The script checks that every
project element has its file, label files have their `.txt` entry, no project folder is empty,
and every new file is a pending add (TFVC) or not untracked (Git).

**Done when** it prints `OK`. Fix what it reports. Two things the CLI cannot do — the user does
them in Visual Studio: remove an empty project folder, and fix references after a rename.

## Step 7 — Build (only when asked)

`d365fo-dev project build <VS project> --skip-cross-references`. An error in another developer's
code is a **baseline error**: report it, do not fix it.

## Step 8 — Test in dev (after the user deploys, or asks you to)

1. **SQL JIT access.** Run `Invoke-DevSql.ps1 -Status -Env <env>` from
   `..\setup-mydaxskills\scripts\` (relative to this skill's folder). `<env>` is a short name such
   as `mtm-dev`. Nothing valid saved → send the user, in one message:
   - request SQL JIT access for the dev environment with the **Reader** role, and allow their IP;
   - then run this in their own PowerShell, and type done:
     `powershell -ExecutionPolicy Bypass -File "<full path>\Invoke-DevSql.ps1" -SaveConnection -Env <env>`
2. **Choose where to test:**
   - **Dev has the data** for the scenario (query it) → give the user the test in dev.
   - **Dev does not** → find or build the data in dev through the UI (steps with exact values),
     then the test.
   - **Nothing can be tested in dev** (for example an integration that only UAT can reach) → tell
     the user to check in and deploy to UAT, and test there with SQL Execute.
3. Every test has the feature **on** (the fix works) and **off** (the old behaviour stays).
4. At the end, suggest `Invoke-DevSql.ps1 -Clear -Env <env>`.

## Step 9 — Handover

```
**Built:**     <one sentence, functional words>
**Project:**   <VS project> (model <Model>)
**Status:**    <built / not built> · <deployed to dev / not deployed> · not checked in

### Changed objects
| Action | Object | Type |

### Before testing
1. Run once: <env URL>/?mi=SysClassRunner&cls=DAXCustomFeatureManagementSetup
2. Enable feature <ticket> – <display name> in DAX custom feature management.
3. DB sync: <needed / not needed>.

### Test result in dev        (when Step 8 ran)
Feature on: <result>. Feature off: <result>.

### Not done
Check-in · <deploy> · <UAT test>.
```

## Guardrails

- **Label files** are two files: `AxLabelFile\<Id>_<lang>.xml` and
  `LabelResources\<lang>\<Id>.<lang>.label.txt`. The CLI registers only the `.xml`. If the
  `.rnrproj` lacks `<Content Include="<Id>.<lang>.label.txt">`, tell the user to add the label
  file from Application Explorer (right-click → Add to project). Never say the `.txt` is hidden by
  design.
- **New labels are a pending edit on the `.txt`.** Warn the user: *Undo Pending Changes* or *Take
  Server Version* on that file, or saving an open label editor with old content, wipes them.
  Re-check the labels after a check-in or Get Latest.
- **Search a whole label file** when you check for a label, not only where it would sort.
- **After CLI edits**, the user reopens or refreshes the model in Visual Studio.
- **Names in source control:** TFVC needs the user's Visual Studio for check-in; you only check
  pending changes with `tf status` (read-only).
