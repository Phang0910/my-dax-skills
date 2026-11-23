<#
.SYNOPSIS
    Read-only SQL queries against a D365FO dev environment through a saved SQL JIT connection.

.DESCRIPTION
    -SaveConnection  The USER runs this in their own PowerShell. It asks for the JIT server,
                     database, user and password (hidden) and stores them encrypted for the
                     current Windows user (DPAPI) in %LOCALAPPDATA%\my-dax-skills\sqljit-<Env>.xml.
    -Status          Shows whether a connection is saved and still valid, and tests it.
                     Never shows the password.
    -Query "<sql>"   Runs ONE read-only statement and prints the rows.
    -Clear           Deletes the saved connection.

    Guards enforced here, not left to the caller:
    - One SELECT or WITH statement only. ';' and write or admin keywords are rejected.
    - ApplicationIntent=ReadOnly, and the query runs in a transaction that is always rolled back.
    - At most -MaxRows rows (default 200); the output says when more rows exist.
    - A saved connection expires after -ValidHours (default 8).
    - The password is never printed; error text is cleaned of it.

.EXAMPLE
    .\Invoke-DevSql.ps1 -SaveConnection -Env mtm-dev
    .\Invoke-DevSql.ps1 -Status -Env mtm-dev
    .\Invoke-DevSql.ps1 -Env mtm-dev -Query "SELECT TOP 10 PURCHID, PURCHSTATUS FROM PURCHTABLE WHERE DATAAREAID = 'mtm'"
    .\Invoke-DevSql.ps1 -Clear -Env mtm-dev
#>
[CmdletBinding(DefaultParameterSetName = 'Query')]
param(
    [Parameter(Mandatory)] [ValidatePattern('^[A-Za-z0-9_-]+$')] [string]$Env,
    [Parameter(ParameterSetName = 'Save', Mandatory)] [switch]$SaveConnection,
    [Parameter(ParameterSetName = 'Status', Mandatory)] [switch]$Status,
    [Parameter(ParameterSetName = 'Clear', Mandatory)] [switch]$Clear,
    [Parameter(ParameterSetName = 'Query', Mandatory)] [string]$Query,
    [Parameter(ParameterSetName = 'Query')] [int]$MaxRows = 200,
    [int]$ValidHours = 8
)

$ErrorActionPreference = 'Stop'
$Dir = Join-Path $env:LOCALAPPDATA 'my-dax-skills'
$File = Join-Path $Dir "sqljit-$Env.xml"

function Get-Saved {
    if (-not (Test-Path $File)) {
        throw "No saved SQL JIT connection for '$Env'. Run in your own PowerShell: .\Invoke-DevSql.ps1 -SaveConnection -Env $Env"
    }
    $c = Import-Clixml $File
    $age = (Get-Date) - [datetime]$c.Saved
    if ($age.TotalHours -gt $ValidHours) {
        throw "The saved connection for '$Env' is older than $ValidHours hours (JIT access has likely expired). Request JIT access again, then run -SaveConnection."
    }
    return $c
}

function Get-PlainPassword($secure) {
    $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
}

function New-Connection($c) {
    $b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $b['Data Source'] = $c.Server
    $b['Initial Catalog'] = $c.Database
    $b['User ID'] = $c.User
    $b['Password'] = Get-PlainPassword $c.Password
    $b['Encrypt'] = $true
    $b['ApplicationIntent'] = 'ReadOnly'
    $b['Connect Timeout'] = 30
    $b['Application Name'] = 'my-dax-skills Invoke-DevSql'
    return New-Object System.Data.SqlClient.SqlConnection $b.ConnectionString
}

function Get-CleanMessage($err, $c) {
    $m = "$($err.Exception.Message)"
    if ($c) {
        $p = Get-PlainPassword $c.Password
        if ($p) { $m = $m.Replace($p, '***') }
    }
    return $m
}

