---
name: raise-ms-support-ticket
description: Raise a Microsoft support request in the Power Platform admin center — draft the description and the answers to Microsoft's questions, get them approved in one pass, then either hand the user a guide pack to file it themselves or drive Chrome and submit it for them — and write the resulting Microsoft ticket number into the Tracker ticket's Principal Case # field. Use when the user asks to raise, file, log or open a ticket with Microsoft on a D365FO / Power Platform issue.
argument-hint: "[ticket no]"
---

# raise-ms-support-ticket

Get a Microsoft support request filed against a Tracker case, and link the two.

**The pack comes first, then one question.** You draft the description and the answers Microsoft
will ask for, show them, and ask a single question that approves the content *and* picks the path:

| | **Path A — Guide pack** | **Path B — Driven in Chrome** |
|---|---|---|
| Who files it | The user, at their own pace | You |
| After approval you send | Nothing more — they have the pack | Live progress, one screenful per step |
| User sends back | A screenshot or paste only if something is off-script | Nothing, unless the portal asks something the pack did not cover |
| Who submits | The user clicks Create | **You click Create** |
| Setup | None | One-time extension install, ~30s |

**The approval is the gate.** In Path B nobody reviews the form before it reaches Microsoft, so the
pack the user approved is the whole of their review. That makes one rule load-bearing: **if the
portal asks something the approved pack does not answer, stop and ask.** Never improvise past the
approval — a request filed under the user's name on a real customer case is not reversible by
editing the form.

**Done when** the support request exists and its number is in the Tracker ticket's
**Principal Case #** field. Tracking Microsoft's replies, chasing, escalating, or posting their
answers back to Tracker is *not* this skill — that is the normal email and Tracker skills.

---

## Hard rules

1. **Never ask for, receive, or type credentials.** The user signs in. You wait and read the page.
2. **Create is clicked only against an approved pack.** *Path A:* the user clicks it. *Path B:*
   you click it, but only once the pack has been approved at Step 0 and only if every answer you
   entered came from that pack. No approval, no submit.
3. **Anything the approved pack does not answer stops the flow.** A clarifying question from the
   Support agent pane, a field you did not anticipate, a value that turns on the user's judgement
   — stop, show it, recommend an answer, wait. This is the rule that keeps Path B honest; without
   it "the user approved the pack" quietly becomes "the user approved whatever I decided".
   Derived facts you parsed yourself — environment ID, verbatim error text, correlation ID — are
   already in the pack and need no second approval.
4. **The page is the source of truth, never the user's description.** *Path B and the Path A
   screenshot fallback:* treat the user's next message — whatever it says — purely as the cue to
   read the page. The browser tools are pull-only, so the cue is only for *timing*; the *state*
   always comes from the page. A validation error after Next is the common desync, and only the
   page reveals it. A **screenshot** is the page; the user's description of it is not.
5. **Do not check role or support-plan prerequisites.** Invoking the skill means the user has
   already confirmed them. Do not re-litigate.
6. **Never trigger browser dialogs** (alert / confirm / prompt) — they block the extension.
7. **Stop and ask after 2–3 failed browser calls.** Do not loop. This ceiling also governs the
   Path B setup poll.
8. **Write no files.** Everything goes to chat as markdown. No scratch files, no saved pack, no
   logs. The only thing written anywhere is the one Tracker field update at the end.
9. **Produce first, then ask once.** Build the pack before you ask anything. The Step 0
   approve-and-choose question is the *only* question you may put to the user before work starts
   — no questionnaire, no field-by-field prompting. Derive what you can; leave what you cannot
   **blank** and move on. A blank the user fills in ten seconds beats five questions they answer
   before anything happens. Same for recommended answers — if the basis for one is not there,
   leave it blank rather than inventing it.
10. **Path B: one screenful per step.** The action, one line of why. No case recaps, no previews
    of later steps, no re-justifying a decision already approved. **This does not apply to the
    Step 0 pack**, which is deliberately one larger message.

---

## Step 0 — Resolve the ticket, build the pack, ask once

Resolve the Tracker ticket (ask only if it was not given; read it back by subject in one line to
confirm). Then **build the pack and show it** — before any question, before opening any browser.

