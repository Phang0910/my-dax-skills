# Worked example — Tracker #19119

A fully assembled evidence pack, kept as a specimen of the shape and depth a good description
block has. **Read it for the shape, not the contents** — none of these values carry over to
another case.

The case: a System Administrator on a Unified Developer Experience sandbox cannot deploy, because
Dataverse reports a missing privilege that appears to be gated on an F&O per-user licence.

---

## Environment

| Item | Value |
|---|---|
| Environment | `nichias2-dev1` |
| Type | Sandbox — Unified Developer (Developer Tools enabled) |
| Environment ID | `e613b521-3ac6-ebde-b918-9f762354829c` |
| Organization ID | `c2cf94d3-48fe-ef11-b015-000d3a80bc82` |
| Tenant ID | `08603cb0-94df-4eef-ae13-716adbe3da96` |
| Dataverse URL | `https://nichias2-dev1.crm5.dynamics.com` |
| F&O URL | `https://nichias2-dev1.operations.dynamics.com/` |
| Application version | `10.0.2527.174` |
| Platform version | `7.0.7858.145` |
| Geo | APAC |

## Affected account

| Item | Value |
|---|---|
| UPN | `admin@nichiasgbl2.onmicrosoft.com` (displays as 和義 北村) |
| Dataverse SystemUserId | `244f9ff8-c972-ef11-a670-6045bd1ba93b` |
| Entra Object ID | `f38d082c-48e3-4fc4-8f16-fbcb70a4748f` |
| Security role | System Administrator |
| Access mode | `1 Administrative` |

## Error — verbatim, from the VS FinOps Cloud Runtime

```
Principal user (Id=244f9ff8-c972-ef11-a670-6045bd1ba93b, type=8, roleCount=2,
privilegeCount=572, accessMode='1 Administrative',
AADObjectId='f38d082c-48e3-4fc4-8f16-fbcb70a4748f', MetadataCachePrivilegesCount=17806,
businessUnitId=2e489ff8-c972-ef11-a670-6045bd1ba93b (System Administrator unlicensed user
with filtered privileges from associated roles. Consider assigning License for the privileges
to take affect. ...)), is missing prvCreatemsprov_fnopackage privilege
(Id=de88d507-c519-492f-a3cd-65d39d3bf852) on OTC=11011 for entity 'msprov_fnopackage'
(LocalizedName='Finance and Operations Package').
context.Caller=244f9ff8-c972-ef11-a670-6045bd1ba93b.
ErrorCode: 0x80040220
```

Fails at `External Package Upload` → `Staging`. Everything before it succeeds, including
Microsoft's own validation of `DAXCustomFeatureManagement_1_0_0_1_managed.zip` and
`DAXSolutionsFGS_1_0_0_1_managed.zip`.

## Corroborating evidence

This is the section that earns the case a real engineer instead of a first-line script. Each line
rules something out.

1. **Reproduces in Visual Studio's own dialog** — Extensions > Dynamics 365 > Synchronize changes
   with the online environment — with an identical caller and error, so it is not tool-specific.
2. **The Finance and Operations Package Manager app** returns a permissions error for the same
   account, so read on the same entity is blocked too, not just create.
3. **Access mode cannot be held.** A second System Administrator set Access Mode to `Read-Write`
   and saved successfully; **Refresh user** reset it to `Administrative`. Access mode is derived
   from licence entitlement, not settable.
4. A licensed account in the same environment — `# Khor Wea Kee`,
   `381d1f52-659e-f011-bbd2-00224859910a` — shows `Read-Write`.

## Microsoft documentation

Documented in the UDE FAQ under **"I get a missing licenses error when running unified developer
experience operations"**, where the stated resolution is *"contact Microsoft Support with
environment details to fix the issue"* — which is what makes this a support case rather than a
configuration fix.

```
https://learn.microsoft.com/en-us/power-platform/developer/unified-experience/finance-operations-faq#i-get-a-missing-licenses-error-when-running-unified-developer-experience-operations
```

## What to ask Microsoft

Numbered, answerable, and each one forecloses a different reply. Never a single open "please
advise".

1. Does `prvCreatemsprov_fnopackage` on `msprov_fnopackage` (OTC 11011) genuinely require an F&O
   per-user licence, or is this an entitlement/provisioning defect on this environment?
2. Can `accessMode` be held at `Read-Write` for a System Administrator without an F&O licence in a
   UDE, or is the licence-sync reset expected behaviour?
3. If a licence is mandatory, what is the minimum qualifying SKU for UDE module deployment?
4. Is there a supported way to deploy to a UDE without a per-user licence?

## Attachments — a note, not a step

Microsoft's FAQ states **correlation ID, client machine name and timestamp** are required; those
three belong in the description block itself, not in an attachment.

- Correlation ID — Visual Studio output pane
- `C:\Users\<user>\AppData\Local\Microsoft\Dynamics365\Logs\Microsoft.PowerPlatformVSExtension*.log`
- `VisualStudioD365Extension*.log`
- `operationlogs.zip` — Finance and Operations Package Manager app > Operation History
- Screenshots: the deploy error, the access mode reset after Refresh user, and the licensed vs
  unlicensed comparison

`operationlogs.zip` is the illustrative case of rule 9: that app errors for the affected account,
so the file cannot be collected at all. Say so in the ticket — the inability to open Operation
History is itself evidence — and file without it. Do not stall the request on an attachment.
