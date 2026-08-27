---
name: draft-progress
description: Draft a short progress/completion note for a Tracker (Redmine) ticket in the house format, confirm it with the user, then post it to the ticket. Use when the user asks to write up, summarise, or post what they have done to a ticket.
argument-hint: "[ticket no]"
---

# draft-progress

Draft a short progress note for the work just done, get it confirmed, then post it to the
Tracker ticket as a note.

**Never post without explicit confirmation.** The confirmation must show the ticket number.

---

## Step 1 — Work out what was done

Prefer, in this order:

1. **The current conversation.** Usually the work is right here. Use it.
2. **Ticket-scoped artefacts** if the conversation is thin — a `HANDOFF_*.md` in the project
   folder, VS project contents, recent build logs (`Metadata\<Model>\BuildProjectResult.log`).
3. **Ask the user** if you still cannot tell. Do not invent scope.

Establish these before drafting:

- What behaviour changed, in business terms
- The exact user-facing message, if the change produces one
- Whether it is gated by a custom feature, and how it is enabled
- Anything deliberately **not** changed, when a reader would otherwise assume it was
- Current state: developed / built / checked in / deployed / in UAT

**Report only what actually happened.** If it is built but not deployed, the note says that. Never
write "deployed" or "tested" on the user's behalf unless they said so or you saw it happen. If the
user says they have deployed or checked in, take them at their word.

## Step 2 — Draft the note

House format. **Short is the whole point** — aim for 5–8 lines, hard ceiling ~12.

That ceiling applies to reporting *what was done*. A note whose job is to explain *why something
behaves the way it does* may run longer — clarity wins over the line count. Cut restatement and
jargon, never the worked figures.

```
#<id> — <one-line status>.

<What changed, 1–2 sentences, plain business language. Quote the exact user-facing message.>

<Feature gate and how to enable it — only if there is one.>

<What needed no change and why — only if a reader would otherwise assume it changed.>

<Status line.>
```

Worked example:

```
#19168 — Fixed, checked in and deployed to UAT.

Purchase requisition accounting date can no longer be backdated. Blocked with:
"The accounting date cannot be earlier than the current calendar date."

Controlled by the custom feature "Purchase Requisition - Prevent Backdated Accounting Date"
— must be enabled via DAXONET Custom Feature Management.

Requested date needed no change — standard D365FO already blocks backdating there.

Ready for user testing.
```

### Variant — analysis done, decision needed

Not every note reports a finished fix. When the outcome is a root cause plus a question for the
user, keep the same shape but swap the middle: explanation, then one paragraph putting the choice
to the user with a recommendation, then `Held pending user confirmation.`

```
#19169 — Root cause confirmed. Awaiting user decision before development.

Report as Finished is standard D365. The block comes from a Luvata validation on the
custom Gross weight field: "Gross weight cannot be lower than Good quantity."

For a production posting, this is correct:
gross weight (1,031.50) vs good qty (1,001.50) -> passes

The actual issue — a reversal posts the same figures as negatives, so the same rule
blocks it:
gross weight (-1,031.50) vs good qty (-1,001.50) -> rejected

-1,031.50 is the lower number, so the rule rejects it even though the figures are correct.

To confirm with the user: the existing rule works for a production posting only. For a
reversal, should we apply the opposite rule ("gross weight cannot be higher than good
quantity"), or should we simply skip the validation? We recommend the opposite rule, so
a reversal also cannot be keyed with a mismatched weight.

Also noted, on a reversal:
- Tare weight is forced to 0.00 instead of the expected negative value.
- Actual PCS has no validation, so it must be keyed as negative manually.

Held pending user confirmation.
```

Always give a recommendation alongside the question. "Which do you want?" with no steer pushes the
decision back unhelpfully.

### Writing the explanation

When the note has to make a reader *understand* something — not just tell them it is done — these
matter more than brevity. An explanation that has to be re-read twice is not short, it is expensive.

- **Show the figures, do not describe the rule.** Real numbers in a comparison line beat any prose
  restatement. Use `label (value) vs label (value) -> outcome`, one case per line, working case
  first. The reader sees the break themselves instead of being told about it.
- **Quote the message, never paraphrase it.** Write `the validation: "Gross weight cannot be lower
  than Good quantity."` — not `a rule saying gross weight must be the higher figure`. The paraphrase
  is a second thing for the reader to reconcile against the message they actually saw on screen.
- **One term per concept, used every time.** Pick `reversal` or `negative case` and never drift
  between them mid-note; same for its opposite (`production posting`). Only pair them as
  `reversal/negative` when the reader genuinely needs both senses at once.
- **Never reference a concept before you introduce it.** The killer is a phrase like "the rule was
  only written for X, not Y" placed *before* the reader knows a second rule is even on the table —
  "the rule" then reads as the existing one, and they wonder why Y ever needed it. Move that
  sentence next to the thing it is setting up.
- **Label the real problem, so a later question cannot displace it.** When a note carries both a
  defect *and* an open question about the fix, tag the defect line — `The actual issue — <what
  breaks>:`. Without it, readers finish on the question ("do we need a rule for reversals?") and
  walk away thinking that is the ticket, forgetting the real point: an existing rule written for
  one case is misfiring in another. The paragraph a reader meets last is the one they remember, so
  the earlier one has to be marked.
  Say `the actual issue`, not `the bottleneck` (jargon, and nothing is slow) and never `the request
  from user` — that reframes our own defect as a change they asked for, and invites "is this
  chargeable?".
- **State plainly when the user did nothing wrong.** "The figures the user keyed are correct" heads
  off a whole round of the customer re-checking their own data entry.
- **Several side notes → one `-` line each under a shared lead-in.** A single side note stays inline
  as prose. Do not bullet one item.

### Rules

The audience is a project manager or functional consultant, not a developer.

**Leave out** unless the user explicitly asks:

- Element inventories, class/table/label names, file paths
- X++ snippets, method names, CoC/event-handler mechanics
- Build output, warning counts, compile logs
- Long "open items" sections — at most one line, and only if it genuinely blocks sign-off
- Restating the ticket's own requirement back at it

**Keep:**

- The user-facing message, verbatim and in quotes
- How to turn the feature on, if it ships off by default
- A deliberate no-change decision, in one line — this pre-empts "you missed half the ticket"
- A clear final status

Write plainly. No filler openers, no "I have successfully…", no bullet-point sprawl.

## Step 3 — Resolve the ticket number

Look for it in: the conversation, the VS project or folder name (`DAX_JP_19168_...` → 19168),
branch or shelveset names, a `HANDOFF_*.md`. If several are plausible or none is, ask — never guess.

Once you have a candidate, call `mcp__claude_ai_Tracker__get_issue` with that id and read back the
**subject**. A number that resolves to an unrelated subject is the wrong number — stop and ask.

## Step 4 — Confirm before posting

Show the user, together:

- **the ticket number and its subject** (so a wrong number is obvious)
- the full draft note, exactly as it will be posted

Then use `AskUserQuestion` — options: post it / edit first / cancel.

Treat any edit request as a redraft, then confirm again. Do not post a note the user has not seen
in final form.

## Step 5 — Post

Post as a ticket note (a comment), not a description overwrite:

```
mcp__claude_ai_Tracker__update_issue(id: <ticket>, notes: "<the confirmed draft>")
```

Set `notes` only. Do **not** touch `status_id`, `done_ratio`, `assigned_to_id` or any other field
unless the user asked for it in this conversation — changing ticket state is a separate decision
from adding a note.

Confirm back to the user in one line that it posted, naming the ticket. If the call fails, say so
plainly and hand them the draft so nothing is lost.
