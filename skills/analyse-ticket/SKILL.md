---
name: analyse-ticket
description: Analyse a Tracker (Redmine) support ticket to its root cause — read the whole ticket including images, check known answers, the custom and standard D365FO code, and the real data in D365 through SQL Execute, then propose the fix, workaround or setup change. Use when the user asks to analyse, investigate, understand or find the root cause of a ticket.
argument-hint: "[ticket no]"
---

# analyse-ticket

Find out **why** a ticket happens, prove it, and propose what to do. Stop there.

**Done when** the root cause is at evidence level **reproduced** or **confirmed**, and the user has
the output below with the fix options. If the evidence stops at **supported**, the output says so
and names the one test that would close the gap.

Building the fix, writing test cases, the customer email and closing the ticket are other skills
(`draft-email`, `draft-progress`, `close-ticket`, `kb-this`). Name the next one in the handover.

## Evidence levels

Tag every finding with one level. Raise a level only on the evidence written beside it.

| Level | Evidence |
|---|---|
| **hypothesis** | A possible cause. Nothing checked yet. |
| **supported** | Code, setup or data agrees with it, and nothing checked disagrees. |
| **reproduced** | The symptom was produced on purpose in UAT by following the cause. |
| **confirmed** | Reproduced, and the opposite test (the cause removed) does not produce the symptom. |

Colleague conclusions and counts in the ticket journals enter at **hypothesis**. Check them again
before you build on them — look for false positives in their numbers (deleted lines, amounts moved
to other lines, test records).

## Hard rules

1. The user signs in to every site. You wait, then read the page.
2. SQL is read-only: `SELECT` statements, run in **Select** mode.
3. Query **UAT first**. Query production only when UAT does not have the data **and** the user says
   yes for this ticket (Step 4).
4. Ask the user at checkpoints only, and put all open questions into one message.

## Step 1 — Read the whole ticket

Read the issue and every journal with `mcp__claude_ai_Tracker__get_issue`.

Then decide the route:

- **Text only** — no attachments and no `!image…!` markers: the connector output is the full ticket.
- **Images or files** — the connector gives no image content and no URL. Open each one in a browser
  and read it. Follow [`reference/read-tracker.md`](reference/read-tracker.md).

**Done when** every journal and every attachment is read, and you can state: what the customer
asks, the timeline, which claims are checked and which are not, and what each screenshot shows
(with its date format and environment).

## Code readiness — checkpoint

Now the customer is known. Find its standard and custom code with the first part of
[`reference/code-search.md`](reference/code-search.md).

- **Both found** → tell the user in one line which folders you will use, and continue.
- **A piece is missing** → stop and ask once. Name the missing piece and what the analysis loses:

  ```
  Code not available: <missing piece>.
  Without code, the analysis cannot check customizations or verify SQL field names.

  → Set up first (recommended) — run /my-dax-skills:setup <customer>, then run this skill again
  → Continue without code
  ```

  Fill in `<customer>` with the customer's name from the project map, so setup prepares exactly
  this customer's code.

  *Set up first* → stop here. *Continue without code* → the rest of the run is **without code**:
  every step marked "Without code" below takes its fallback.

## Step 2 — Look for a known answer

Run these before deep analysis. They are fast and often end the investigation.

- **DAXONET Notes** — search past KB articles for the symptom, error text and customer:
  `mcp__claude_ai_DAXONET_Notes__list_documents(query: "...")`. Large results go to a file; read
  the file.
- **Microsoft Learn** — standard behaviour and setup: `mcp__claude_ai_Microsoft_Learn__microsoft_docs_search`.
- **Known Microsoft bugs** — if the symptom looks like a product defect, ask the user to search the
  LCS Issue search, or search it yourself if an LCS session is open.

**Done when** each source was searched with the symptom and the error text, and any match is
recorded with its link.

## Step 3 — Form hypotheses and read the code

List every candidate cause at level **hypothesis**. For each one, write the test that would prove
or remove it.

Read the code on the business path of the symptom: the customer's extensions first, then the
standard methods they extend or call. Follow [`reference/code-search.md`](reference/code-search.md).

Ask the user early for screenshots of the setup pages on that path (parameters, policies, the
dialog the user saw). One setup screenshot can replace many queries.

**Done when** every customization on the path is listed with what it changes (or "no effect on
the symptom"), and every hypothesis has its test.

**Without code:** build the hypotheses from the ticket, Step 2 and the setup screenshots. Done
when every hypothesis has its test. The output lists "customizations not checked" as an open risk.

## Step 4 — Check the real data in D365

Use SQL Execute to see the records behind the ticket. Follow [`reference/sql-execute.md`](reference/sql-execute.md).

1. **Choose the environment.** Query the ticket's own documents (PO, PR, voucher numbers) in UAT.
   - Found → work in UAT.
   - Not found → tell the user that UAT does not have the data, and ask: check in production
     (read-only), or reproduce in UAT instead?
2. **Choose who runs the SQL.** Ask once per ticket:
   - *You run it* — the user opens SQL Execute, runs each query, and pastes the result.
   - *I run it* — the user gives the SQL Execute URL and signs in. You run it in Claude in Chrome,
     or in the built-in browser if Chrome is not connected.
3. Run one discriminating query at a time. After each result, update the evidence level of every
   hypothesis it touches.

**Without code:** verify table and field names with the fallback in `reference/sql-execute.md`.

**Done when** every hypothesis is **supported** or removed, and each removal has its result.

## Step 5 — Reproduce the cause

When data and code support one cause, prove it in UAT. Give the user exact steps built from the
customer's code (mandatory fields, workflow stages, lookups) and from a known-good record of the
same type (copy its dimensions and values). Give one test that produces the symptom and one
opposite test that does not.

**Without code:** take the values from a known-good record of the same type in UAT. Before you
write the steps, ask the user once which custom mandatory fields and workflow stages that document
type has.

**Done when** the symptom is **reproduced**, and **confirmed** if the opposite test was run.
If the user cannot run it now, stop at **supported** and say what is left.

## Step 6 — Propose actions and write the output

List every realistic action, with its effect and risk: code fix, workaround, setup change, user
guidance, raise to Microsoft. Recommend one.

Write in ASD-STE100 style:

- An instruction sentence has 20 words or fewer. A description sentence has 25 words or fewer.
- One instruction per sentence. Use the active voice and the imperative.
- Use one term for one thing, every time.
- Write menu paths as `A > B > C`. Copy D365 field names, button names and error text exactly.

Use this structure every time. The summary comes first and fits on one screen.

```
Summary
Problem:   <one sentence — what the user sees>
Cause:     <one sentence> (<evidence level>; add "code not checked" when without code)
Action:    <the recommended action, one sentence>
Next step: <one action, and who does it>

Details
1. Ticket facts — timeline, what each screenshot shows
2. Checks — code, setup, data: what was checked, the result, the environment
3. Ruled out — each removed cause and the result that removed it
4. Options — table: action | effect | risk; the recommended option marked
5. Handover — root cause, evidence, objects involved, chosen option, next skill
```

## Missing setup

Name the missing piece, and point the user to `/my-dax-skills:setup` to fix it. Then:

| Missing or signed out | Do |
|---|---|
| Tracker connector | Stop. The ticket cannot be read. |
| Browser (Claude in Chrome and the built-in browser) | Continue. Ask the user to paste each ticket image, and to run each SQL query and paste the result. |
| DAXONET Notes or Microsoft Learn | Continue. Record the source as "not searched" in Step 2. |
| Standard or custom code | The code readiness checkpoint. |