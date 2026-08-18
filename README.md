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
