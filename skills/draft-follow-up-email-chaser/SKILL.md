---
name: draft-follow-up-email-chaser
description: Draft a chaser email on a support case the customer has gone quiet on — the 1st/2nd follow-up, the 3rd follow-up that warns of closure, or the system-behaviour archive request. Use when the user asks to follow up, chase, or nudge a customer on a ticket with no response. For updating a customer on our own progress, use draft-follow-up-email-progress instead.
argument-hint: "[ticket no]"
---

# draft-follow-up-email (chaser)

Draft a follow-up (chaser) email on a case awaiting the customer's response, show it to the user,
and stop. **You are drafting, not sending.**

**Never send.** Output the draft in chat. Creating an Outlook *draft* is allowed only if the user
asks for it explicitly, and even then never `outlook_send_mail` / `outlook_send_draft`.

This sits between `draft-email` and `draft-closing-email` in the same family. Its sibling is
`draft-follow-up-email-progress` — that one goes out when **we** are holding the case; this one
when **they** have gone quiet. The house style, salutation table, and writing rules in
`draft-email` still apply — this skill only fixes the follow-up *templates* and the rule for
picking between them.

---

## Step 1 — Pull the real ticket first

Call `mcp__claude_ai_Tracker__get_issue` with the case ID (the skill argument, if given).
**Never draft a follow-up from the user's summary alone** — the whole point is that you are
chasing at the right stage, and only the journals tell you that. From the ticket, establish:

- **The exact subject line** — reuse it verbatim, including any `[#<id>]` prefix. That prefix
  files the reply back into Tracker; rewriting it breaks threading.
- **The recipient** — whoever we last wrote to on the thread, normally the `author`.
- **The Cc list** — keep everyone already on the thread, including the project helpdesk alias
  (e.g. `mmm@helpdesk.daxonet.com` for MMM). Dropping it means the reply never reaches Tracker.
- **The date we last replied**, and whether anything has come back since.
- **How many follow-ups we have already sent** — count the journals/emails that are chasers, not
  substantive replies. This decides which template is next.
- **What we last told them** — a fix delivered and awaiting confirmation reads differently from
  "this is standard system behaviour and cannot be changed".

## Step 2 — Work out which follow-up this is, then ask

Compute the stage from the ticket, then confirm with the user using `AskUserQuestion`. Put your
computed stage **first** and label it `(Recommended)`, with the reason in the description —
`last reply 2026-08-18, no response, no chaser sent yet`. The user overrules freely; the
recommendation exists so they do not have to count journals themselves.

| Situation on the ticket | Template |
|---|---|
| Resolution provided, no chaser yet — send the next day | **A** — first follow-up |
| First chaser sent, ~3 business days ago, still silent | **A** — second follow-up (same wording) |
| Two chasers already sent, still silent | **B** — third follow-up, warns of closure |
| The answer was "system behaviour / not supported", and we want the ticket archived | **C** — system-behaviour archive request |

Notes on the cadence:

- **First follow-up: the next working day** after the resolution was provided.
- **Second: three business days** after the first. Do not chase sooner; if the gap is shorter,
  say so and let the user decide.
- **Third: another three business days**, and it carries the closure warning. After that the
  case goes to `draft-closing-email`, not to a fourth chaser.
- **Template C is not a stage** — it is the variant for cases where the outcome was "this is how
  the system works" rather than a fix awaiting confirmation. It can replace the second or third
  chaser.

## Step 3 — The templates

Wrap every template in the house salutation and sign-off. Keep the body wording as it stands —
these are standing templates, not prose to improve.

**Template A — first / second follow-up**

```
Dear <Name>,

Good morning. May we know if there's any update on this case?

Please do not hesitate to contact us if you've any inquiries.

Target next update: <dd Month yyyy> (<Weekday>)

Thank you.

Best Regards,
<sender name>
```

**Template B — third follow-up, with closure notice**

```
Dear <Name>,

Good morning. May we know if there's any update on this case?

Please let us know if there's anything we can assist you with, otherwise we'll proceed to set this case to close.

Target next update: <dd Month yyyy> (<Weekday>)

Thank you.

Best Regards,
<sender name>
```

**Template C — system behaviour, request to archive**

```
Dear <Name>,

Please understand that this issue is due to system behavior, and we currently do not have enough information to explain why it is not supported.

In case if no concerns, please kindly allow me to archive this ticket.

Thank you and I am looking forward to hearing from you soon.

Please let us know if there's any additional information or assistance you need from our end.

Best Regards,
<sender name>
```

Details that matter:

- **`Target next update:` is the third working day from the day the email goes out.** Count
  working days forward from the send date, skipping weekends and public holidays: a chaser sent
  on a Wednesday targets the following Monday. This matches the three-business-day cadence in
  Step 2 — the date you promise here is the day the next chaser is due.
- **Format the date as `1 September 2026 (Tuesday)`** — day without a leading zero, month spelled
  out, four-digit year, then the weekday name in brackets. The weekday is there so the customer
  can see at a glance how long they have; do not abbreviate it.
- **Templates A and B carry the target-update line; Template C does not.** C is asking to archive,
  so there is no next update to promise.
- **`Good morning.`** is the template wording. Switch it to `Good afternoon.` when the user is
  sending after midday, and drop it entirely if the thread never uses a time greeting.
- **Salutation** — `Dear <Name>,` on MMM threads; match whatever the thread already uses. `Hi
  <Name>,` on the more familiar threads.
- **Sign off `Best Regards,` then `<sender name>`.** No `DAXONET Customer Success` line, no
  hotline block — the mail client signature supplies them.
- **Template C ends on its own closing lines** — no separate `Thank you.` before `Best Regards,`,
  the thanks are already in the body.
- **Nothing else goes in.** No re-explaining the fix, no fresh findings, no new questions. A
  chaser that reopens the technical discussion restarts the thread instead of closing it. If
  there is genuinely new substance to send, that is `draft-email`. If the substance is where our
  own work has got to, that is `draft-follow-up-email-progress`.

## Step 4 — Flag anything that makes the chaser wrong

Say so plainly, in a line or two, if:

- **The customer already replied** and the reply is sitting unanswered on the ticket. Chasing
  then reads as if we did not read their message — draft a reply with `draft-email` instead.
- **The gap is too short** — the resolution went out today, or the last chaser was yesterday.
- **We owe them something** — an earlier note promised a data fix, a deployment, or a target
  date that has not landed. Chasing over our own open commitment is the wrong email — send the
  update with `draft-follow-up-email-progress` instead.
- **Template B is up but the case is not actually resolved.** Warning of closure on an
  unfinished case invites a complaint.

State the concern and still show the finished draft. Do not refuse to draft.

## Step 5 — Hand it back

Show the full draft in a code block with `Subject:`, `To:` and `Cc:` at the top so the routing
can be checked at a glance. Then say which template you used and why (`third follow-up — chasers
sent 12 and 18 August, no response`), and list the flags from Step 4.

If Template B is going out, add one line: the next step after this is `draft-closing-email`, not
another chaser.

Treat any change request as a redraft and show the whole email again, not a diff.
