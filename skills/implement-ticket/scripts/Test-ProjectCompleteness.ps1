<#
.SYNOPSIS
    Checks that a D365FO VS project (.rnrproj) is complete before check-in. Read-only.

.DESCRIPTION
    1. Every element in the project has its XML file in the model folder.
    2. Every label file (AxLabelFile\<Id>_<lang>) has its <Id>.<lang>.label.txt entry and file.
    3. No project folder is empty.
    4. Source control: every project file is a pending add or already on the server (TFVC),
       or is not untracked (Git). Pending adds of build output (bin\, obj\, *.dll) are reported.

    Prints one line per problem and "OK" when there is none. Exit code 0 = OK, 1 = problems.

.EXAMPLE
    .\Test-ProjectCompleteness.ps1 -Project C:\Project\MTM\Trunk\Main\Projects\X\X\X.rnrproj -ModelPath C:\Project\MTM\Trunk\Main\Metadata\DAXSolutionsMTM\DAXSolutionsMTM
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Project,
    [Parameter(Mandatory)] [string]$ModelPath
)

$ErrorActionPreference = 'Stop'
$problems = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $Project)) { throw "Project file not found: $Project" }
if (-not (Test-Path -LiteralPath $ModelPath)) { throw "Model folder not found: $ModelPath" }

[xml]$proj = Get-Content -LiteralPath $Project -Raw
$ns = New-Object Xml.XmlNamespaceManager $proj.NameTable
$ns.AddNamespace('m', 'http://schemas.microsoft.com/developer/msbuild/2003')

$contents = @($proj.SelectNodes('//m:Content', $ns) | ForEach-Object { $_.GetAttribute('Include') })
$links = @($proj.SelectNodes('//m:Content/m:Link', $ns) | ForEach-Object { $_.InnerText })
$folders = @($proj.SelectNodes('//m:Folder', $ns) | ForEach-Object { $_.GetAttribute('Include') })

# Files that belong to the project, for the source-control check.
$projectFiles = New-Object System.Collections.Generic.List[string]

# 1 + 2: elements and label files
foreach ($inc in $contents) {
    if ($inc -match '\.label\.txt$') { continue }
    if ($inc -notmatch '^(Ax[A-Za-z]+)\\(.+)$') { continue }
    $kind = $Matches[1]; $name = $Matches[2]
    $file = Join-Path $ModelPath "$kind\$name.xml"
    if (Test-Path -LiteralPath $file) { $projectFiles.Add($file) }
    else { $problems.Add("Missing file for project element $inc ($file)") }

    if ($kind -eq 'AxLabelFile' -and $name -match '^(.+)_([A-Za-z]{2}(-[A-Za-z]{2,4})?)$') {
        $id = $Matches[1]; $lang = $Matches[2]
        $txtName = "$id.$lang.label.txt"
        if (-not ($contents | Where-Object { $_ -like "*$txtName" })) {
            $problems.Add("Label file $name has no '$txtName' entry in the project. Add the label file from Application Explorer (right-click > Add to project).")
        }
        $txt = Join-Path $ModelPath "AxLabelFile\LabelResources\$lang\$txtName"
        if (Test-Path -LiteralPath $txt) { $projectFiles.Add($txt) }
        else { $problems.Add("Label text file missing: $txt") }
    }
}

# 3: empty folders
foreach ($f in $folders) {
    if (-not ($links | Where-Object { $_.StartsWith($f, [StringComparison]::OrdinalIgnoreCase) })) {
        $problems.Add("Empty project folder '$f'. Remove it in Visual Studio (right-click > Remove).")
    }
}

# 4: source control
function Get-RepoRoot([string]$path) {
    $d = Get-Item -LiteralPath $path
    while ($d) {
        if (Test-Path -LiteralPath (Join-Path $d.FullName '.git')) { return $d.FullName }
        $d = $d.Parent
    }
    return $null
}

$gitRoot = Get-RepoRoot $ModelPath
if ($gitRoot) {
    $untracked = @(git -C $gitRoot status --porcelain --untracked-files=all -- $ModelPath (Split-Path $Project) 2>$null |
        Where-Object { $_ -like '?? *' } | ForEach-Object { (Join-Path $gitRoot ($_.Substring(3) -replace '/', '\')) })
    foreach ($pf in $projectFiles) {
        if ($untracked -contains $pf) { $problems.Add("Not added to Git: $pf") }
    }
    if ($untracked -contains $Project) { $problems.Add("Not added to Git: $Project") }
} else {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $tf = $null
    if (Test-Path $vswhere) {
        $tf = & $vswhere -latest -find 'Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\tf.exe' | Select-Object -First 1
    }
    if (-not $tf) {
        Write-Host "Source control not checked: no Git repo and no tf.exe found."
    } else {
        $ErrorActionPreference = 'Continue'
        $pending = @{}
        $tfError = $null
        foreach ($root in @($ModelPath, (Split-Path $Project))) {
            $out = & $tf status $root /recursive /format:detailed /noprompt 2>&1 | ForEach-Object { "$_" }
            if ($LASTEXITCODE -ne 0 -and ($out -match 'TF\d+')) { $tfError = ($out | Where-Object { $_ -match 'TF\d+' } | Select-Object -First 1); break }
            $local = $null
            foreach ($line in $out) {
                if ($line -match '^\s*Local item\s*:\s*\[[^\]]*\]\s*(.+)$') { $local = $Matches[1].Trim() }
                elseif ($line -match '^\s*Change\s*:\s*(.+)$' -and $local) { $pending[$local] = $Matches[1].Trim(); $local = $null }
            }
        }
        if ($tfError) {
            Write-Host "Source control not checked - tf.exe could not reach the server: $tfError"
            Write-Host "Check pending adds in Visual Studio (Pending Changes) instead."
            $projectFiles2 = @()
        } else { $projectFiles2 = @($projectFiles) + $Project }
        foreach ($pf in $projectFiles2) {
            if ($pending.ContainsKey($pf)) { continue }
            $null = & $tf properties $pf /noprompt 2>&1
            if ($LASTEXITCODE -ne 0) { $problems.Add("New file is not a pending add in TFVC: $pf (Visual Studio: right-click > Add Items to Folder, or include it in the project again)") }
        }
        foreach ($k in $pending.Keys) {
            if ($pending[$k] -match 'add' -and $k -match '\\(bin|obj)\\|\.(dll|netmodule|pdb)$') {
                $problems.Add("Build output is a pending add: $k (undo this add)")
            }
        }
    }
}

if ($problems.Count -eq 0) {
    Write-Host "OK - $($projectFiles.Count) file(s) checked, nothing missing."
    exit 0
}
$problems | ForEach-Object { Write-Host "- $_" }
exit 1
