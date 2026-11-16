---
name: setup-mydaxskills
description: Check what the my-dax-skills plugin needs on this PC — connectors, browser, standard D365FO code, and optionally projects' custom code — and set up or guide the user through anything missing.
disable-model-invocation: true
---

# setup-mydaxskills

Check every piece the my-dax-skills plugin needs, show one checklist, and fix each missing piece.
Other skills send the user here when they find a missing piece.

**Terms.** A **project** is a DAXONET client engagement: one D365 environment and its code, one
row in the project map (for example MTM). The Tracker project of a ticket points to one project;
the names can differ (Tracker "Maxell Tohshin" is project MTM). A **D365 project** is a Projects
module record (`ProjId`). A **legal entity** is the D365 company (`DATAAREAID`, `cmp=`).

**Projects matter only for custom code.** The general pieces (connectors, browser, standard
code) are the same for everyone and are the only required rows. Custom code is one **optional**
row per project in the project map, so a user can set up the plugin before any ticket exists.

A **ticket project** is the one exception: when this conversation already has a ticket (or
`analyse-ticket`'s checkpoint named its project), that project's custom code row is
**required**, because the analysis waits on it. Match the ticket's Tracker project to a project
in the project map in `C:\D365Std\CLAUDE.md`. The user never types a project.

**You do the work you can do:** checks, the standard code extraction, the Git install, a Git
clone, the TFVC REST download, and folder access requests. **The user does** sign-ins, tokens,
connector connections, the Chrome extension, and Visual Studio. Each row in Step 3 says who does
what.

**Done when** every **required** row is ✅, or the user chose to leave a row for later and it is
marked ⏸ in the final checklist.

## Step 1 — Run every check

Run all checks before you show anything. Collect every result first; the one question comes in
Step 2.

### Connectors

For each connector, use `ToolSearch` with the keywords below. The tool names differ between
Claude apps (some use `mcp__claude_ai_<Name>__…`, some use an id), so match on the tool's purpose,
not its prefix. A connector is ✅ when its tool loads **and** one cheap read call succeeds.

| Connector | ToolSearch keywords | Read call | Needed by |
|---|---|---|---|
| Tracker (Redmine) | `redmine issue get_issue` | `get_current_user` | every skill — **required** |
| DAXONET Notes | `notes documents list_documents` | `list_documents` with a one-word query | `kb-this`, `update-weekly-report`, `analyse-ticket` |
| Microsoft Learn | `microsoft docs search` | `microsoft_docs_search` with `"purchase order"` | `analyse-ticket`, `raise-ms-support-ticket` |
| Microsoft 365 | `outlook email search` | `get_me` or a one-result email search | `draft-email` (Outlook draft only — optional) |

A tool that loads but fails with an authorization error is ❌ **sign-in needed**, not missing.

### Browser

- **Claude in Chrome**: load `mcp__claude-in-chrome__tabs_context_mcp` with `ToolSearch` and call
  it. Tabs returned → ✅.
- **Built-in browser**: `mcp__Claude_Browser__*` tools are present → ✅.

One of the two is enough for `analyse-ticket`. Claude in Chrome is the default; the built-in
browser is the fallback. `raise-ms-support-ticket` Path B needs Claude in Chrome.

### Code for `analyse-ticket` (Claude Code only)

Skip this group in Chat and Cowork, and say why in one line: they cannot read folders on this PC.

1. **Standard code**: `C:\D365Std\CLAUDE.md` exists, and each version folder it lists has
   `ApplicationSuite\`. On a dev VM without `C:\D365Std`, a local
   `%LOCALAPPDATA%\Microsoft\Dynamics365\<version>\PackagesLocalDirectory\` also counts.
2. **Standard code in this session**: `C:\D365Std` is the working directory or an added folder of
   this session. On disk but not in the session → ❌ **not added to Claude**.

Then, for **every project in the project map** (skip this part while standard code is missing —
the map is inside it):

3. **The project's row**: repo type (`Git:` or `TFVC:`), repo URL or server path, signature
   models.
4. **Custom code**: a folder of one of its signature models in the working directory or an added
   folder. Found → ✅ with the path. On disk at `C:\Custom\<Project>` but not in the session →
   ❌ **not added to Claude**. Not found → ⏸ for most projects; ❌ for the ticket project.
5. **Tools for that repo type** — check them only for projects the user picks in Step 3, and for
   the ticket project:
   - Git → `git --version` runs.
   - TFVC → `tf.exe` exists
     (`& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -find "Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\tf.exe"`),
     or, without Visual Studio, a saved token at `%LOCALAPPDATA%\my-dax-skills\azdo-pat-<org>.xml`.

### Checked by its own skill

`update-es-weekly-sheet` checks Claude Code and the SharePoint folder sync itself when it runs.
List it as ➖ with that note.

## Step 2 — Show the checklist

Summary first, in ASD-STE100 style (short sentences, active voice, one term per thing):

```
Setup: <n> of <m> required items ready. <k> optional items missing.

| Item | Status | Needed by | Fix |
|---|---|---|---|
| Tracker connector | ✅ | every skill | — |
| Standard code | ❌ | analyse-ticket | I extract D365Std.zip to C:\ — you download it |
| ... | ❌ sign-in needed | ... | <one line: who does what> |

Custom code (optional — set up the projects you work on):
| Project | Repo | Status |
|---|---|---|
| MTM | TFVC | ✅ C:\Project\MTM\Trunk\Main |
| Luvata | Git | ⏸ not set up |
| ... | ... | ... |
```

Show the project table only when standard code is ✅. Put the ticket project, when there is one,
in the first table as a required row instead.

Statuses: ✅ ready · ❌ missing · ❌ sign-in needed · ⏸ optional or not needed now · ➖ checked by
its own skill. The **Fix** column says who does the work, so choosing to fix a row is the user's
agreement to it.

Then ask **one** question: which missing item to fix first. Recommend the first required ❌.
Include "Leave the rest for later" as an option. When no required ❌ is left, ask instead which
projects' custom code to set up now (several allowed), with "None for now" as an option — the
user picks from the list, and the plugin is ready either way.

## Step 3 — Fix one item at a time

Fix the chosen item only. When the user has a part to do, give it in short steps and wait for
"done". Then run that item's check again, show its new status, and offer the next ❌.

| Item | You do | The user does |
|---|---|---|
| Connector missing or signed out | Name the connector and the page. | Claude app: **Customize > Connectors**, **Connect** or **Reconnect**, sign in. Claude Code CLI: claude.ai **Settings > Connectors**. Then a new session and `/my-dax-skills:setup-mydaxskills` again. |
| Claude in Chrome | Give the link. | Install https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn, **Add to Chrome**, open the Claude icon, sign in. |
| Standard code | Find the zip (default `%USERPROFILE%\Downloads\D365Std.zip`). Extract it with `tar -xf "<zip>" -C C:\` as a background task, then run the file-count check in [`reference/code-setup.md`](reference/code-setup.md) section 1. | Download `D365Std.zip` from the team's shared "D365 Standard Source" folder (link from the team lead) if it is not in Downloads, and say where it is. |
| Folder not added to Claude | **No added folders yet:** request access with `mcp__ccd_directory__request_directory` and the folder path. **The session already has added folders** (an environment): ask the user to add it there, so it stays for later sessions. **Claude Code CLI:** ask for `/add-dir`. | Approve the access request, or add the folder: **Edit environment > Folders > Add**, or type `/add-dir <folder>` in the CLI. |
| Git missing | Install it: `winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements`. Open a new shell (or refresh `PATH`) and run `git --version`. | — |
| Git project's custom code | Clone it: `git clone "<repo URL>" C:\Custom\<Project>`. Then add the folder (row above). | Sign in with the project's Azure DevOps account when the Git Credential Manager window opens. |
| TFVC project, Visual Studio installed | Tell the user what to do (right column), then check the folder. | In Visual Studio: **Source Control Explorer** > the project's `<server path>` > **Get Latest Version**. Say which local folder it maps to. |
| TFVC project, no Visual Studio | Explain the token step. When the token is saved, run the first download with `scripts\Get-TfvcLatest.ps1` in this skill's folder ([`reference/code-setup.md`](reference/code-setup.md), "TFVC without Visual Studio"), then add the folder. | Create a PAT (scope **Code > Read**) in the project's Azure DevOps, then run `Get-TfvcLatest.ps1 -Collection <URL> -SavePat` **in their own terminal** and paste the token there. Give them the full command with the script path. |

The token stays out of the conversation: the user pastes it only into the script's own prompt,
the script stores it encrypted for that Windows user, and the script never prints it. When a user
offers a token in chat, explain this and send them to the `-SavePat` command instead.

A connector change takes effect in a **new session**. A folder granted with `request_directory`
works at once.

## Step 4 — Finish

Show the final checklist. Then list which skills are ready to use now, and which wait on a ⏸ item.
Projects without custom code are not a gap: say in one line that `analyse-ticket` offers their
setup when a ticket for them comes in.
