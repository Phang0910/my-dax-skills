---
name: draft-follow-up-email-progress
description: Draft a progress-update email on an open support case — where we currently are, and when the next update lands. Use when the user wants to update, keep warm, or report progress to a customer on a ticket that is still sitting on our side. For chasing a customer who has gone quiet, use draft-follow-up-email-chaser instead.
argument-hint: "[ticket no] [describe your progress]"
---

# draft-follow-up-email (progress)

Draft the progress update we owe the customer on an open case, show it to the user, and stop.
**You are drafting, not sending.**

**Never send.** Output the draft in chat. Creating an Outlook *draft* is allowed only if the user
asks for it explicitly, and even then never `outlook_send_mail` / `outlook_send_draft`.

This is the sibling of `draft-follow-up-email-chaser`. The chaser goes out when **they** have
gone quiet. This one goes out when **we** are holding the case and they are waiting on us — a fix
in progress, a vendor reply pending, a deployment scheduled. Same family, opposite direction.

---

## Step 1 — Pull the ticket, then take the progress from the user

Call `mcp__claude_ai_Tracker__get_issue` with the case ID (the first argument, if given). The
ticket supplies the routing and what the customer already knows; the user's second argument
supplies what is new. Establish from the ticket:

- **The exact subject line** — reuse it verbatim, including any `[#<id>]` prefix. That prefix
  files the reply back into Tracker; rewriting it breaks threading.
- **The recipient** — whoever we last wrote to on the thread, normally the `author`.
- **The Cc list** — keep everyone already on the thread, including the project helpdesk alias
  (e.g. `mmm@helpdesk.daxonet.com` for MMM). Dropping it means the reply never reaches Tracker.
- **What we last told them**, and any date we already promised. If this update moves a date we
  named before, that is the thing the customer will notice first.

If the progress argument is missing, or is one word like `investigating`, ask what actually moved.
Do not manufacture progress from the journals — a note posted with `draft-progress` is internal
wording, not a customer sentence.

## Step 2 — The template

```
Dear <Name>,

<the progress — as simple and clear as possible>

Target next update: <dd Month yyyy> (<Weekday>)

Thank you.

Best Regards,
<sender first name>
```

That is the whole email. No `Good morning.`, no `Do let me know if you have any further
questions.` — this template is complete as it stands and is not the `draft-email` shape.

- **Salutation** — `Dear <Name>,` on MMM threads; otherwise match whatever the thread already
  uses.
- **Sign off `Best Regards,` then the sender's first name** as it appears on the thread
  (`Jun Phang`). No `DAXONET Customer Success` line, no hotline block — the mail client signature
  supplies them.

## Step 3 — Writing the progress line

- **One to three sentences.** The customer wants the state and the date, not the method.
- **Lead with where it stands**, then the reason it is not finished yet. `The fix is built and is
  now in UAT for verification` — not a chronology of what we did each day.
- **Plain English only.** No element, class or table names, no X++, no file paths, no correlation
  IDs. Same "Leave out" list as `draft-email`.
- **Name a blocker only when it is honest and useful** — a vendor reply we are waiting on, a
  deployment window. If the blocker is something the customer must do, say it in one line so the
  ball is visibly in their court.
- **No apology paragraph.** If we slipped a date, one clause covers it, then the new date.

**`Target next update:`** defaults to the third working day from the day the email goes out —
count forward from the send date, skipping weekends and public holidays. But a date the work
itself dictates wins over the counter: a deployment set for Friday, a vendor ETA the user gave
you, a UAT window. Use that date and say so when handing the draft back.

**Format the date as `1 September 2026 (Tuesday)`** — day without a leading zero, month spelled
out, four-digit year, weekday name in brackets, not abbreviated. Never promise a date the user
has not actually agreed to.

## Step 4 — Flag anything that makes this the wrong email

Say so plainly, in a line or two, if:

- **Nothing has actually moved** since the last update. An email that says we are still looking
  into it invites "so when?". Either wait, or say plainly what is blocking and who holds it.
- **The customer already replied** and the reply is sitting unanswered on the ticket. Answer them
  first with `draft-email`.
- **The update is really the answer.** If the work is done, this is `draft-closing-email`, not a
  progress note.
- **We are about to promise a date we already missed once.** Then the email needs one clause on
  what changed, or the new date reads as guesswork.
- **The case is actually waiting on the customer**, not on us — that is
  `draft-follow-up-email-chaser`.

State the concern and still show the finished draft. Do not refuse to draft.

## Step 5 — Hand it back

Show the full draft in a code block with `Subject:`, `To:` and `Cc:` at the top so the routing can
be checked at a glance. Then say where the target date came from (`third working day from today`,
or `the deployment window you gave me`) and list the flags from Step 4.

Treat any change request as a redraft and show the whole email again, not a diff.
