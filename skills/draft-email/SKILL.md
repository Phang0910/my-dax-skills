---
name: draft-email
description: Draft a reply email to a customer or vendor in the DAXONET house style, then hand it back for review. Use when the user asks to write, draft, or reply to an email — to a customer, to NTT/vendor contacts, or on a Tracker email thread.
---

# draft-email

Draft an email reply in the house style, show it to the user, and stop. **You are drafting, not
sending.**

**Never send.** Output the draft in chat. Creating an Outlook *draft* is allowed only if the user
asks for it explicitly, and even then never `outlook_send_mail` / `outlook_send_draft`. The user
sends it themselves, from their own mailbox, after reading it.

---

## Step 1 — Read the thread before writing

Do not draft from the user's summary alone. Find the actual thread:

1. **The Tracker ticket.** `mcp__claude_ai_Tracker__get_issue` — the `journals` usually contain the
   full email chain pasted in, including headers. This gives you the exact recipient list, the
   subject line, what the other side actually asked, and how we have been writing to them.
2. **The current conversation**, for the technical substance.
3. **Ask** if the recipient or the ask is still unclear. Do not invent a recipient.

Establish before drafting:

- **Who** you are replying to, and what they actually asked — answer every question they raised
- **The exact subject line** already in use
- **The full Cc list** already on the thread
- **Who is sending** — the user, or a colleague who owns the thread (see Step 4)

## Step 2 — Subject and recipients: copy, do not improve

- **Reuse the subject verbatim**, including any `[#<id>]` prefix the helpdesk added. That prefix is
  what files the reply back into Tracker. Rewriting the subject — even to fix a typo in it — breaks
  threading and loses the ticket linkage. If the subject contains a mistake, correct it in the
  body, never in the header.
- **Keep everyone already on the thread**, including the project helpdesk alias
  (e.g. `nichias@helpdesk.daxonet.com`). Dropping it means the reply never reaches Tracker.
- Add a recipient only if the user asks.

## Step 3 — Draft in the house style

Short. Most replies are three or four lines. Length is earned by instructions or an explanation,
never by throat-clearing.

```
Hi <Name>,

<One-line courtesy opener, only when replying.>

<The answer. One or two sentences.>

<Label:> <detail — only when there is genuinely more to say.>

Do let me know if you have any further questions.

Thank you.

Regards,
<Sender name>
DAXONET Customer Success
```

**Salutation** — match what the thread already uses:

| Recipient | Form |
|---|---|
| Japanese counterpart (NTT etc.) | `Hi Egoshi san,` |
| Malaysian customer contact, formal | `Hi Ms. Tey,` / `Hi Mr. Khor,` |
| Customer contact, familiar | `Hi Syima,` |

**Plain labels carry the structure.** Not headings, not bullets — a bold-free label and a colon:
`What is needed:` · `Conclusion:` · `Steps:` · `Please note:` · `To confirm:` ·
`Interim workaround:` · `Target date on next update:`

**Close** with `Do let me know if you have any further questions.` then `Thank you.` Sign off
`Regards,` + name + `DAXONET Customer Success`. The hotline block is added by the mail client —
do not type it out.

### Worked example — short reply

```
Hi Ms. Tey,

The UAT environment already refreshed completed.

Do let me know if you have any further questions.

Thank you.
```

That is a complete, in-style reply. Resist padding it.

### Worked example — reply that has to instruct

```
Hi Egoshi san,

Thank you for your reply, and no problem regarding the delay.

Unfortunately the Visual Studio Professional licence does not resolve this. It covers the
development tool on the developer's PC only, and gives no access inside the Dynamics 365
environment - the two are licensed separately.

What is needed: a Dynamics 365 Finance or Supply Chain Management licence (full licence,
not Team Member) assigned to admin@nichiasgbl2.onmicrosoft.com. The account already has
the System Administrator role, so this is purely a licensing matter.

This is currently holding up two tickets - #19119 and #18935. Both fixes are ready to
progress but cannot be deployed until the licence is in place.

Steps:
1. Microsoft 365 admin center > Users > Active users > select the account > Licenses and
   apps > assign the licence > Save changes.
2. Power Platform admin center > Environments > <env> > Settings > Users + permissions >
   Users > select the account > "..." > Manage user in Dynamics 365 > Administration tab >
   Access Mode > set to Read-Write > Save.

Please note: step 2 must be done by another System Administrator, as an account cannot
change its own access mode.

To confirm it is working: open the "Finance and Operation Package Manager" app. It
currently shows a permissions error and should load normally once the licence is active.

Do let me know if you have any further questions.

Thank you.

Regards,
Jun Phang Gan
DAXONET Customer Success
```

### Writing rules

- **Answer every question they asked.** A reply that addresses one of two questions guarantees
  another round trip. Handle the second with `On your second question:`.
- **Lead with the answer, not the reasoning.** `Unfortunately the Visual Studio Professional licence
  does not resolve this` first; why, second. Recipients skim.
- **Menu paths use `>`, one numbered step per action.** Never prose out a click path.
- **Give a self-serve verification step.** `To confirm it is working: open X — it should now Y.`
  Without it the thread bounces back "we did it, is it right?".
- **State impact factually, never press.** `This is currently holding up two tickets - #19119 and
  #18935.` No "urgently", no "as soon as possible".
- **Say plainly when the customer did nothing wrong** — `Your inventory records and the standard
  report are accurate.` It stops them re-checking their own data for a week.
- **Own our mistakes in one clause, then move on.** `Our earlier reference to "VB" was not correct -
  no Visual Basic is involved.` No apology paragraph.
- **Quote error text only as evidence a vendor needs.** Otherwise state the conclusion. Never paste
  a stack trace to a customer.
- **Distinguish what you verified from what you were told.** If you are citing a colleague's ticket
  note, flag it to the user as second-hand before they send it under their own name.

### Leave out

- Element names, class/table names, file paths, X++
- Build logs, warning counts, correlation IDs (unless a vendor asked for one)
- "I have successfully…", "Please be informed that…", "Kindly be advised"
- Restating their whole question back at them before answering it

## Step 4 — Hand it back

Show the full draft in a code block, with `Subject:`, `To:` and `Cc:` at the top so the user can
check the routing at a glance.

Then raise anything they should decide before sending. Common ones:

- **Who sends it.** If a colleague opened the thread or owns the customer relationship, say so and
  offer to change the sign-off. A reply from the person who made the original request usually
  carries more weight.
- **Anything second-hand.** Name it and suggest they confirm with the colleague first.
- **A correction that might embarrass someone.** Offer the version without it.

Do not use `AskUserQuestion` for a plain "is this ok" — just show the draft and let them respond.
Use it only when there is a real fork, such as which of two senders should own the reply.

Treat any change request as a redraft and show the whole email again, not a diff.

## Step 5 — Optional: save as an Outlook draft

Only when the user asks. Use `mcp__claude_ai_Microsoft_365__outlook_create_draft`, or
`outlook_create_reply_draft` / `outlook_create_reply_all_draft` when replying to a message you can
locate with `outlook_email_search` — a reply draft preserves threading headers better than a new
message with a copied subject.

Confirm in one line that the draft was created and that **it has not been sent**.

Never call `outlook_send_mail` or `outlook_send_draft`, even if the user says "send it" — tell them
the draft is in their Outlook and they can review and send it there.
