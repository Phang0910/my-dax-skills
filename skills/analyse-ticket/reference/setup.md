# analyse-ticket — one-time setup

Do this once per PC before you use `analyse-ticket`. The skill reads two kinds of code:

- **Standard code** — Microsoft's D365FO source, one folder per version, in `C:\D365Std`.
- **Custom code** — each customer's own models, from that customer's Azure DevOps repo.

The repo URL, the repo type (Git or TFVC) and the standard version for each customer are in the
project map in `C:\D365Std\CLAUDE.md`. That file is not in this repo, because it holds customer
details.

Both kinds of code are read-only for the skill. Microsoft source is licensed: keep it inside
DAXONET and customer channels.

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

TFVC needs `tf.exe`, which comes with Visual Studio 2022 (any edition you are licensed for).
Run the commands in **Developer PowerShell for VS 2022** (Start menu), where `tf` is ready to use.

1. In the customer's Azure DevOps portal, find:
   - the **collection URL** — `https://dev.azure.com/<organisation>`
   - the **server path** — **Repos > Files**, the TFVC repository, `Trunk/Main` (shown as
     `$/<Project>/Trunk/Main`; the project map names the branch)
2. Create a local workspace and get the code once:
   ```
   tf workspace /new <Customer>-ReadOnly /collection:<collection URL> /location:local /noprompt
   tf workfold /unmap $/ /workspace:<Customer>-ReadOnly
   tf workfold /map "<server path>" C:\Custom\<Customer> /workspace:<Customer>-ReadOnly
   tf get C:\Custom\<Customer> /recursive
   ```
   The first `tf` command opens a browser sign-in. The `unmap $/` line removes a default root
   mapping, so only the branch downloads. The first `get` takes a while.
3. Get the latest changes:
   ```
   tf get C:\Custom\<Customer> /recursive
   ```
4. Check the version:
   ```
   tf history C:\Custom\<Customer> /recursive /stopafter:1 /noprompt
   ```

Without Visual Studio there is no incremental update for TFVC. The fallback is to download the
branch as a zip from the Azure DevOps portal each time.

---

## 3. Add the folders to Claude

1. In the Claude app: **Edit environment > Folders > Add** — add `C:\D365Std` and `C:\Custom`.
2. Start a new session.

The skill finds each customer's code by its signature models (project map). It tells you if a
folder is missing and points you back to this page.

## Rules for these copies

- Read only. Edit and check in from your normal dev workspace, never from `C:\Custom`. Then every
  update applies cleanly.
- On a dev VM that already has the customer's TFVC workspace (for example
  `C:\Project\<Customer>\Trunk\Main`), use that workspace. Map each server path to one local
  folder only.