This is the one place the "no wall of text" instinct is deliberately off. The pack is new
information the user cannot produce themselves, and in Path B it is the only review they get.

### Where the material comes from

Build every piece of it from these, in order, without interviewing the user:

| Source | What it yields |
|---|---|
| **The current conversation** | Usually the bulk of it. The investigation that produced this request is normally right here — verbatim errors, IDs, versions, what was ruled out and how. |
| **Tracker ticket** (`get_issue`) — description and journals | Subject, symptom, root cause, what was already tested, prior error text |
| **Parsing the error text** from either source | Environment / organization / tenant IDs, versions, SystemUserId, Entra object ID, access mode, privilege name, error code |
| **Microsoft Learn search** on the privilege or error string | The documented match and its heading anchor — `mcp__claude_ai_Microsoft_Learn__microsoft_docs_search` |

Anything you cannot find is left **blank** for the user to fill. Never ask for it up front.

### The pack

#### 1. The URL

```
https://admin.powerplatform.microsoft.com/support/requests
```

#### 2. The description block

A fenced code block, the text only, ready to paste. Include the verbatim error, the environment
and account IDs, the correlation ID / timestamp / client machine name Microsoft's FAQ requires,
the evidence ruling out a local cause, the Learn link, and numbered questions.

`reference/example-19119.md` is a fully worked one — read it for the shape, not the contents.

Say nothing about it beyond what it is. Do not narrate what is in it.

#### 3. Likely asks, and how to answer

Head this section **"Likely asks — not a script."** The Support agent pane generates clarifying
questions per case and Microsoft reshuffles the wizard, so some of this will not match. Say that
in the pack itself, in one line, or the first mismatch makes the user distrust the whole thing.

The fixed choices, each with its one-line reason:

| Portal field | Recommend | The one-line reason |
|---|---|---|
| Product | **Power Platform Administration**, for a Dataverse issue on a Power Platform-managed environment | Wrong product means misrouting and days lost |
| Request type | **Technical** | Advisory gets a genuine fault closed rather than fixed |
| Severity | **B**, or C | A commits you to round-the-clock engagement and is auto-downgraded if you cannot |
| Affected environment | Pick it from the list; if absent, **"My environment is not listed"** and paste the URL |  |
| Diagnostic consent | **Grant** | Without it Microsoft cannot look, and comes back to ask — a day gone |

Then the case-specific ones you can anticipate — the predicted-product confirmation, the
category / subcategory if the case suggests one, the date the issue occurred. Give the
recommended answer in a code block wherever it is text to paste.

Fit these to the case in front of you. Give the reason once, in one clause.

#### 4. Attachments

One line, and only if relevant: not required to create the request, Microsoft's first reply
usually asks, and anything unobtainable should be stated in the ticket rather than stalling
the filing.

### The question

**One** `AskUserQuestion`, two options. Both encode approval; a correction arrives through the
auto-added *Other*, so do not add a "something's wrong" option of your own and do not split this
into two questions.

- **"Looks right — give me the guide, I'll file it"** — you keep the pack and work through the
  portal at your own pace.
- **"Looks right — you drive it in Chrome and submit"** — I fill the form and click Create.
  One-time extension setup, about 30 seconds.

Do **not** pre-check whether the extension is connected before asking. If they pick Path B and it
is not connected, Step B0 handles it.

If they come back with a correction instead, fix the pack, show the changed part only, and ask
again — not the whole pack a second time.

**Always the Power Platform admin center.** Lifecycle Services is out of scope: do not route to
it, do not mention it, do not build a walkthrough for it.

---

## Path A — They file it

The pack is already sent. Add two instructions, no more:

> Anything that doesn't match the above — a question not on this list, a validation error, a
> screen that looks wrong — screenshot it or paste it here and I'll answer it.
>
> When the request is created, reply with the case number and I'll write it into Tracker.

Do **not** offer "or paste it into Tracker yourself". Two choices means some users do neither and
Principal Case # stays empty.

Then stop. Do not follow up unprompted.

### When they come back mid-flow