function Test-ReadOnlyQuery([string]$sql) {
    # Strip comments and string literals before checking keywords.
    $s = [regex]::Replace($sql, '--[^\r\n]*', ' ')
    $s = [regex]::Replace($s, '/\*.*?\*/', ' ', 'Singleline')
    $s = [regex]::Replace($s, "'([^']|'')*'", "''")
    if ($s -notmatch '^\s*(SELECT|WITH)\b') { throw 'Only one SELECT (or WITH ... SELECT) statement is allowed.' }
    if ($s.Contains(';')) { throw "Only one statement is allowed: remove ';'." }
    $bad = '\b(INSERT|UPDATE|DELETE|MERGE|EXEC|EXECUTE|DROP|ALTER|TRUNCATE|CREATE|GRANT|REVOKE|DENY|BACKUP|RESTORE|DBCC|SHUTDOWN|KILL|INTO|OPENROWSET|OPENQUERY|OPENDATASOURCE|WAITFOR|SET)\b|\bxp_|\bsp_'
    $m = [regex]::Match($s, $bad, 'IgnoreCase')
    if ($m.Success) { throw "Not allowed in a read-only query: '$($m.Value)'." }
}

switch ($PSCmdlet.ParameterSetName) {
    'Save' {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        Write-Host "SQL JIT connection for '$Env'. Copy each value from the JIT access page."
        $server = (Read-Host 'Server (for example spartan-srv-xxx.database.windows.net)').Trim()
        $db = (Read-Host 'Database').Trim()
        $user = (Read-Host 'User name').Trim()
        $pw = Read-Host 'Password (it stays hidden)' -AsSecureString
        if (-not $server -or -not $db -or -not $user -or $pw.Length -eq 0) { throw 'Every value is required. Run the command again.' }
        $c = [pscustomobject]@{ Server = $server; Database = $db; User = $user; Password = $pw; Saved = (Get-Date).ToString('o') }
        $conn = New-Connection $c
        try { $conn.Open(); $conn.Close() }
        catch { throw "Could not connect: $(Get-CleanMessage $_ $c) Check the values, that JIT access is active, and that your IP is allowed." }
        $c | Export-Clixml $File
        Write-Host "OK - connected to $db on $server. Saved encrypted for $env:USERNAME for $ValidHours hours. Go back to Claude and say done."
    }
    'Status' {
        $c = Get-Saved
        $left = [math]::Round($ValidHours - ((Get-Date) - [datetime]$c.Saved).TotalHours, 1)
        $conn = New-Connection $c
        try { $conn.Open(); $conn.Close(); $state = 'connection works' }
        catch { $state = "cannot connect: $(Get-CleanMessage $_ $c)" }
        Write-Host "Env: $Env | Server: $($c.Server) | Database: $($c.Database) | User: $($c.User) | Valid for $left more hour(s) | $state"
    }
    'Clear' {
        if (Test-Path $File) { Remove-Item $File -Force; Write-Host "Deleted the saved connection for '$Env'." }
        else { Write-Host "Nothing saved for '$Env'." }
    }
    'Query' {
        Test-ReadOnlyQuery $Query
        $c = Get-Saved
        $conn = New-Connection $c
        $tx = $null
        try {
            $conn.Open()
            $tx = $conn.BeginTransaction()
            $cmd = $conn.CreateCommand()
            $cmd.Transaction = $tx
            $cmd.CommandText = $Query
            $cmd.CommandTimeout = 120
            $r = $cmd.ExecuteReader()
            $rows = New-Object System.Collections.Generic.List[object]
            $more = $false
            while ($r.Read()) {
                if ($rows.Count -ge $MaxRows) { $more = $true; break }
                $o = [ordered]@{}
                for ($i = 0; $i -lt $r.FieldCount; $i++) {
                    $n = $r.GetName($i); if (-not $n) { $n = "col$i" }
                    $o[$n] = if ($r.IsDBNull($i)) { $null } else { $r.GetValue($i) }
                }
                $rows.Add([pscustomobject]$o)
            }
            $r.Close()
            if ($rows.Count -eq 0) { Write-Host 'No rows.' }
            else { $rows | Format-Table -AutoSize | Out-String -Width 4096 | Write-Host }
            if ($more) { Write-Host "Rows: first $MaxRows shown - MORE ROWS EXIST. Filter the query, or use GROUP BY / COUNT." }
            else { Write-Host "Rows: $($rows.Count)" }
        }
        catch { throw "Query failed: $(Get-CleanMessage $_ $c)" }
        finally {
            if ($tx) { try { $tx.Rollback() } catch { } }
            $conn.Close()
        }
    }
}
