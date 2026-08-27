---
name: draft-closing-email
description: Draft the final ticket-closure email for a resolved Tracker support case, in the DAXONET closure format. Use when the user asks to close a ticket, draft a closing/closure email, or send the final email for a case.
---

# draft-closing-email

Draft the closure email for a resolved support case, show it to the user, and stop.
**You are drafting, not sending.**

**Never send.** Output the draft in chat. Creating an Outlook *draft* is allowed only if the user
asks for it explicitly, and even then never `outlook_send_mail` / `outlook_send_draft`.

This skill is the closure counterpart to `draft-email`. The general house style, salutation
table, and writing rules in `draft-email` still apply — this skill only fixes the closure
*format*. Read `draft-email` if you need the wider style guidance.

---

## Step 1 — Pull the real ticket first

Call `mcp__claude_ai_Tracker__get_issue` with the case ID. **Never draft a closure from the
user's summary alone.** From the ticket, establish:

- **The exact subject line** — reuse it verbatim, including any `[#<id>]` prefix. That prefix
  files the reply back into Tracker; rewriting it breaks threading.
- **Reported By** — the `author` field.
- **Consultant Assigned** — the `assigned_to` field, unless the user names someone else.
- **Consultant Hours** — the `spent_hours` field. See the warning in Step 3.
- **Whether the case is actually finished** — read the last few journals. See Step 4.
- **The Cc list** — keep everyone already on the thread, including the project helpdesk alias
  (`mmm@helpdesk.daxonet.com` for MMM). Dropping it means the reply never reaches Tracker.

## Step 2 — The closure format

This is the format actually in use (verified against sent closures, e.g. ticket #18885).
The detail fields run as **one compact block with no blank lines between them**:

```
Dear <Name>,

We've successfully resolved your support case with the following details:
Support Case ID: <id>
Reported By: <first name>
Consultant Assigned: <first name>
Summary of Resolution: <one short sentence>
Consultant Hours: <n> hours

Please confirm the closure of this support case. If we don't hear back from you within 3 days, we'll close the case automatically.

If you need further help or have any questions, just let us know. We're here to assist you.

Thank you.

Best Regards,
<sender name>
```

Details that matter:

- **First names only.** `Reported By: Sean`, not `Sean Ng`. `Consultant Assigned: Jun Phang`,
  not `Gan Jun Phang`.
- **`Consultant Hours`** — plural, even at 1.0.
- **Salutation** — `Dear <Name>,` on MMM threads. Match whatever the thread already uses.
- **Sign off `Best Regards,` then `<sender name>`.** Do not add the `DAXONET Customer Success` line
  or the hotline block here — the mail client signature supplies them.
- The `Please confirm the closure…` paragraph is part of the standard template. Some past
  closures omitted it; include it unless the user says otherwise.

## Step 3 — Summary of Resolution

**One short sentence. Plain business language.** This is the line users get wrong by making it
too long — resist explaining the root cause, the investigation, or the technical mechanism. The
customer already had those in earlier replies; the closure is a record, not a report.

Good: `Stopped the DMS chassis interface from overwriting the manufacturing year with blank values.`

Good: `Added new safety checks to save the error into the DO_Received Message field.`

Leave out entirely: class and table names, X++, file paths, feature/flight names, build details,
environment names, deployment mechanics.

**Hours — always check Tracker, never trust the number in a pasted template.** House templates
circulate with a placeholder figure (often `1.5 hours`) that people forget to change. Read
`spent_hours` from the ticket, use that, and tell the user you overrode the template value.

## Step 4 — Flag anything that makes closure premature

A closure email ends the case. Before handing it over, check the ticket and say so plainly if:

- **Work is still outstanding** — a data fix not yet run, a deployment not yet scheduled, a
  follow-up promised in an earlier note. Closing over an open commitment brings the case
  straight back.
- **The customer's last message was a question or a request** that was answered over Teams or a
  call rather than on the ticket. That resolution is second-hand to you — flag it and let the
  user confirm before sending under their own name.
- **The ticket status contradicts closure** — still sitting in an active state with no sign the
  customer agreed.

State the concern in a line or two and still show the finished draft. Do not refuse to draft.

## Step 5 — Hand it back

Show the full draft in a code block with `Subject:`, `To:` and `Cc:` at the top so the routing
can be checked at a glance. Then list the flags from Step 4 and any value you substituted
(hours especially).

Treat any change request as a redraft and show the whole email again, not a diff.
