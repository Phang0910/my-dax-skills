---
name: draft-acknowledge-email
description: Draft the first-response acknowledgement email for a newly registered DAXONET support case, confirming the Support Case ID and assigned consultant. Use when the user asks to acknowledge a case, draft an acknowledgement/first-response email, or reply that a request has been registered.
---

# draft-acknowledge-email

Draft the acknowledgement email for a newly registered support case, show it to the user, and
stop. **You are drafting, not sending.**

**Never send.** Output the draft in chat. Creating an Outlook *draft* is allowed only if the user
asks for it explicitly, and even then never `outlook_send_mail` / `outlook_send_draft`.

This is the opening bookend to `draft-closing-email`. The house style and writing rules in
`draft-email` still apply — this skill only fixes the acknowledgement *format*.

---

## Step 1 — Pull the real ticket first

Call `mcp__claude_ai_Tracker__get_issue` with the case ID. **Never draft an acknowledgement from
the user's summary alone** — the whole point of this email is that the two details in it are
correct. From the ticket, establish:

- **The exact subject line** — reuse it verbatim, including any `[#<id>]` prefix. That prefix
  files the reply back into Tracker; rewriting it breaks threading.
- **The recipient** — the `author` field, unless the thread shows someone else asking.
- **Assigned Consultant** — the `assigned_to` field, unless the user names someone else.
- **The Cc list** — keep everyone already on the thread, including the project helpdesk alias
  (`mmm@helpdesk.daxonet.com` for MMM). Dropping it means the reply never reaches Tracker.

If the ticket has **no assignee yet**, say so and ask who to name. Do not guess, and do not
default to the user.

## Step 2 — The acknowledgement format

The two detail fields run as **one compact block with no blank line between them** — circulating
copies of this template space them out, but the compact run matches the verified closure format
in `draft-closing-email`. Ask the user before spacing them.

```
Dear <Name>,

Thank you for reaching out to DAXONET Customer Success Support Services.

Your request has been registered and acknowledged with the following details:
Support Case ID: <id>
Assigned Consultant: <first name>

Please use the Case ID for any future communication. Our support consultant is now on the case and will assist you promptly.

Thank you.

Best Regards,
<sender name>
```

Details that matter:

- **First names only.** `Assigned Consultant: Jun Phang`, not `Gan Jun Phang`.
- **Salutation** — `Dear <Name>,` on MMM threads. Match whatever the thread already uses.
- **Sign off `Best Regards,` then `<sender name>`.** Do not add the `DAXONET Customer Success`
  line or the hotline block — the mail client signature supplies them.
- **Nothing else goes in.** No summary of the issue, no ETA, no first-look findings, no
  troubleshooting questions. This email says *we have it and here is the reference*. Substance
  belongs in the next reply, drafted with `draft-email`.

## Step 3 — Flag anything worth knowing before it goes out

Say so plainly, in a line or two, if:

- **The case is already well past acknowledgement** — journals show replies traded, or the status
  is resolved. Sending a first response then reads as if nobody was watching.
- **The ticket has no assignee**, or the assignee differs from the person the user named.
- **The requester is not the ticket author** — someone else on the thread raised it, and `Dear
  <author>` would address the wrong person.

State the concern and still show the finished draft. Do not refuse to draft.

## Step 4 — Hand it back

Show the full draft in a code block with `Subject:`, `To:` and `Cc:` at the top so the routing
can be checked at a glance. Then list the flags from Step 3.

Treat any change request as a redraft and show the whole email again, not a diff.
