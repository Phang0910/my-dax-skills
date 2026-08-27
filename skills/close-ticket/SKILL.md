---
name: close-ticket
description: Close a resolved Tracker (Redmine) support ticket — set the status, pick the Root Cause, write the Resolution, and stamp the Resolution Date. Use when the user asks to close, reject or wrap up a ticket in Tracker, and as the natural next step after draft-closing-email.
argument-hint: "[ticket no]"
---

# close-ticket

Close a resolved support case properly: status, **Root Cause**, **Resolution**, **Resolution
Date**, in one update, after the user confirms.

**Never close without explicit confirmation.** The confirmation must show the ticket number, the
subject, and every value about to be written.

This is the Tracker counterpart to `draft-closing-email`. That skill writes the email; this one
closes the record. Run it after the closure email has gone out — or right after drafting it, if the
customer has already agreed to closure on the ticket.

---

## The fields

Resolve these by id. `list_custom_fields` requires admin and **will fail on this account** — do not
call it. These ids are stable and verified against closed tickets across MMM, UAS, Luvata,
Panasonic and VSTECS.

| Field | id | What goes in it |
|---|---|---|
| Root Cause | `cf 7` | One value from the list below. Must match the dropdown string exactly. |
| Resolution | `cf 52` | What was actually done. See Step 3. |
| Resolution Date | `cf 53` | The date you are closing — today, `YYYY-MM-DD`. |

**Do not touch anything else.** Not `done_ratio`, not `assigned_to_id`, not `spent_hours`, not
`due_date`, and not `cf 56` — that field is used inconsistently across projects and is not yours to
fill. `cf 43` is Principal Case # (the Microsoft ticket number) and belongs to
`raise-ms-support-ticket`.

### Root Cause values

```
Business Operation
User Familiarize
As design
Integration issue
Bugs
Duplicated
Fixed
Cannot Reproduce
Change Request
```

Roughly what each one is for:

- **Business Operation** — the system worked; the process or the data around it did not. Someone
  posted wrongly, a record needed clearing, a job needed rerunning. The most common value by far.
- **User Familiarize** — nothing was wrong. The user needed to be shown how.
- **As design** — standard D365 behaviour that the customer read as a fault.
- **Integration issue** — the fault was in an interface: EDI, DMS, a web service, a third party.
- **Bugs** — a genuine defect, ours or Microsoft's, that needed a code fix.
- **Duplicated** — already covered by another ticket. Pair with **Rejected**, not Closed.
- **Fixed** — a defect corrected without a wider root-cause story to tell.
- **Cannot Reproduce** — closed because it never recurred and there was nothing to see.
- **Change Request** — not a fault; it turned into a request for new behaviour.

If Tracker rejects a value, the dropdown string differs from the list above — read the exact
casing off a recently closed ticket in the same project rather than guessing at it.

---

## Step 1 — Pull the ticket

`mcp__claude_ai_Tracker__get_issue`. Resolve the id from the conversation first — if
`draft-closing-email` just ran, it is the same ticket, so do not ask again. Ask only if there is
genuinely no id in play.

Read back **the ticket number and its subject** before doing anything else. Closing the wrong
ticket is the one unrecoverable mistake this skill can make.

From the ticket, establish:

- **Current status** — and whether it contradicts closure.
- **What actually resolved it** — the last few journals, and this conversation.
- **Whether the customer agreed to closure**, or whether the 3-day auto-close clause is being
  relied on.

### Say so if closure looks premature

Same check as `draft-closing-email` Step 4. Flag it in a line or two, then carry on and show the
proposed values — do not refuse:

- Work still outstanding — a data fix not run, a deployment unscheduled, a promise made in a note.
- The customer's last message is an unanswered question.
- The status is `In Review: Customer` (9) with no reply, and no closure email has gone out.
- The case is sitting in `In Progress: Customer` (7) or `In Review: Internal` (8) waiting on
  Microsoft, with the Principal Case # still open.

## Step 2 — Root Cause

Recommend one value from the list, with a one-line reason drawn from the ticket. Then **confirm it
with `AskUserQuestion`** — offer your recommendation first, plus the two or three next most likely
values. This is a real fork with a fixed set of answers, which is exactly what that tool is for.

Never write a Root Cause the user has not seen and accepted.

## Step 3 — Resolution

**Start from the Summary of Resolution** if `draft-closing-email` produced one in this conversation
— on a well-run case they are the same sentence, and #18932 shows the field and the email matching
verbatim.

But they are not always identical, and the difference matters: **the Tracker field is internal.**
Where the email must stay in plain business language, the Resolution field is the record a
consultant reads in a year's time, so it may keep the specifics the email deliberately drops —
a number sequence, a table name, an environment, the fact that the fix was a SQL update in the
notes.

House style, from Khor's closures:

- **Action first, and short.** Usually a fragment, not a full sentence.
- **One line for a straightforward fix.** Two or three sentences only when the answer was "there is
  no standard way to do this" and the workaround needs stating.
- **Point at the evidence rather than repeating it.** `using the SQL queries in Note` beats pasting
  fifteen transaction IDs into the field.
- No greeting, no sign-off, no "we have successfully".

Real examples:

```
Clear record in status list for Sales_4
```
```
Void the RNT transactions using the SQL queries in Note.
```
```
Delete the VM dev 1 and VM dev 2 to reduce the storage.
```
```
User to create new PO
```
```
Confirmed there is no standard D365 configuration to fully lock the Target LP field. The
recommended workaround is to scan the LP label instead of typing it and only change it when
genuinely necessary. A stricter system-enforced block would require custom development.
```

## Step 4 — Resolution Date

**Today**, in `YYYY-MM-DD` — the date the ticket is being closed, not the date the fix went in and
not the date the email was sent.

Take today's date from the environment context. If the user names a different date, use theirs.

## Step 5 — Confirm, then write once

Show the whole block and stop for a yes:

```
Close #<id> — <subject>

Status:          Closed
Root Cause:      <value>
Resolution:      <text>
Resolution Date: <YYYY-MM-DD>
```

On confirmation, **one** `mcp__claude_ai_Tracker__update_issue` call:

- `status_id: 5`
- `custom_fields: [{id: 7, ...}, {id: 52, ...}, {id: 53, ...}]`

No `notes`. The closure email is posted by whoever sends it, not by this skill.

Confirm in one line that the ticket is closed, and stop.

### Rejecting instead of closing

`status_id: 6` for a ticket that was never a real case — a duplicate, a mis-filed email, a request
withdrawn. Set **Root Cause only**; leave Resolution and Resolution Date blank, since nothing was
resolved. #19306 is the pattern.

`Transferred` (13) and `KIV` (14) also close a ticket. Neither is this skill's job — if one of
those is what the user actually wants, say so and let them do it in Tracker.
