# Read the D365FO code on the symptom path

## Where the code is

**`C:\D365Std` exists** (the shared standard-source export) → read `C:\D365Std\CLAUDE.md` now,
unless it is already in your context. It maps each customer to its standard version folder and
its custom code repo, and it has two readiness checks. Complete both checks before you read any
code, and keep to the folders they select.

**`C:\D365Std` does not exist** (a dev VM) → use the local installation:

| Code | Location |
|---|---|
| Customer customizations | The customer's repo folder in this environment, for example `C:\Project\<Customer>\Trunk\Main\Metadata\<Model>\<Model>\` |
| Standard application | `C:\Users\<user>\AppData\Local\Microsoft\Dynamics365\<version>\PackagesLocalDirectory\` |

Both layouts are `<Package>\<Model>\Ax*\<Name>.xml` (for example `ApplicationSuite\Foundation\AxTable\PurchLine.xml`).
Inside a model, each element is one XML file: `AxClass\<Name>.xml`, `AxTable\<Name>.xml`,
`AxForm\<Name>.xml`, `AxEnum\<Name>.xml`, and the `...Extension` folders.

## Search method

- **Customizations first.** In the customer model, find the extensions on the path:
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
