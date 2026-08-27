# my-dax-skills

Personal Claude Code skills for D365FO / Dynamics work.

This repo is both a **plugin marketplace** and the **plugin** itself, so one `marketplace add`
plus one `install` is all it takes on a new machine.

## Install

```
/plugin marketplace add Phang0910/my-dax-skills
/plugin install my-dax-skills@my-dax-skills
```

Then restart Claude Code. Skills are invoked namespaced by the plugin:

```
/my-dax-skills:draft-progress
```

## Skills

| Skill | What it does |
|---|---|
| `draft-progress` | Drafts a short progress/completion note for a Tracker (Redmine) ticket in the house format, shows it with the ticket number for confirmation, then posts it to the ticket. |
| `draft-email` | Drafts a reply email to a customer or vendor in the house style, then hands it back for you to review and send yourself. |
| `draft-acknowledge-email` | Drafts the first-response acknowledgement email for a newly registered support case — confirms the Support Case ID and the assigned consultant, both read off Tracker. |
| `draft-closing-email` | Drafts the final ticket-closure email for a resolved support case, in the DAXONET closure format, with the consultant hours taken from Tracker rather than the template. |
| `draft-follow-up-email` | Drafts the chaser email on a case the customer has gone quiet on — picks the 1st/2nd follow-up, the 3rd that warns of closure, or the system-behaviour archive request, recommending the stage from the ticket's journals. |
| `raise-ms-support-ticket` | Guides you through raising a Microsoft support request in the Power Platform admin center — drafts the description block, watches the live browser to stay in step, then writes the Microsoft ticket number into the Tracker ticket's Principal Case # field. |
| `close-ticket` | Closes a resolved Tracker ticket — sets the status, picks the Root Cause from the dropdown, writes the Resolution in the internal house style, and stamps today as the Resolution Date. The natural next step after `draft-closing-email`. |
| `weekly-report` | Drafts this week's Customer Success Weekly Report in DAXONET Notes, pulled from the Tracker. |
| `update-weekly-report` | Refreshes an existing weekly report doc — re-pulls the week, folds in what landed since, tightens the prose. |

### draft-progress

Writes up what you just did, in the short format that suits a PM or functional consultant —
what changed, the user-facing message, the feature gate, and anything deliberately left alone.
No element lists, no file paths, no build logs.

It resolves the ticket number from context (conversation, project folder name, handoff doc),
reads the ticket back to show you its subject, and **always** asks before posting. Nothing
reaches the Tracker until you confirm.

Requires the Tracker MCP server to be connected.

### draft-email

Writes a reply in the way the team actually writes to customers — short, plain labels
(`What is needed:`, `Steps:`, `To confirm:`), menu paths as `A > B > C`, closing on
`Do let me know if you have any further questions.`

It reads the existing thread off the Tracker ticket first, so it picks up the real recipient
list and the exact subject line — including the `[#id]` prefix that files the reply back into
Tracker. It answers every question the other side asked, and adds a verification step so the
thread does not bounce back unverified.

**It never sends.** The draft comes back in chat for you to review. It can save an Outlook draft
if you ask, but sending is always yours.

Tracker MCP for reading the thread; Microsoft 365 MCP only if you want the Outlook draft.

### draft-acknowledge-email

Writes the opening acknowledgement — the email that tells the customer their request is
registered and gives them the reference they will quote for the rest of the case. Two detail
lines only, `Support Case ID` and `Assigned Consultant`, as one compact block, first names only.

It reads both values off the Tracker ticket rather than the user's summary, since being wrong
about them is the only way this email can fail. If the ticket has no assignee yet it asks instead
of guessing, and it flags the cases where a first response would look odd — replies already
traded on the thread, or a requester who is not the ticket author.

Deliberately says nothing about the issue itself. No ETA, no first findings, no questions — that
is the next email, drafted with `draft-email`.

**It never sends.**

Requires the Tracker MCP server.

### draft-closing-email

Writes the final closure email for a resolved case, in the format actually in use: the detail
block (`Support Case ID`, `Reported By`, `Consultant Assigned`, `Summary of Resolution`,
`Consultant Hours`) as one compact run with no blank lines, first names only, signed off
`Best Regards, Jun Phang`.

Two things it does that save a round trip. It reads `spent_hours` off the Tracker ticket instead
of trusting the placeholder figure that circulating copies of the template carry, and it keeps
the Summary of Resolution to one plain-language sentence — no class names, environments or
deployment detail.

It also reads the last few journals before drafting and flags when closure looks premature — a
data fix not yet run, a deployment still unscheduled, or a customer question that was only
answered on a call. It still shows you the draft; it just tells you what it noticed.

