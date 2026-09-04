---
name: KB-this
description: Write a knowledge base article about a resolved case and publish it to DAXONET Notes under the customer's KB page, in the house format. Use when the user asks to KB a case, write it up as a knowledge base article, or document a fix in Notes.
argument-hint: "[ticket no or case description]"
---

# KB-this

Turn a resolved case into a knowledge base article and publish it to DAXONET Notes as a child of
the customer's KB parent page.

**Never publish without explicit confirmation.** The confirmation must show the title and the
parent page it will be nested under.

A KB article is written for the next person who hits the same symptom — not as a record of the
investigation. Anything that does not help them recognise or fix the problem is cut.

---

## Step 1 — Gather the case facts

Prefer, in this order:

1. **The current conversation.** If the case was just worked here, the facts are already present.
2. **The Tracker ticket** — `mcp__claude_ai_Tracker__get_issue`. Read the journals and attachment
   list, not just the subject. Screenshots attached to a ticket frequently hold the whole answer
   (error text, environment, form names) while the description sits empty.
3. **Ask the user** for anything still missing. Do not invent.

Establish before drafting:

- The **symptom** as the user experienced it, and where — the form, the button, the navigation path
- The **exact error text**, verbatim
- The **environment** — legal entity, and which of DEV / UAT / PROD
- The **root cause**, and *why* the system behaved that way
- What was **actually done** to fix it, in re-applicable steps
- How it was **verified**
- What is still **outstanding**

**Report only what happened.** If the fix was applied to a deployed package but not to source, the
KB says exactly that. Never write "resolved" over an outstanding item.

## Step 2 — Read the existing KBs before drafting

**Do not infer the format from one article.** Read every KB under the customer's parent page first.
The format has changed over time and the oldest article is often a superseded shape.

Find the parent page and its children:

```
mcp__claude_ai_DAXONET_Notes__list_documents(query: "<customer name>")
```

Known values for Panasonic — verify rather than assume they still hold:

| | |
|---|---|
| Parent page | `PANASONIC` — https://notes.daxonet.com/doc/panasonic-gwgLdDvzML |
| `parentDocumentId` | `f872bc4e-00f6-4978-8c2a-08acf5901685` |
| `collectionId` | `dd3e7671-599d-4ee1-a97c-ea3214d92d09` |

**Search results are far too large for context and will be dumped to a file instead.** That is
expected — do not retry with a smaller limit. Parse the file offline and print only what you need:

```bash
# the tool result is [{type, text}] whose text is concatenated JSON objects
python - <<'EOF'
import json, glob
base = "<the tool-results directory the error names>/"
PARENT = "f872bc4e-00f6-4978-8c2a-08acf5901685"
dec = json.JSONDecoder(); docs = {}
for fn in glob.glob(base + "mcp-claude_ai_DAXONET_Notes-list_documents-*.txt"):
    txt = ''.join(x['text'] for x in json.load(open(fn, encoding='utf-8')))
    i = 0
    while i < len(txt):
        while i < len(txt) and txt[i] != '{': i += 1
        if i >= len(txt): break
        try:
            o, j = dec.raw_decode(txt, i); i = j
            if isinstance(o, dict) and 'title' in o and 'data' in o: docs[o['id']] = o
        except Exception: i += 1
# then filter on parentDocumentId == PARENT and walk o['data'] for headings
EOF
```

`list_documents` with a `collectionId` returns an Authorization error — use full-text `query`
instead and filter on `parentDocumentId` yourself.

Run two or three searches with different phrasings (the customer name, distinctive section headings
like `Symptom Root Cause Resolution`, `Redmine Case Date Resolved`) so the corpus is complete
before you conclude anything about the format.

## Step 3 — Draft the article

House format, as used by the current articles:

```
# KB: <descriptive title with the key identifiers>

| Field | Detail |
|---|---|
| **Module** | <Module › Submodule / Interface> |
| **Environment** | <Entity> | <Company name> — <DEV/UAT/PROD> |
| **D365 F&O Version** | 10.0.x |
| **Date Resolved** | YYYY-MM-DD |
| **Resolved By** | <internal person> |
| **Redmine Case** | #NNNNN |

---

## Symptom
## Root Cause
## Resolution
## Prevention / SOP Recommendation
## Related References
```

### The metadata table is fitted to the subject, not fixed

