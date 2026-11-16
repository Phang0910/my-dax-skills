# Code setup — standard and custom D365FO code

Do this once per PC. `analyse-ticket` reads two kinds of code:

- **Standard code** — Microsoft's D365FO source, one folder per version, in `C:\D365Std`.
- **Custom code** — each customer's own models, from that customer's Azure DevOps repo.

The repo URL, the repo type (Git or TFVC) and the standard version for each customer are in the
project map in `C:\D365Std\CLAUDE.md`. That file is not in this repo, because it holds customer
details.

Both kinds of code are read-only for the skill. Microsoft source is licensed: keep it inside
DAXONET and customer channels.

**Easiest:** run `/my-dax-skills:setup` (standard code) or `/my-dax-skills:setup <customer>`
(custom code) in Claude Code. Claude runs the extraction, the Git install and clone, and the TFVC
download itself, and asks you only for sign-ins, the token and folder approvals. This page is the
manual version of the same steps.

---

## 1. Standard code (`C:\D365Std`)

1. Download `D365Std.zip` from the team's shared "D365 Standard Source" folder. Ask your team lead
   for the link. It is about 1.3 GB.
2. Extract it to `C:\`. The zip holds a `D365Std` folder, so the result is `C:\D365Std\...`.

   Command Prompt:
   ```
   tar -xf "%USERPROFILE%\Downloads\D365Std.zip" -C C:\
   ```
   PowerShell:
   ```
   tar -xf "$env:USERPROFILE\Downloads\D365Std.zip" -C C:\
   ```
   It writes about 800,000 files (about 6 GB) and takes 10–30 minutes. When the prompt comes back
   with no error, it is finished. Keep the window open until then.
3. Check that every file arrived. In PowerShell:
   ```
   foreach ($v in Get-ChildItem C:\D365Std -Directory) { $exp = [int]((Select-String -Path "$($v.FullName)\VERSION.txt" -Pattern 'Files:\s*(\d+)').Matches[0].Groups[1].Value); $got = (Get-ChildItem $v.FullName -Recurse -File).Count - 1; "{0}: expected {1}, found {2} -> {3}" -f $v.Name, $exp, $got, $(if ($got -eq $exp) {'OK'} else {'MISMATCH'}) }
   ```
   Each version prints `OK`. For `MISMATCH`, run the `tar` command again — it fills in the
   missing files.

To check a downloaded zip against the team copy, compare the size in bytes. The SharePoint
QuickXorHash of the file is the stronger check.

---

## 2. Custom code (`C:\Custom\<Customer>`)

Download each repo once as a **working copy**. After that, an update pulls only the files that
changed. Use one folder per customer, for example `C:\Custom\MTM`.

**Git or TFVC?** Read the customer's row in the project map (`C:\D365Std\CLAUDE.md`, last column):

| The column starts with | Repo type | Example |
|---|---|---|
| `Git:` | Git — the text after it is the clone URL | `Git: https://dev.azure.com/<org>/<project>/_git/<repo>` |
| `TFVC:` | TFVC — the text after it is the project and branch | `TFVC: MTM Trunk/Main` |

For a customer that is not in the map, open their Azure DevOps portal at **Repos > Files** and open
the repository list at the top:

- **Git** — the repository has a **Clone** button, and its URL contains `/_git/`.
- **TFVC** — the repository shows a `$/<Project>` folder tree and has no Clone button.

Then ask the map owner to add the customer, so the next person does not have to check.

Sign in with the **customer's** Azure DevOps account. If you use a personal access token, give it
**Code (Read)** scope only, and let Git Credential Manager or `tf` store it.

### Git repos

1. Install Git for Windows from https://git-scm.com/download/win (default options). It includes
   Git Credential Manager, which keeps one sign-in per Azure DevOps organisation.
2. Clone once (repo URL from the project map):
   ```
   git clone "<repo URL>" C:\Custom\<Customer>
   ```
   A browser sign-in opens the first time.
3. Get the latest changes:
   ```
   git -C C:\Custom\<Customer> pull --ff-only
   ```
4. Check the version:
   ```
   git -C C:\Custom\<Customer> log -1 --format="%h %ad %s"
   ```

### TFVC repos

Two ways, depending on whether this PC has Visual Studio:

- **Visual Studio installed** (usually a developer VM) → in Visual Studio, open **Source Control
  Explorer**, select the customer's branch (for example `$/MTM/Trunk/Main`), and click **Get
  Latest Version**. Then add the mapped local folder to Claude (section 3). `analyse-ticket` gets
  the latest changes itself before each analysis.
- **No Visual Studio** → use the REST script, below.

To find the **collection URL** and **server path** for the script: in the customer's Azure DevOps
portal, the collection URL is `https://dev.azure.com/<organisation>`, and the server path is under
**Repos > Files** in the TFVC repository (shown as `$/<Project>/Trunk/Main`; the project map names
the branch).

### TFVC without Visual Studio

`scripts\Get-TfvcLatest.ps1` in the `setup` skill folder keeps the copy up to date through the
Azure DevOps REST API. The first run downloads the branch as one zip. Later runs download only the
files changed by newer changesets, and apply deletes and renames. Ask Claude for the script's full
path on your PC — it is in the plugin folder.

1. Create a **personal access token** in the customer's Azure DevOps: your profile picture >
   **Personal access tokens** > **New Token**. Scope: **Code > Read** only. Pick an expiry date
   and note it.
2. Save the token once per organisation. Run this **yourself**, in your own terminal — it asks
   for the token and stores it encrypted for your Windows user:
   ```
   powershell -ExecutionPolicy Bypass -File "<script path>" -Collection <collection URL> -SavePat
   ```
3. First download (collection URL and server path as in step 1 of the `tf.exe` route):
   ```
   powershell -ExecutionPolicy Bypass -File "<script path>" -Collection <collection URL> -ServerPath "<server path>" -LocalPath C:\Custom\<Customer>
   ```
4. Get the latest changes — the folder remembers the collection and the server path:
   ```
   powershell -ExecutionPolicy Bypass -File "<script path>" -LocalPath C:\Custom\<Customer>
   ```
5. Check the version (changes nothing):
   ```
   powershell -ExecutionPolicy Bypass -File "<script path>" -LocalPath C:\Custom\<Customer> -Status
   ```

The last changeset is kept in `C:\Custom\<Customer>\.tfvc-latest.json`. When the token expires,
the script says so; save a new one with step 2. Add `-Full` to step 4 to download the whole branch
again, for example after a local file was changed by mistake.

---

## 3. Add the folders to Claude

Add `C:\D365Std` and each custom code folder:

- **Claude app, with an environment** → **Edit environment > Folders > Add**, then start a new
  session. The folders stay for later sessions.
- **Claude app, no environment** → approve the folder request when `/my-dax-skills:setup` asks.
  Access works at once, for that session.
- **Claude Code CLI** → type `/add-dir C:\D365Std` (and each custom folder), or start Claude with
  `claude --add-dir C:\D365Std`.

`analyse-ticket` finds each customer's code by its signature models (project map). Run
`/my-dax-skills:setup` again to check that everything is found.

## Rules for these copies

- Read only. Edit and check in from your normal dev workspace, never from `C:\Custom`. Then every
  update applies cleanly.
- On a dev VM that already has the customer's TFVC workspace (for example
  `C:\Project\<Customer>\Trunk\Main`), use that workspace. Map each server path to one local
  folder only.