**It never sends.**

Requires the Tracker MCP server.

### draft-follow-up-email

Writes the chaser for a case awaiting the customer's reply. Three standing templates: **A** for
the first follow-up (the next working day after the resolution went out) and the second (three
business days later), **B** for the third, which adds `otherwise we'll proceed to set this case to
close`, and **C** for cases whose answer was "this is system behaviour" and which we want
archived.

It counts the chasers already on the ticket and recommends the stage, so you do not have to read
back through the journals — you still choose. It also flags when the chaser is the wrong email:
the customer already replied and is waiting on us, the gap is too short, or we are the ones
holding an open commitment. After Template B the next step is `draft-closing-email`, not a fourth
chaser.

**It never sends.**

Requires the Tracker MCP server.

### raise-ms-support-ticket

Files a Microsoft support request without you having to hold the whole case in your head in front
of a form that times out.

It builds one thing up front — the **description block**, in a code block ready to paste: the
verbatim error, the environment and account IDs, the correlation ID and timestamp Microsoft's FAQ
insists on, the evidence that rules out a local cause, the Learn link, and numbered questions.
Everything else is resolved on demand, when the portal actually asks. Attachments are printed as a
note, never as a gate — the request can be created without them.

It derives the pack from the conversation you are already in plus the Tracker ticket, and leaves
what it cannot find **blank**. No questionnaire.

Then it guides you through the Power Platform admin center — Support agent pane or the web-form
fallback — one instruction at a time, reading the live page after each step so a validation error
does not put the two of you out of sync. It recommends the answers that matter (Power Platform
Administration, Technical, Severity B, grant diagnostic consent) with the reason each one costs you
a day if you get it wrong.

**It never signs in and it never clicks Create support request.** You do both. Afterwards it reads
the ticket number off the confirmation page, shows it to you, and on your confirmation writes it to
the Tracker ticket's Principal Case # field (`cf 43`), the only field it touches. Then it stops; chasing Microsoft's reply is the email skills' job.

Always PPAC, never Lifecycle Services. Needs the Tracker MCP and the `claude-in-chrome` extension —
though with no browser it still gives you a description block you can file by hand.

### close-ticket

Closes the ticket the way it is supposed to be closed — status, **Root Cause**, **Resolution** and
**Resolution Date**, in one update, rather than a status change that leaves the reporting fields
empty.

It recommends a Root Cause from the nine dropdown values with a reason drawn from the ticket, then
asks you to confirm it, since an unconfirmed dropdown value is the kind of thing that quietly
skews a quarter's reporting. For the Resolution it starts from the Summary of Resolution
`draft-closing-email` produced, but keeps the technical specifics that email drops — the number
sequence, the table, the fact that the fix was a SQL update in the notes — because this field is
the internal record, not the customer's copy.

It reads the field ids directly (`cf 7`, `cf 52`, `cf 53`) rather than calling
`list_custom_fields`, which needs admin and errors on this account, and it touches nothing else —
no `done_ratio`, no reassignment, no note.

It also flags a premature close before showing you the values: work still outstanding, an
unanswered customer question, or a case still waiting on Microsoft with the Principal Case # open.
`Rejected` is handled as its own path — Root Cause only, no Resolution, since nothing was resolved.

**Nothing is written until you confirm**, and the confirmation shows the ticket number and subject.

Requires the Tracker MCP server.

### weekly-report

Pulls the week off the Tracker and writes the Customer Success Weekly Report into DAXONET Notes
in the house format.

### update-weekly-report

Refreshes a weekly report that already exists. It rewrites and curates the whole report rather
than appending bullets to the bottom — re-pulls the week, folds in what landed since, and tightens
what is already there.

Both are `disable-model-invocation`, so they only run when you invoke them by name.

## Adding a skill

Create `skills/<name>/SKILL.md` with frontmatter:

```markdown
---
name: <name>
description: <when Claude should use this skill>
---
```

Then **bump `version` in `.claude-plugin/plugin.json`** — this step is not optional. The plugin
cache is keyed by version (`~/.claude/plugins/cache/my-dax-skills/my-dax-skills/<version>/`), so
if the version is unchanged, `marketplace update` refreshes the marketplace metadata but never
re-extracts the plugin. The new skill is pushed, present in the repo, and still invisible in
Claude Code.

Commit and push, then on each machine:

```
/plugin marketplace update my-dax-skills
```

and restart Claude Code. To confirm it landed, check that a directory for the new version exists
under the cache path above and contains your skill.
