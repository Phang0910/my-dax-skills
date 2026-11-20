---
name: analyse-ticket
description: Analyse a Tracker (Redmine) support ticket to its root cause — read the whole ticket including images, check known answers, the custom and standard D365FO code, and the real data in D365 through SQL Execute, then propose the fix, workaround or setup change. Use when the user asks to analyse, investigate, understand or find the root cause of a ticket.
argument-hint: "[ticket no]"
---

# analyse-ticket

Find out **why** a ticket happens, prove it, and propose what to do. Stop there.

**Done when** the root cause is at evidence level **reproduced** or **confirmed**, and the user has
the output below with the fix options. If the evidence stops at **supported**, the output says so
and gives the UAT test that would close the gap.

Building the fix, writing test cases, the customer email and closing the ticket are other skills
(`draft-email`, `draft-progress`, `close-ticket`, `kb-this`). Name the next one in the output.

**Terms.** A **project** is a DAXONET client engagement: one D365 environment and its code, one
row in the project map (for example MTM); match the ticket's Tracker project to it. A **D365
project** is a Projects module record (`ProjId`). A **legal entity** is the D365 company
(`DATAAREAID`, `cmp=`). The **customer** is the people at the project who raised the ticket.

## What the user sees

The user is a functional consultant. Do the work quietly, and show only two things:

1. **Checkpoint questions** — when you need a decision, a sign-in, a file or a query result. Put
   every open question in one message.
2. **The output** in Step 6.

Everything else is your working notes: hypothesis lists, evidence levels per finding, the
attachments you chose, the code you read, search results with no match, every query and its
result. Keep them to yourself. Between steps, write at most one short line on what you are doing
now. Do not repeat the ticket back to the user.

## Evidence levels (your notes)

Track one level for every finding. Raise a level only on evidence you have.

| Level | Evidence |
|---|---|
| **hypothesis** | A possible cause. Nothing checked yet. |
| **supported** | Code, setup or data agrees with it, and nothing checked disagrees. |
| **reproduced** | The symptom was produced on purpose in UAT by following the cause. |
| **confirmed** | Reproduced, and the opposite test (the cause removed) does not produce the symptom. |

- Colleague conclusions and counts in the ticket journals start at **hypothesis**. This includes
  claims about an environment's setup ("SUP has the feature off"). Check them before you build on
  them or use them in a decision. Look for false positives in their numbers (deleted lines, amounts
  moved to other lines, test records).
- For each time in the story (when something was posted, switched on, changed), know whether you
  read it from a record or worked it out. Many tables have no modified date. In the output, write a
  worked-out time as "probably" or "not recorded", never as a fact.

## Hard rules

1. The user signs in to every site. You wait, then read the page.
2. SQL is read-only: `SELECT` statements, run in **Select** mode.
3. Query **UAT first**. Query production only when a UAT query in this run showed UAT does not have
   the data **and** the user says yes for this ticket (Step 4).
4. Ask the user at checkpoints only, and put all open questions into one message.

## Step 1 — Read the whole ticket

Read the issue and every journal with `mcp__claude_ai_Tracker__get_issue`.

Then decide the route:

- **Text only** — no attachments and no `!image…!` markers: the connector output is the full ticket.
- **Images or files** — the ticket has attachments. **Open them in a browser before you read any
  code or run any query.** The connector gives no image content and no URL. Follow
  [`reference/read-tracker.md`](reference/read-tracker.md) for the browser and the URLs.

Choose the attachments you need to understand the ticket, from their filenames, sizes, dates and
the journal text around them, and read those. If a file you need has no preview, ask the user for
it.

**Done when** every journal and the attachments you need are read, and you know: what the
customer asks, the timeline, which claims are checked and which are not, and what the screenshots
show (with their date format and environment).

## Code readiness — checkpoint

Now the project is known. Find its standard and custom code with the first part of
[`reference/code-search.md`](reference/code-search.md).

- **Both found** → continue. Do not tell the user the folders.
- **A piece is missing** → stop and ask once. Name the missing piece and what the analysis loses:

  ```
  Code not available: <missing piece>.
  Without code, the analysis cannot check customizations or verify SQL field names.

  → Set up first (recommended) — run /my-dax-skills:setup-mydaxskills in this conversation, then run this skill again
  → Continue without code
  ```

  Setup reads the project from this conversation's ticket, so the user types the command only.

  *Set up first* → stop here. *Continue without code* → the rest of the run is **without code**:
  every step marked "Without code" below takes its fallback.

## Step 2 — Look for a known answer

Run these before deep analysis. They are fast and often end the investigation.

- **DAXONET Notes** — search past KB articles for the symptom, error text and project:
  `mcp__claude_ai_DAXONET_Notes__list_documents(query: "...")`. Large results go to a file; read
  the file.
- **Microsoft Learn** — standard behaviour and setup: `mcp__claude_ai_Microsoft_Learn__microsoft_docs_search`.
- **Known Microsoft bugs** — if the symptom looks like a product defect, ask the user to search the
  LCS Issue search, or search it yourself if an LCS session is open.

