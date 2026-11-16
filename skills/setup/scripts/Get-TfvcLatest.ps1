<#
.SYNOPSIS
    Keeps a read-only local copy of a TFVC branch up to date through the Azure DevOps REST API.
    No Visual Studio or tf.exe needed.

.DESCRIPTION
    First run: downloads the branch as one zip at the latest changeset.
    Later runs: downloads only the files changed by newer changesets, and applies deletes and
    renames. The last applied changeset is kept in <LocalPath>\.tfvc-latest.json.

    Authentication is a personal access token (PAT) with Code (Read) scope, saved once per
    Azure DevOps organisation with -SavePat. It is stored encrypted for the current Windows user
    (DPAPI) under %LOCALAPPDATA%\my-dax-skills\. The script never prints it.

.EXAMPLE
    # Once per organisation — run it yourself in a terminal; it asks for the PAT:
    .\Get-TfvcLatest.ps1 -Collection https://dev.azure.com/contoso -SavePat

    # First download, and every later get latest:
    .\Get-TfvcLatest.ps1 -Collection https://dev.azure.com/contoso -ServerPath '$/MTM/Trunk/Main' -LocalPath C:\Custom\MTM

    # Show the local and the server changeset, change nothing:
    .\Get-TfvcLatest.ps1 -LocalPath C:\Custom\MTM -Status
