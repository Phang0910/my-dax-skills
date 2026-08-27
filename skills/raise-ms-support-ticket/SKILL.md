---
name: raise-ms-support-ticket
description: Guide the user through raising a Microsoft support request in the Power Platform admin center, watching the live browser to stay in sync, then write the resulting Microsoft ticket number into the Tracker ticket's Principal Case # field. Use when the user asks to raise, file, log or open a ticket with Microsoft on a D365FO / Power Platform issue.
argument-hint: "[ticket no]"
---

# raise-ms-support-ticket

Assemble the description block for a Microsoft support request, guide the user through the Power
Platform admin center while they file it, then write the Microsoft ticket number back to Tracker.

**The user drives the browser.** You observe, guide, draft text to paste, and recommend answers.
You never fill the form and you never submit it.

**Done when** the support request exists and its number is in the Tracker ticket's
**Principal Case #** field. Tracking Microsoft's replies, chasing, escalating, or posting their
answers back to Tracker is *not* this skill — that is the normal email and Tracker skills.

---

## Hard rules

1. **Never ask for, receive, or type credentials.** The user signs in. You wait and read the page.
2. **Never click "Create support request".** That final action is the user's — the same principle
   as `draft-email` never sending.
3. **Never answer Microsoft's questions on the user's behalf.** Give a *recommended answer* in a
   code block for them to read, edit and paste.
4. **The page is the source of truth, never the user's description.** Do not ask the user to report
   what happened. End each step with "tell me when that's done" and treat their next message —
   whatever it says — purely as the cue to read the page. The browser tools are pull-only, so the
   cue is only for *timing*; the *state* always comes from the page. A validation error after Next
   is the common desync, and only the page reveals it.
5. **Do not check role or support-plan prerequisites.** Invoking the skill means the user has
   already confirmed them. Do not re-litigate.
6. **Never trigger browser dialogs** (alert / confirm / prompt) — they block the extension.
7. **Stop and ask after 2–3 failed browser calls.** Do not loop.
8. **Write no files.** Everything goes to chat as markdown. No scratch files, no saved pack, no
   logs. The only thing written anywhere is the one Tracker field update at the end.
9. **Never interrogate the user.** No upfront questionnaire, no field-by-field prompting. Derive
   what you can; leave what you cannot **blank** and move on. A blank the user fills in ten seconds
   beats five questions they answer before anything happens. The same applies to recommended
   answers — if the basis for one is not there, leave it blank rather than inventing it.

---

## Step 0 — Context and the description block

Resolve the Tracker ticket (ask only if it was not given; read it back by subject to confirm).

Then derive **only two things**. Do not build the rest of the pack yet.

### Sources — no interrogation

| Source | What it yields |
|---|---|
| **The current conversation** | Usually the bulk of it. The investigation that produced this request is normally right here — verbatim errors, IDs, versions, what was ruled out and how. Use it first. |
| **Tracker ticket** (`get_issue`) — description and journals | Subject, symptom, root cause, what was already tested, pasted email threads, prior error text |
| **Parsing the error text** from either source | Environment / organization / tenant IDs, app and platform versions, SystemUserId, Entra object ID, access mode, privilege name, error code |
| **Microsoft Learn search** on the privilege or error string | The documented match and its heading anchor — `mcp__claude_ai_Microsoft_Learn__microsoft_docs_search` |
| **Drafted from the above** | The numbered questions for Microsoft, and every recommended answer |

Anything still unknown at the end is left **blank** for the user to fill. Never ask for it up front.
**Corroboration** is the item that tends to be unrecoverable — "I set Read-Write and it reverted"
appears in no log. Take it from the conversation or the journals if it is there; otherwise leave it
blank.

### 1. The description block — eager

The text that gets pasted into the portal's description field. Print it **in a fenced code block**
so it can be copied straight out. Include, in this order:

- The verbatim error
- Environment and account IDs
- Correlation ID, timestamp, client machine name — Microsoft's FAQ requires all three
- Corroborating evidence: what rules out a local or tool-specific cause
- The relevant Microsoft documentation link
- The numbered questions for Microsoft

It is eager because the portal asks for it at step 2, and because deriving it mid-wizard strands
the user in front of a live form that can time out.

`reference/example-19119.md` is a fully worked one — read it for the shape and the level of
detail, not for its contents.

### 2. The attachment list — a note, not a step

