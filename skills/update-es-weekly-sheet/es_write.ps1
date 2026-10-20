# Write one week's cells + notes into the ES workbook THROUGH Excel co-authoring.
# Excel sends only the changed cells and merges colleagues' edits, so there is no
# whole-file upload to collide with. Refuses to write unless the workbook is
# open from SharePoint with AutoSave on.
#
#   powershell -File es_write.ps1 spec.json
#   spec: {"sheet":"Jun Phang","col":"AC","day":16,
#          "values":{"7":3,"13":null}, "notes":{"10":"Gan Jun Phang:\n19829 ...","13":null}}
#   null clears the cell / removes the note.
param([Parameter(Mandatory)][string]$Spec)
$ErrorActionPreference = 'Stop'
$s = Get-Content -Raw -Encoding UTF8 $Spec | ConvertFrom-Json
$name = 'ES Weekly Update_Customer Success Team.xlsx'
$url = 'https://daxonet0.sharepoint.com/sites/EnterpriseSolution/Shared Documents/General/08 Resources/' + $name

try { $xl = [Runtime.InteropServices.Marshal]::GetActiveObject('Excel.Application') }
catch { $xl = New-Object -ComObject Excel.Application }
$xl.Visible = $true
$wb = $null
foreach ($w in $xl.Workbooks) { if ($w.Name -eq $name) { $wb = $w } }
if (-not $wb) { $wb = $xl.Workbooks.Open($url) }
for ($i = 0; $i -lt 30 -and -not $wb.AutoSaveOn; $i++) { Start-Sleep 1 }   # AutoSave comes up a moment after open
if ($wb.ReadOnly -or -not $wb.AutoSaveOn) {
    throw "Not co-authoring (ReadOnly=$($wb.ReadOnly), AutoSave=$($wb.AutoSaveOn)) - nothing written"
}

$ws = $wb.Worksheets.Item($s.sheet)
$day = $ws.Range("$($s.col)3").Value2
if ("$day" -ne "$($s.day)") { throw "$($s.sheet)!$($s.col)3 is '$day', expected '$($s.day)' - nothing written" }

foreach ($p in $s.values.PSObject.Properties) {
    $r = $ws.Range("$($s.col)$($p.Name)")
    if ($null -eq $p.Value) { [void]$r.ClearContents() } else { $r.Value2 = [double]$p.Value }
}
foreach ($p in $s.notes.PSObject.Properties) {
    $r = $ws.Range("$($s.col)$($p.Name)")
    [void]$r.ClearComments()
    if ($null -eq $p.Value) { continue }
    $text = $p.Value -replace "`r", ''
    $c = $r.AddComment($text)                       # a legacy note, authored as Application.UserName
    $c.Shape.TextFrame.Characters().Font.Bold = $false   # Excel's default note font is bold; house style is plain
    # ponytail: no TextFrame.AutoSize - it throws 0x800A03EC on a co-authored workbook
}
$wb.Save()   # AutoSave would get there anyway; this just pushes it now

$rows = @($s.values.PSObject.Properties.Name) + @($s.notes.PSObject.Properties.Name) | Sort-Object { [int]$_ } -Unique
foreach ($row in $rows) {
    $r = $ws.Range("$($s.col)$row")
    $n = if ($r.Comment) { ($r.Comment.Text() -split "`n" | Where-Object { $_ }).Count - 1 } else { '-' }
    "{0}{1} = {2}  (note tickets: {3})" -f $s.col, $row, $r.Value2, $n
}
