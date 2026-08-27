---
name: raise-ms-support-ticket
description: Guide the user step by step through raising a Microsoft support request in the Power Platform admin center — reading the live browser, or their screenshots — then write the resulting Microsoft ticket number into the Tracker ticket's Principal Case # field. Use when the user asks to raise, file, log or open a ticket with Microsoft on a D365FO / Power Platform issue.
argument-hint: "[ticket no]"
---

# raise-ms-support-ticket

Guide the user through the Power Platform admin center while they file a Microsoft support
request, then write the Microsoft ticket number back to Tracker.

**The user drives the browser.** You observe, guide, draft text to paste, and recommend answers.
You never fill the form and you never submit it.

**Start at the browser.** No evidence pack, no description block, no case summary before the
portal is open. Every piece of text is produced at the moment the portal asks for it, and each
step is an instruction plus at most one line of why.

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
   is the common desync, and only the page reveals it. Without the extension, a **screenshot** is
   the page — ask for one per step and read it the same way.
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
10. **One screenful per step.** The instruction, one line of why, and the text to paste. Nothing
    else. No case recaps, no previews of later steps, no re-justifying a decision already taken.

---

## Step 0 — Resolve the ticket, then go

Resolve the Tracker ticket (ask only if it was not given; read it back by subject in one line to
confirm). Then **open the browser**.

That is the whole of Step 0. Do not print an evidence pack, a description block, an attachment
list, or a summary of the case up front. The user filing the ticket already knows the case —
a wall of text before anything happens is time spent reading back what they told you.

Everything the portal needs is produced **at the moment the portal asks for it**, and nothing
sooner.

### Where the material comes from

When you do need to produce something — the description text, an answer to a clarifying question —
build it from these, in order, without interviewing the user:

| Source | What it yields |
|---|---|
| **The current conversation** | Usually the bulk of it. The investigation that produced this request is normally right here — verbatim errors, IDs, versions, what was ruled out and how. |
| **Tracker ticket** (`get_issue`) — description and journals | Subject, symptom, root cause, what was already tested, prior error text |
| **Parsing the error text** from either source | Environment / organization / tenant IDs, versions, SystemUserId, Entra object ID, access mode, privilege name, error code |
| **Microsoft Learn search** on the privilege or error string | The documented match and its heading anchor — `mcp__claude_ai_Microsoft_Learn__microsoft_docs_search` |

Anything you cannot find is left **blank** for the user to fill. Never ask for it up front.

---

## Step 1 — Is Claude in Chrome available?

Check before promising to drive anything. Load the tools in **one** `ToolSearch` call:

```
select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__get_page_text
```

Then call `tabs_context_mcp`. It either returns the user's tabs or it fails.

### Connected — drive the browser

Create a **new tab** (do not hijack an existing one) and navigate to:

```
https://admin.powerplatform.microsoft.com/support/requests
```

Read the page yourself after each step. Do not ask for screenshots.

### Not connected — run on screenshots

Say so in one line and give them the link:

> Claude in Chrome isn't connected here, so I can't read the page myself. Install it from
> https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn (setup:
> https://code.claude.com/docs/en/chrome), or just send me a screenshot at each step and I'll
> guide you the same way.

Then run the identical flow, with **a screenshot standing in for the page read**. Ask for one
screenshot per step — that is all you need, and it is enough. Do not ask the user to describe
what happened in words; rule 4 holds either way, because a screenshot is the page and their
description is not.

Tell them the URL to open themselves:
`https://admin.powerplatform.microsoft.com/support/requests`

**Always the Power Platform admin center.** Lifecycle Services is out of scope: do not route to
it, do not mention it, do not build a walkthrough for it.

## Step 2 — Sign-in

Tell the user to sign in. Do not touch it. Then confirm from the page (or their screenshot) that
they landed on **Support requests**.

## Step 3..N — The guided loop

Per step: **the instruction, then the reason in one short line.** That is the whole shape.

1. What to click — menu path as `A > B > C`, one action per numbered line.
2. Why, in **one sentence at most**, and only where the choice is not obvious. Skip it entirely
   for a plain "click Next".
3. Where the portal asks for text, give it in a code block — the text only, no preamble.
4. Close with "tell me when that's done" — no y/n, no "what happened?".
5. On their cue, read the page (or their screenshot) and work out the real state from it.
6. If it does not match what the step expected, say so and guide the correction rather than
   advancing.

**Keep it short.** One screenful per step. The user is in front of a live form that can time out,
and they are reading you on a phone-sized terminal pane. Do not restate the case, do not
re-explain a decision already made, and do not pad a recommendation with its full justification —
the reason is one clause, not a paragraph.

Wrong:

> Click **No**. This has nothing to do with Copilot Studio. Getting the product wrong here is the
> documented cause of misrouting and days of delay, so it's worth correcting firmly. If it then
> asks you to name the product or offers a picker, aim for Power Platform Administration…

Right:

> Click **No** — wrong product, and misrouting here costs days.
>
> If it asks you to name the product, paste:
> ```
> Power Platform Administration - Dataverse privilege failure on a Unified Developer
> Environment during module deployment from Visual Studio.
> ```

### The wizard, for your own orientation

PPAC leads with a **Support agent** pane; a **Switch to web form** fallback exists and both must be
handled. The stages, roughly:

1. **Get support** — the Support agent pane opens
2. Describe the issue, then confirm or correct the **predicted product**
3. Clarifying questions; **Category** / **Subcategory** if asked
4. Generated self-help solutions to review
5. **Create a support request**
6. **Technical** vs Advisory · support plan · **severity** · date the issue occurred
7. Affected environment — if it is not listed, "My environment is not listed" and paste the URL
8. Contact preferences and **advanced diagnostic consent**
9. The user clicks **Create support request**

This list is for you, not for the user. Do not print it as a preview of what is coming — take the
stages one at a time as the portal reaches them.

### The description field

When the portal reaches the description, produce the block **then** — in a fenced code block, the
text only, ready to paste. Include the verbatim error, the environment and account IDs, the
correlation ID / timestamp / client machine name Microsoft's FAQ requires, the evidence ruling out
a local cause, the Learn link, and numbered questions.

`reference/example-19119.md` is a fully worked one — read it for the shape, not the contents.

Say nothing about it beyond "paste this into the description field". Do not narrate what is in it.

### Attachments

Mention them **once**, in one line, and only if the portal offers an upload: attachments are not
required to create the request, Microsoft's first reply usually asks, and anything unobtainable
should be stated in the ticket rather than stalling the filing.

### Recommendations to make

| Portal field | Recommend | The one-line reason |
|---|---|---|
| Product | **Power Platform Administration**, for a Dataverse issue on a Power Platform-managed environment | Wrong product means misrouting and days lost |
| Request type | **Technical** | Advisory gets a genuine fault closed rather than fixed |
| Severity | **B**, or C | A commits you to round-the-clock engagement and is auto-downgraded if you cannot |
| Diagnostic consent | **Grant** | Without it Microsoft cannot look, and comes back to ask — a day gone |

Fit these to the case in front of you. Give the reason, but give it once and in one clause.

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