Print it as a note. **Nothing waits on it.** Attachments are not required to create the request;
Microsoft's first reply often asks for them and they can be added then. If one is unobtainable,
say so in the ticket rather than stalling.

Show the description block once, with unknown fields left visibly blank, let the user correct
anything wrong, then open the browser.

Everything else — category, subcategory, whatever clarifying questions the support agent invents,
the environment picker — is **resolved on demand** when the portal actually asks. Do not
pre-compute answers to questions you cannot predict.

---

## Step 1 — Open the browser

Load the Chrome tools in **one** `ToolSearch` call:

```
select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__get_page_text
```

Call `tabs_context_mcp` first. Create a **new tab** — do not hijack an existing one — and navigate
to:

```
https://admin.powerplatform.microsoft.com/support/requests
```

**Always the Power Platform admin center.** Lifecycle Services is out of scope: do not route to it,
do not mention it, do not build a walkthrough for it.

If the extension is unavailable, stop here and say so. The description block from Step 0 already
stands on its own — the user can file it by hand, or hand it to someone else who will.

## Step 2 — Sign-in

Tell the user to sign in. Do not touch it. Wait for their cue, then read the page to verify they
landed on **Support requests**.

## Step 3..N — The guided loop

For each step:

1. Give the instruction — menu path as `A > B > C`, one action per numbered line.
2. Where the portal asks something, supply a **recommended answer** in a code block.
3. Close with "tell me when that's done" — no y/n, no "what happened?".
4. On their next message, **read the page** and determine the actual state from it.
5. If the page does not match what the step expected, say so and guide the correction instead of
   advancing.

Portal flow to expect. PPAC leads with a **Support agent** pane; a **Switch to web form** fallback
exists and both must be handled.

1. **Get support** — the Support agent pane opens
2. Describe the issue, then confirm or correct the **predicted product**
3. Answer the clarifying questions; **Category** / **Subcategory** if asked
4. Review the generated self-help solutions
5. **Create a support request**
6. **Technical** vs Advisory · support plan · **severity** · date the issue occurred
7. Affected environment — if it is not listed, "My environment is not listed" and paste the URL
8. Contact preferences and **advanced diagnostic consent**
9. The user clicks **Create support request**

### Recommendations to make

| Portal field | Recommend | Why |
|---|---|---|
| Product | **Power Platform Administration**, for a Dataverse issue on a Power Platform-managed environment | Picking "Dynamics 365 Customer Service" is documented as causing misrouting and delay |
| Request type | **Technical** | Submitting Technical when you wanted Advisory gets the case closed; a genuine fault is Technical |
| Severity | **B**, or C | Severity A commits you to staying engaged until it is resolved and is auto-downgraded if you cannot. Development blocked with no production impact is B |
| Diagnostic consent | **Grant** | Without it Microsoft cannot access the environment and will come back to ask, losing a day |

Fit these to the case in front of you — but always give the reason, not just the value.

## Step N+1 — Capture the Microsoft ticket number

Read it off the confirmation page — a 16-digit case number, e.g. `2608020030001071`. Show it to
the user and have them **confirm it is correct** before anything is written to Tracker.

## Step N+2 — Write it into Principal Case #

**Principal Case # holds the Microsoft support ticket ID, and it is filled as soon as the support
request exists** — not when Microsoft first replies, and not at closure. It is what links the
Tracker case to Microsoft's, so anyone picking the ticket up can find the Microsoft thread.

Do this in the same session, immediately after Step N+1. If the write cannot be made — the field
rejects the value, the ticket id is wrong — say so plainly rather than leaving the user thinking
the link was recorded.

1. **Principal Case # is `cf 43`.** Do not call `list_custom_fields` to confirm it — that endpoint
   requires admin and errors on this account. `cf 43` is verified against #18932, where the
   Microsoft case number `2608020030001071` was written to it when the ticket moved to
   *In Progress: Customer*.

   Take care not to reach for a neighbouring field: on #19119, `cf 51` is *Customer Work Item* —
   the Azure DevOps work item — and `cf 52` / `cf 53` are Resolution and Resolution Date, which
   belong to `close-ticket`. If you want to sanity-check before writing, `get_issue` on a ticket
   that already went to Microsoft and confirm `cf 43` holds a 16-digit case number.
2. Show the user the field and the value about to be written.
3. On confirmation, `update_issue` setting **only** that custom field. Do not touch `status_id`,
   `assigned_to_id`, `done_ratio`, or anything else.

Confirm in one line that the field is set, and stop. The job is done.
