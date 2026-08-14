---
name: draft-progress
description: Draft a short progress/completion note for a Tracker (Redmine) ticket in the house format, confirm it with the user, then post it to the ticket. Use when the user asks to write up, summarise, or post what they have done to a ticket.
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
