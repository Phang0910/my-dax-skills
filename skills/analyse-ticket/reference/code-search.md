# Read the D365FO code on the symptom path

## Where the code is

**`C:\D365Std` exists** (the shared standard-source export) → read `C:\D365Std\CLAUDE.md` now,
unless it is already in your context. It maps each project to its standard version folder and
its custom code repo, and it has two readiness checks. Complete both checks before you read any
code, and keep to the folders they select.

**`C:\D365Std` does not exist, and a local D365 installation does** (a dev VM) → use the local
installation:

| Code | Location |
|---|---|
| Project customizations | The project's repo folder in this environment, for example `C:\Project\<Project>\Trunk\Main\Metadata\<Model>\<Model>\` |
| Standard application | `C:\Users\<user>\AppData\Local\Microsoft\Dynamics365\<version>\PackagesLocalDirectory\` |

**Neither exists, or a readiness check fails** (a missing version folder, or no custom code for
the project) → that piece is missing. Go to the code readiness checkpoint in `SKILL.md`.

**Get the latest custom code** before you read it, and record the version in the Checks section
of the output. Find the copy's type from the repo root of the custom code folder:

| The folder has | Type | Pending changes? | Update | Version |
|---|---|---|---|---|
| `.git\` | Git | `git -C <folder> status --porcelain` prints lines | `git -C <folder> pull --ff-only` | `git -C <folder> log -1 --format="%h %ad"` |
| `.tfvc-latest.json` | TFVC via REST script | none — the copy is read-only | `powershell -ExecutionPolicy Bypass -File "<script>" -LocalPath <folder>` | the same with `-Status` |
| neither | TFVC workspace | `"<tf.exe>" status <folder> /recursive` lists files | `"<tf.exe>" get <folder> /recursive` | `"<tf.exe>" history <folder> /recursive /stopafter:1 /noprompt` |

- `<script>` is `..\setup-mydaxskills\scripts\Get-TfvcLatest.ps1`, relative to this skill's folder.
- `<tf.exe>` is the full path from
  `& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -find "Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\tf.exe"`.
  `tf` alone is not on the PATH of a normal shell.
- No pending changes → update without asking. Pending changes (usually a developer workspace) →
  ask the user before you update.
- The update fails (expired token, sign-in prompt, no network) → continue on the current code, and
  write in the output: "Custom code not updated — using <commit or changeset> from <date>".
  Tell the user to run `/my-dax-skills:setup-mydaxskills` when the cause is the sign-in or token.

Both layouts are `<Package>\<Model>\Ax*\<Name>.xml` (for example `ApplicationSuite\Foundation\AxTable\PurchLine.xml`).
Inside a model, each element is one XML file: `AxClass\<Name>.xml`, `AxTable\<Name>.xml`,
`AxForm\<Name>.xml`, `AxEnum\<Name>.xml`, and the `...Extension` folders.

## Search method

- **Customizations first.** In the project model, find the extensions on the path:
  `[ExtensionOf(classStr(X))]`, `[ExtensionOf(tableStr(X))]`, form extensions, event handlers.
  For each one, write what it changes — or "no effect on the symptom".
- **Then the standard code** that those extensions wrap, and the standard methods the symptom
  passes through. Read the exact method, not the whole file.
- **Search exact files.** Give `Grep` and `Read` a full file path, or a folder plus a filename
  glob. A search over all of `PackagesLocalDirectory` times out.
- Use the `Grep` and `Read` tools for metadata. Shell commands on metadata folders can be blocked
  by a hook.
- If the `d365fo-dev` skill is available, use it for X++ lookups (references, overrides, labels).

## What to note

- Feature flags (for example `DAX_*CustomFeature::instance().isEnabled()`) that switch the custom
  logic on or off.
- Parameters the standard code reads (for example `PurchParameters::find().PriceDateType`). Ask the
  user for a screenshot of that setup page.
- Validation messages (`checkFailed`, `throw error`) — they tell you which fields and stages block
  a UAT reproduction.
- Enum values: read the `AxEnum` file. SQL stores the integer `Value`; a value with no `<Value>`
  element is 0, and the next values follow in order.