A screenshot or a pasted question is the cue to answer *that one thing* and hand control back —
not to switch into a step-by-step loop. Rule 4 applies: read the screenshot, do not ask them to
describe it. If they clearly want you to take over from there, switch to Path B.

---

## Path B — You file it

### Step B0 — Setup, done by you wherever it can be

Load the tools in **one** `ToolSearch` call:

```
select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__get_page_text
```

Then call `tabs_context_mcp`. If it returns tabs, setup is already done — say nothing about it
and go to Step B1.

If it fails, do the automatable half yourself and hand the user only what is physically theirs:

- **You:** register the MCP server if it is missing (`claude mcp list`, then add it).
- **You:** verify the connection by polling `tabs_context_mcp`. Do **not** ask "have you done it
  yet?" — detect it.
- **The user, unavoidably:** the Chrome Web Store install and the site-permission grant. Both are
  browser-UI clicks behind a security boundary, and the extension is the very thing that would
  let you click them.

Give it as one link and two clicks, not a paragraph:

> Install: https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn
> Add to Chrome → then click the Claude icon and allow `admin.powerplatform.microsoft.com`.
> I'll pick it up automatically. (Setup guide: https://code.claude.com/docs/en/chrome)

Poll for the connection under the rule 7 ceiling. If it is still not up, say so plainly and offer
to drop to Path A. Do not keep retrying.

### Step B1 — Open the portal

Create a **new tab** (do not hijack an existing one) and navigate to:

```
https://admin.powerplatform.microsoft.com/support/requests
```

Read the page yourself after each step. Do not ask for screenshots.

### Step B2 — Sign-in

Tell the user to sign in. Do not touch it. Then confirm from the page that they landed on
**Support requests**.

### Step B3..N — Fill the form

Per step: **the action, then the reason in one short line.** That is the whole shape.

1. What you are entering or clicking — one action per numbered line.
2. Why, in **one sentence at most**, and only where the choice is not obvious. Skip it entirely
   for a plain "clicking Next".
3. Enter the approved answer. It came from the pack; do not re-justify it.
4. **Rule 3 check:** if the portal asks something the pack does not answer, stop, show it,
   recommend an answer, and wait. Do not answer it yourself.
5. Read the page and work out the real state from it.
6. If it does not match what the step expected, say so and correct rather than advancing.

**Keep it short.** One screenful per step. The user is watching a live form that can time out, on
a phone-sized terminal pane. Do not restate the case, do not re-explain a decision already
approved.

Wrong:

> Selecting **No**. This has nothing to do with Copilot Studio. Getting the product wrong here is
> the documented cause of misrouting and days of delay, so it's worth correcting firmly. If it
> then asks you to name the product or offers a picker, aim for Power Platform Administration…

Right:

> Selecting **No** — wrong product, and misrouting here costs days.

### The wizard, for your own orientation

PPAC leads with a **Support agent** pane; a **Switch to web form** fallback exists and both must
be handled. The stages, roughly:

1. **Get support** — the Support agent pane opens
2. Describe the issue, then confirm or correct the **predicted product**
3. Clarifying questions; **Category** / **Subcategory** if asked
4. Generated self-help solutions to review
5. **Create a support request**
6. **Technical** vs Advisory · support plan · **severity** · date the issue occurred
7. Affected environment — if it is not listed, "My environment is not listed" and paste the URL
8. Contact preferences and **advanced diagnostic consent**
9. **Create support request** — you click it, against the approved pack

This list is for you, not for the user. Do not print it as a preview of what is coming — take the
stages one at a time as the portal reaches them.

### Step B-final — Submit, then report what went in

Click **Create support request**. Then, in one short block, tell the user what was actually
submitted: product, request type, severity, environment, diagnostic consent. They approved a
prediction of the form; they should see the form that existed.

If anything went in differently from the approved pack — the portal forced a value, a field was
not offered — say which, plainly. Do not let a divergence pass silently just because the request
succeeded.

---

## Step N+1 — Capture the Microsoft ticket number

*Path A:* the user replies with it. *Path B:* read it off the confirmation page.

A 16-digit case number, e.g. `2608020030001071`. Show it to the user and have them **confirm it
is correct** before anything is written to Tracker.

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
