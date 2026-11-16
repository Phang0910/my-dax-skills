# Check data with SQL Execute

SQL Execute is a page inside D365FO:

```
https://<environment host>/?cmp=<COMPANY>&mi=DEVSQLQueryExecute
```

Find the UAT and production hosts in memory or the conversation, or ask the user. The choice of
environment and of who runs the SQL is in `SKILL.md` Step 4.

When UAT does not have the ticket's records, UAT is a copy older than that data. Tell the user
the refresh gap in one line when you ask about production.

## Write each query

- **Check every table, field and enum against the AOT** before you give the query
  (`AxTable\<Name>.xml`, `AxEnum\<Name>.xml`). A wrong column name fails silently: no result grid,
  only a message.

  **Without code:** look the table up in Microsoft Learn's table reference first. Then run
  `SELECT TOP 1 * FROM <TABLE> WHERE DATAAREAID = '<company>'` once per table, and take the column
  names from its result before you filter on them. Enum integers come from Microsoft Learn or from
  values seen in the data. Label each query "fields not verified against code".
- **One statement per query.** Two statements in one run fail with "Connection is busy with
  results for another command", and the session stays blocked. To recover, close SQL Execute and
  open it again.
- Filter on `DATAAREAID` (lower case, for example `'mtm'`) and on the ticket's document numbers.
- Results stop at about 100 rows with no warning. Filter tightly, or use `GROUP BY` and counts.
- Write enum values as integers, with the name in a comment: `RELATION IN (1,2,3) -- line, multiline, total discount`.
- Under each query, write what each possible result means for the hypotheses.

## Run it yourself

1. Open the SQL Execute URL. If a sign-in page shows, ask the user to sign in.
2. Before every run, read the mode field (`devsqlqueryexecute_1_Parameters_QueryExecuteMode_input`).
   Continue only when it shows **Select**.
3. Click **Run** by its element id (`devsqlqueryexecute_1_BtnRunSQL`). A warning bar can move the
   layout, so a click by coordinates can hit the mode list.
4. Read the result grid. If there is no grid, read the message bar — it holds the error.
5. Open only the SQL Execute page. Ask the user before you open any other page.

## Read the result

- Label every result with its environment and the date you ran it.
- Look for false positives before you count cases: soft-deleted rows (`ISDELETED = 1`), values
  moved to other lines (compare totals, not one field), test or demo records.
