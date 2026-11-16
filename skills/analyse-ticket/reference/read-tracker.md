# Read Tracker images and files

The Tracker connector returns attachment metadata (id, filename, size, author) but no content and
no URL. Read each image or file in a browser.

## Choose the browser

1. Check Claude in Chrome. Load its tools in one `ToolSearch` call, then call `tabs_context_mcp`:

   ```
   select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__get_page_text,mcp__claude-in-chrome__read_page
   ```

2. Connected → use Claude in Chrome.
3. Not connected, or the tools are not found → use the built-in browser (`mcp__Claude_Browser__*`).
   Do this without asking the user.

## Open each attachment

- Open `https://tracker.daxonet.com/attachments/<attachment id>`. The page shows the image inline.
- Use the attachment view page. The `/attachments/download/<id>/<filename>` URL starts a file
  download, which the browser blocks.
- If the page shows **Continue with Azure AD**, ask the user to sign in in that browser. Wait, then
  continue.
- Take a screenshot, then zoom on the image area. Read every value the image shows.
- For a PDF, Excel or Word file, open the attachment page and read the preview. If there is no
  preview, ask the user for the file.

Open every attachment, including the small ones. A small image is often an email signature; the
large ones carry the evidence. Skip only images you have read on an earlier page.

## Record for each image

- The document numbers, values and statuses it shows.
- The **date format** of that user (D/M/YYYY or M/D/YYYY). Find it from a date that is not
  ambiguous (for example 18/8/2026). 
- The **environment** (URL in the screenshot, or the user's statement).
- Any value that disagrees with another image or with the ticket text. A mismatch is often the
  first clue.
