# DAXONET naming and code conventions

These rules apply to **new** work only. Existing names never change, even when they follow an
older pattern (for example label files with a ticket number, or `PAX_`, `VTM_`, `DOT_` objects).

`<Prefix>` comes from the project map's **Prefix** column (`DAX_` or `AXG_`). `<Model>` is the
project's DAXONET model (for example `DAXSolutionsMTM`). `<Ticket>` is the Tracker number.
`<Name>` is PascalCase English that says what the change does.

## Names

| Item | Rule | Example |
|---|---|---|
| VS project | `<Prefix><Initials>_<Ticket>_<Name>` — `<Prefix>` already ends in `_` | `DAX_JP_19168_AddPRBackdatedValidation` |
| Feature class (always one per ticket) | `<Prefix><Ticket>_<Name>_CustomFeature` — no initials | `DAX_19168_AddPRBackdatedValidation_CustomFeature` |
| Label file | `<Prefix><Name>` — no ticket number, en-US | `DAX_PRBackdatedValidation` |
| Label id | descriptive PascalCase | `@DAX_PRBackdatedValidation:PRBackdatedAccountingDate` |
| New element (table, class, form, enum, EDT, menu item …) | `<Prefix><Name>` — no ticket number; add the module's area code where it has one | `DAX_GRNAttachmentCleanup`, `DAX_EP_BudgetTrans` |
| Field on a standard table | `<Prefix><Name>`, same name as its EDT or enum | `DAX_EP_PurchReqStage` |
| Table, form, EDT, enum, menu, security extension | `<Base>.<Model>` | `PurchReqTable.DAXSolutionsMTM` |
| Class extension (CoC) | `<Class>_<Model>_Extension` | `PurchLine_DAXSolutionsMTM_Extension` |

- No `&`, spaces or other XML-special characters. Use `And`.
- `<Name>` is the same in the VS project and the feature class.
- A follow-up fix to an earlier ticket's feature gets **its own** new feature class.

## Feature class

Create it with `d365fo-dev project item create custom-feature` (`--feature-number <Ticket>`,
`--display-name`, `--module`). The result must look like this:

```xpp
internal final class DAX_19766_AddPLGroupBudgetTransaction_CustomFeature implements DAXCustomIFeature
{
    private static DAX_19766_AddPLGroupBudgetTransaction_CustomFeature instance;

    private void new() { }
    private static void TypeNew() { instance = new DAX_19766_AddPLGroupBudgetTransaction_CustomFeature(); }
    public static DAX_19766_AddPLGroupBudgetTransaction_CustomFeature instance() { return DAX_19766_AddPLGroupBudgetTransaction_CustomFeature::instance; }

    [Hookable(false)] public str featureNumber()  { return '19766'; }
    [Hookable(false)] public str displayName()    { return 'Add PL Group column in Budget transactions'; }
    [Hookable(false)] public int module()         { return FeatureModuleV0::Budgeting; }
    [Hookable(false)] public boolean isEnabled()  { return DAXCustomFeatureStateProvider::isFeatureEnabled(DAX_19766_AddPLGroupBudgetTransaction_CustomFeature::instance()); }
}
```

- `featureNumber()` is the ticket number as a string.
- `displayName()` is English, functional words, no label.

## Code

- **Chain of Command:** call `next` first. Then check the feature, and run the new logic only when
  it is on:

  ```xpp
  public void init()
  {
      next init();

      if (DAX_19766_AddPLGroupBudgetTransaction_CustomFeature::instance().isEnabled())
      {
          // new behaviour
      }
  }
  ```

  When the fix must replace standard behaviour before `next`, say so in the plan (Step 3) and
  explain why.
- **A fix to an earlier feature's code** checks both features: the parent feature and this one.
- **Comments:** each new method or changed block gets

  ```xpp
  /// <summary>
  /// Tracker #19168 – block backdated PRs when the accounting date is in a closed period.
  /// </summary>
  ```

  No `//DAX_JP_<ticket> - begin / - end` markers.
- **Text the user sees** is a label in the ticket's label file, never a literal string.