**Done when** each source was searched with the symptom and the error text. Keep the link of any
match that explains the ticket; it goes in the output.

## Step 3 — Form hypotheses and read the code

List every candidate cause at level **hypothesis**, each with the test that would prove or remove
it.

Read the code on the business path of the symptom: the project's extensions first, then the
standard methods they extend or call. Follow [`reference/code-search.md`](reference/code-search.md).

Ask the user early for screenshots of the setup pages on that path (parameters, policies, the
dialog the user saw). One setup screenshot can replace many queries.

**Done when** you know what every customization on the path changes, and every hypothesis has its
test.

**Without code:** build the hypotheses from the ticket, Step 2 and the setup screenshots. Done
when every hypothesis has its test. The output says "customizations not checked".

## Step 4 — Check the real data in D365

Use SQL Execute to see the records behind the ticket. Follow [`reference/sql-execute.md`](reference/sql-execute.md).

1. **Choose the environment.** Query the ticket's own documents (PO, PR, voucher numbers) in UAT.
   "UAT does not have the data" must come from that UAT query in this run, not from a journal or a
   colleague.
   - Found → work in UAT.
   - Not found → query the setup the cause needs (feature flags, parameters, integration setup) in
     UAT too. Then tell the user in one line that UAT does not have the records, and whether its
     setup can produce the case. Ask:
     - *Reproduce in UAT* — recommended when the UAT setup can produce the case, as it is or after a
       setup change the user can make.
     - *Check in production (read-only)*.
2. **Choose who runs the SQL.** Ask once per ticket:
   - *You run it* — the user opens SQL Execute, runs each query, and pastes the result.
   - *I run it* — the user gives the SQL Execute URL and signs in. You run it in Claude in Chrome,
     or in the built-in browser if Chrome is not connected.
3. Run one discriminating query at a time. After each result, update your evidence levels. When you
   run the queries, do not show each result to the user.

**Without code:** verify table and field names with the fallback in `reference/sql-execute.md`.

**Done when** every hypothesis is **supported** or removed by a result.

## Step 5 — Reproduce the cause

When data and code support one cause, prove it in UAT. Build the steps from the project's code
(mandatory fields, workflow stages, lookups) and from a known-good record of the same type (copy
its dimensions and values). Give one test that produces the symptom and one opposite test that does
not.

**Without code:** take the values from a known-good record of the same type in UAT. Before you
write the steps, ask the user once which custom mandatory fields and workflow stages that document
type has.

**Done when** the symptom is **reproduced**, and **confirmed** if the opposite test was run.
If the user cannot run it now, stop at **supported**. The output then holds the UAT test, without
the user asking for it: record IDs checked in UAT, menu path, clicks and field values in order, and
the expected result of both tests.

## Step 6 — Propose actions and write the output

List every realistic action for yourself: code fix, workaround, setup change, user guidance, raise
to Microsoft. Show the ones worth choosing between, and recommend one.

Write for a functional consultant, in ASD-STE100 style:

- Short sentences: 20 words or fewer for an instruction, 25 for a description. Active voice.
- Functional words: screens, documents, fields, buttons, what the user sees. No class, method or
  table names outside **For the developer**.
- Explain a term a consultant may not know (HTML vs JSON, transaction, rollback, batch task) in one
  clause, the first time it appears.
- Write menu paths as `A > B > C`. Copy D365 field names, button names and error text exactly.
- One term for one thing, every time.

Use this structure. Leave out a section that has nothing to say. The first block fits on one screen.

```
**Problem:**   <one sentence — what the user sees>
**See it:**    <menu path and the record that shows it in the UI, or "Not visible in the UI, because …">
**Cause:**     <one sentence> — <proven in UAT | likely, not tested yet>[; customizations not checked]
**Fix:**       <the recommended action, one sentence>
**Next step:** <one action, and who does it>

### Why it happens
3–6 short lines: only the facts needed to follow the cause. Mention a ruled-out cause only when the
customer or a colleague suggested it (one line). Link a KB article or Microsoft page if one matched.

### Test in UAT          (only when the cause is not proven yet)
Numbered steps with record IDs, then the expected result, then the opposite test.

### Options
| Option | What it does | Risk |
The recommended one marked.

### For the developer
Technical root cause, objects involved (classes, tables, methods), environment and records used,
next skill. Bullet points, no more than about 8 lines.
```

## Missing setup

Name the missing piece, and point the user to `/my-dax-skills:setup-mydaxskills` to fix it. Then:

| Missing or signed out | Do |
|---|---|
| Tracker connector | Stop. The ticket cannot be read. |
| Browser (Claude in Chrome and the built-in browser) | Continue. Ask the user to paste each ticket image you need, and to run each SQL query and paste the result. |
| DAXONET Notes or Microsoft Learn | Continue. Add "Not searched: <source>" under For the developer. |
| Standard or custom code | The code readiness checkpoint. |