Only **Date Resolved** and **Resolved By** appear in every article. Everything else is chosen to
suit the case — an EPACS master-data article uses `System`, `Site / Term`, `Part Number`, `Change`
and carries no `Module` or `D365 F&O Version` at all. Add a row when it identifies the thing that
broke (`Function App`, `Interface`, `Batch Job`) and drop rows that would be noise.

Include **Redmine Case** when a ticket exists. When there is none, say so explicitly at the end of
Related References — "No Redmine ticket raised for this change. This KB serves as the standalone
record."

**Omit `Reported by`.** Name people inline in Symptom only where it genuinely matters to the story.
Never put internal staff in a reported-by position.

### The sections

- **`## Symptom`** — or `## Symptom / Request` when it is a change request rather than a fault.
  Lead paragraph, then a numbered progression when the case unfolded in stages. Reproduce the exact
  error string. Quote the user verbatim where it is the clearest statement of what they wanted.
- **`## Root Cause`** — **this is where the teaching goes.** Not just what was misconfigured, but
  why the system behaved that way, and why it was hard to see. Used even when there was no fault
  ("a planned master-data maintenance request, not a system fault").
- **`## Resolution`** — re-applicable steps, navigation paths in bold with `›`. Use
  `### Step N: <Title> (Completed)` subheadings when the fix ran in phases. Items that are done but
  not yet closed out go in a final `### Step N: Outstanding items (Checklist)` as unchecked
  checkboxes. May close with an `Outcome:` line.
- **`## Prevention / SOP Recommendation`** — present in every current article. Split by
  responsibility (customer vs Daxonet) where both are involved. A deployment or handoff checklist
  belongs here as checkboxes.
- **`## Related References`** — forms, tables, interfaces, hostnames, links, and related Redmine
  cases. Form and table names in inline code.

### Voice

Past tense, third person, factual. Exact values, IDs and error strings reproduced verbatim — never
paraphrased. Navigation paths bolded, using `›` as the separator. Length tracks complexity; the
existing articles run 350–900 words. There is no target length, but nothing goes in that does not
help the next reader.

### Never include

- Client secrets, host keys, connection strings, tokens — even ones visible in a screenshot the
  user pasted. If a credential is part of the story, say "the credentials in `<file>`" and stop.
  Raise the exposure with the user separately; it does not belong in a KB.
- The full investigation trail. `nslookup` output, portal blades checked, dead ends ruled out —
  that belongs on the ticket. The KB gets the conclusion and the one or two checks that let someone
  else confirm it fast.
- Screenshots. None of the existing articles use them.

## Step 4 — Confirm before publishing

Show the user, together:

- the **title** and the **parent page** it will be nested under
- the full draft, exactly as it will be published
- anything you had to assume, called out plainly

Then use `AskUserQuestion` — options: publish it / edit first / cancel.

Treat any edit as a redraft, then confirm again. Save the draft to a local `.md` file first so it
survives if publishing fails.

## Step 5 — Publish

```
mcp__claude_ai_DAXONET_Notes__create_document(
  title:            "<title, 100 characters or fewer>",
  parentDocumentId: "<customer KB parent page id>",
  collectionId:     "<collection id>",
  publish:          true,
  text:             "<the confirmed markdown, including the H1>"
)
```

Include the `# KB: …` H1 in `text` as well as passing `title` — the existing articles carry both.

**Title is capped at 100 characters** and the call is rejected outright if longer. Trim a trailing
parenthetical rather than the descriptive part; the detail is in the metadata table anyway.

## Step 6 — Report back

Give the user the published URL in one line, then flag anything to tidy in the editor.

Two rendering quirks to check and mention:

- A phrase marked as **both** bold and inline code imports as literal `` `**text**` ``. Choose one
  or the other when drafting.
- Nested checkbox lists under a numbered item render, but verify the nesting survived.

If the call fails, say so plainly and hand the user the local draft file so nothing is lost.

---

## What this skill exists to prevent

- **Inferring the template from one article.** The Panasonic page holds four KBs in two different
  shapes; the earliest was superseded two hours after it was written. Read them all first.
- **Leaving a `Reported by` placeholder** for the user to chase. Omit the line.
- **Publishing a secret** that appeared in a Kudu or portal screenshot during the investigation.
- **Retrying an oversized search** with a smaller limit instead of parsing the saved file.
- **Writing the investigation instead of the fix.** If a line does not help the next person
  recognise or resolve the symptom, cut it.