#>
[CmdletBinding()]
param(
    [string]$Collection,
    [string]$ServerPath,
    [string]$LocalPath,
    [switch]$SavePat,
    [switch]$Status,
    [switch]$Full,
    [int]$FullThreshold = 2000
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$ApiVersion = '7.1'
$StateName = '.tfvc-latest.json'
$PatDir = Join-Path $env:LOCALAPPDATA 'my-dax-skills'

function Get-OrgName([string]$url) {
    $u = [Uri]$url.TrimEnd('/')
    if ($u.Host -like '*.visualstudio.com') { return $u.Host.Split('.')[0] }
    return $u.Segments[-1].Trim('/')
}

function Get-PatFile([string]$url) { Join-Path $PatDir ("azdo-pat-{0}.xml" -f (Get-OrgName $url)) }

function Get-AuthHeader([string]$url) {
    $file = Get-PatFile $url
    if (-not (Test-Path $file)) {
        throw "No saved PAT for organisation '$(Get-OrgName $url)'. Run once in your own terminal: .\Get-TfvcLatest.ps1 -Collection $url -SavePat"
    }
    $secure = Import-Clixml $file
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $pat = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
    return @{ Authorization = "Basic $b64" }
}

function Invoke-Api([string]$relative, [hashtable]$headers) {
    $uri = "{0}/_apis/{1}" -f $Collection.TrimEnd('/'), $relative
    $sep = '?'; if ($uri.Contains('?')) { $sep = '&' }
    $uri = "$uri$($sep)api-version=$ApiVersion"
    try { return Invoke-RestMethod -Uri $uri -Headers $headers -Method Get }
    catch {
        $code = $null
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        if ($code -eq 401 -or $code -eq 203) { throw "Azure DevOps rejected the PAT (HTTP $code). It may be expired. Save a new one with -SavePat." }
        throw
    }
}

function Get-LatestChangeset([hashtable]$headers) {
    $p = [Uri]::EscapeDataString($ServerPath)
    $r = Invoke-Api "tfvc/changesets?searchCriteria.itemPath=$p&`$top=1" $headers
    if (-not $r.value -or $r.value.Count -eq 0) { throw "No changesets found under $ServerPath. Check the server path." }
    return [int]$r.value[0].changesetId
}

function Get-ServerPrefix { return $ServerPath.TrimEnd('/') + '/' }

function ConvertTo-LocalFile([string]$serverItem) {
    $prefix = Get-ServerPrefix
    if (-not $serverItem.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $null }
    $rel = $serverItem.Substring($prefix.Length) -replace '/', '\'
    return Join-Path $LocalPath $rel
}

function Save-State([int]$changeset) {
    $state = [ordered]@{ collection = $Collection; serverPath = $ServerPath; changeset = $changeset; updated = (Get-Date).ToString('s') }
    $state | ConvertTo-Json | Set-Content (Join-Path $LocalPath $StateName) -Encoding UTF8
}

function Invoke-FullDownload([int]$changeset, [hashtable]$headers) {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("tfvc-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $zip = Join-Path $tmp 'branch.zip'
        $p = [Uri]::EscapeDataString($ServerPath)
        $uri = "{0}/_apis/tfvc/items?path={1}&versionDescriptor.versionType=changeset&versionDescriptor.version={2}&recursionLevel=full&`$format=zip&api-version={3}" -f $Collection.TrimEnd('/'), $p, $changeset, $ApiVersion
        Write-Host "Downloading $ServerPath at C$changeset as a zip..."
        Invoke-WebRequest -Uri $uri -Headers $headers -OutFile $zip -UseBasicParsing
        $ex = Join-Path $tmp 'x'
        Expand-Archive -Path $zip -DestinationPath $ex -Force

        # The zip may hold the branch under its own folder names; descend while that is all it holds.
        $segments = $ServerPath.TrimStart('$', '/').Split('/')
        $root = $ex
        while ($true) {
            $dirs = @(Get-ChildItem $root -Directory -Force)
            $files = @(Get-ChildItem $root -File -Force)
            if ($files.Count -eq 0 -and $dirs.Count -eq 1 -and ($segments -contains $dirs[0].Name)) { $root = $dirs[0].FullName } else { break }
        }

        if (Test-Path $LocalPath) {
            Get-ChildItem $LocalPath -Force | Where-Object { $_.Name -ne $StateName } | Remove-Item -Recurse -Force
        } else {
            New-Item -ItemType Directory -Path $LocalPath | Out-Null
        }
        Get-ChildItem $root -Force | Move-Item -Destination $LocalPath
    }
    finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    Save-State $changeset
    $count = @(Get-ChildItem $LocalPath -Recurse -File -Force | Where-Object { $_.Name -ne $StateName }).Count
    Write-Host "Done. $LocalPath is at C$changeset ($count files)."
}

function Get-ChangesetChanges([int]$id, [hashtable]$headers) {
    $all = @(); $skip = 0; $top = 1000
    do {
        $r = Invoke-Api "tfvc/changesets/$id/changes?`$top=$top&`$skip=$skip" $headers
        $page = @($r.value)
        $all += $page
        $skip += $top
    } while ($page.Count -eq $top)
    return $all
}

function Invoke-Incremental([int]$from, [int]$to, [hashtable]$headers) {
    $p = [Uri]::EscapeDataString($ServerPath)
    $ids = @()
    $skip = 0
    do {
        $r = Invoke-Api "tfvc/changesets?searchCriteria.itemPath=$p&searchCriteria.fromId=$($from + 1)&searchCriteria.toId=$to&`$top=1000&`$skip=$skip&`$orderby=id asc" $headers
        $page = @($r.value)
        $ids += $page | ForEach-Object { [int]$_.changesetId }
        $skip += 1000
    } while ($page.Count -eq 1000)
    $ids = $ids | Sort-Object -Unique

    # Final state per server item across all new changesets: 'present' or 'deleted'.
    $state = @{}
    foreach ($id in $ids) {
        foreach ($c in (Get-ChangesetChanges $id $headers)) {
            $item = $c.item.path
            $type = [string]$c.changeType
            if ($c.sourceServerItem -and $type -match 'rename') { $state[$c.sourceServerItem] = @{ deleted = $true; folder = [bool]$c.item.isFolder } }
            if ($type -match 'delete' -and $type -notmatch 'undelete') { $state[$item] = @{ deleted = $true; folder = [bool]$c.item.isFolder } }
            else { $state[$item] = @{ deleted = $false; folder = [bool]$c.item.isFolder } }
        }
        if ($state.Count -gt $FullThreshold) { break }
    }

    if ($state.Count -gt $FullThreshold) {
        Write-Host "More than $FullThreshold changed items; downloading the full branch instead."
        Invoke-FullDownload $to $headers
        return
    }

    $added = 0; $removed = 0
    foreach ($key in ($state.Keys | Sort-Object)) {
        $local = ConvertTo-LocalFile $key
        if (-not $local) { continue }
        $s = $state[$key]
        if ($s.deleted) {
            if (Test-Path -LiteralPath $local) { Remove-Item -LiteralPath $local -Recurse -Force; $removed++ }
        } elseif ($s.folder) {
            if (-not (Test-Path -LiteralPath $local)) { New-Item -ItemType Directory -Path $local -Force | Out-Null }
        } else {
            $dir = Split-Path $local -Parent
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $ip = [Uri]::EscapeDataString($key)
            $uri = "{0}/_apis/tfvc/items?path={1}&versionDescriptor.versionType=changeset&versionDescriptor.version={2}&download=true&api-version={3}" -f $Collection.TrimEnd('/'), $ip, $to, $ApiVersion
            Invoke-WebRequest -Uri $uri -Headers $headers -OutFile $local -UseBasicParsing
            $added++
        }
    }
    Save-State $to
    Write-Host ("Done. C{0} -> C{1}: {2} changeset(s), {3} file(s) downloaded, {4} removed." -f $from, $to, $ids.Count, $added, $removed)
}

# ---- main ----

if ($SavePat) {
    if (-not $Collection) { throw 'Give -Collection (for example https://dev.azure.com/contoso).' }
    New-Item -ItemType Directory -Path $PatDir -Force | Out-Null
    $secure = Read-Host "PAT for $(Get-OrgName $Collection) (Code: Read scope)" -AsSecureString
    $secure | Export-Clixml (Get-PatFile $Collection)
    Write-Host "Saved, encrypted for $env:USERNAME, at $(Get-PatFile $Collection)."
    return
}

if (-not $LocalPath) { throw 'Give -LocalPath.' }
$stateFile = Join-Path $LocalPath $StateName
$saved = $null
if (Test-Path $stateFile) { $saved = Get-Content $stateFile -Raw | ConvertFrom-Json }
if (-not $Collection -and $saved) { $Collection = $saved.collection }
if (-not $ServerPath -and $saved) { $ServerPath = $saved.serverPath }
if (-not $Collection -or -not $ServerPath) { throw 'Give -Collection and -ServerPath on the first run.' }

$headers = Get-AuthHeader $Collection
$latest = Get-LatestChangeset $headers

if ($Status) {
    $localCs = 'none'
    if ($saved) { $localCs = "C$($saved.changeset) (updated $($saved.updated))" }
    Write-Host "Local:  $localCs"
    Write-Host "Server: C$latest"
    return
}

if ($Full -or -not $saved) { Invoke-FullDownload $latest $headers }
elseif ([int]$saved.changeset -ge $latest) { Write-Host "Already at the latest changeset, C$latest." }
else { Invoke-Incremental ([int]$saved.changeset) $latest $headers }
