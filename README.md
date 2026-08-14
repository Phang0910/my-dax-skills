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

### draft-progress

Writes up what you just did, in the short format that suits a PM or functional consultant —
what changed, the user-facing message, the feature gate, and anything deliberately left alone.
No element lists, no file paths, no build logs.

It resolves the ticket number from context (conversation, project folder name, handoff doc),
reads the ticket back to show you its subject, and **always** asks before posting. Nothing
reaches the Tracker until you confirm.

Requires the Tracker MCP server to be connected.

## Adding a skill

Create `skills/<name>/SKILL.md` with frontmatter:

```markdown
---
name: <name>
description: <when Claude should use this skill>
---
```

Commit and push, then `/plugin marketplace update my-dax-skills` on each machine.
