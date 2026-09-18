[CmdletBinding()]
param(
    [string]$SourceTemplate = (Join-Path (Split-Path $PSScriptRoot -Parent) 'backups\2026-09-18-pre-v1.3-friendly-skills\Cowork Value V1 Testing.pbit'),
    [string]$OutputTemplate = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Cowork Value V1.3 Friendly Skills Testing.pbit')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$utf16 = [System.Text.UnicodeEncoding]::new($false, $false)

function Read-ZipText {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$EntryName,
        [System.Text.Encoding]$Encoding
    )

    $entry = $Archive.GetEntry($EntryName)
    if ($null -eq $entry) {
        throw "Missing PBIT entry: $EntryName"
    }

    $reader = [System.IO.StreamReader]::new($entry.Open(), $Encoding, $true)
    try {
        $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
    }
}

function Write-ZipText {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$EntryName,
        [string]$Text,
        [System.Text.Encoding]$Encoding
    )

    $existing = $Archive.GetEntry($EntryName)
    $lastWriteTime = $null
    if ($null -ne $existing) {
        $lastWriteTime = $existing.LastWriteTime
        $existing.Delete()
    }

    $entry = $Archive.CreateEntry($EntryName, [System.IO.Compression.CompressionLevel]::Optimal)
    if ($null -ne $lastWriteTime) {
        $entry.LastWriteTime = $lastWriteTime
    }
    $writer = [System.IO.StreamWriter]::new($entry.Open(), $Encoding)
    try {
        $writer.Write($Text)
    }
    finally {
        $writer.Dispose()
    }
}

function ConvertTo-MText {
    param([object]$Value)

    if ($null -eq $Value) {
        return ''
    }
    if ($Value -is [System.Array]) {
        return ($Value -join "`n")
    }
    return [string]$Value
}

function ConvertTo-MLines {
    param([string]$Text)
    return ,([string[]]($Text -split "\r?\n"))
}

function Set-UnappliedFormula {
    param(
        [object]$Query,
        [string]$Expression
    )

    $Query.text = ConvertTo-MLines $Expression
    if ($Query.PSObject.Properties.Name -contains 'lastLoadedAsTableFormulaText') {
        $loaded = $Query.lastLoadedAsTableFormulaText | ConvertFrom-Json -Depth 100
        $loaded.RootFormulaText = $Expression
        $Query.lastLoadedAsTableFormulaText = $loaded | ConvertTo-Json -Depth 100 -Compress
    }
}

function Add-AfterName {
    param(
        [object[]]$Items,
        [object]$NewItem,
        [string]$AfterName
    )

    $result = [System.Collections.Generic.List[object]]::new()
    $inserted = $false
    foreach ($item in $Items) {
        $result.Add($item)
        if (-not $inserted -and $item.name -eq $AfterName) {
            $result.Add($NewItem)
            $inserted = $true
        }
    }
    if (-not $inserted) {
        $result.Add($NewItem)
    }
    return $result.ToArray()
}

function Add-StringAfterValue {
    param(
        [string[]]$Items,
        [string]$NewItem,
        [string]$AfterValue
    )

    $result = [System.Collections.Generic.List[string]]::new()
    $inserted = $false
    foreach ($item in $Items) {
        $result.Add($item)
        if (-not $inserted -and $item -eq $AfterValue) {
            $result.Add($NewItem)
            $inserted = $true
        }
    }
    if (-not $inserted) {
        $result.Add($NewItem)
    }
    return $result.ToArray()
}

$friendlyNameExpression = @'
let
	fn = (raw as nullable text) as text =>
		let
			Technical = if raw = null then "" else Text.Trim(Text.From(raw)),
			IsMcp = Text.StartsWith(Technical, "mcp__"),
			Payload = if IsMcp then Text.AfterDelimiter(Technical, "mcp__") else Technical,
			Parts = Text.Split(Payload, "__"),
			ServerRaw = if IsMcp and List.Count(Parts) > 1 then Parts{0} else null,
			ToolRaw = if IsMcp and List.Count(Parts) > 1 then Text.Combine(List.Skip(Parts, 1), " ") else Payload,
			Normalized = Text.Replace(Text.Replace(ToolRaw, "_", " "), "-", " "),
			Characters = Text.ToList(Normalized),
			Positions = List.Positions(Characters),
			WithBoundaries = List.Transform(
				Positions,
				(i) =>
					let
						Current = Characters{i},
						Previous = if i = 0 then "" else Characters{i - 1},
						Next = if i >= List.Count(Characters) - 1 then "" else Characters{i + 1},
						CurrentUpper = List.Contains({"A".."Z"}, Current),
						PreviousLower = List.Contains({"a".."z"}, Previous),
						PreviousUpper = List.Contains({"A".."Z"}, Previous),
						NextLower = List.Contains({"a".."z"}, Next),
						IsBoundary = i > 0 and CurrentUpper and (PreviousLower or (PreviousUpper and NextLower))
					in
						(if IsBoundary then " " else "") & Current
			),
			Spaced = Text.Combine(WithBoundaries, ""),
			Words = List.Select(Text.SplitAny(Spaced, " "), each _ <> ""),
			Cleaned = if List.IsEmpty(Words) then "Unspecified Skill" else Text.Proper(Text.Combine(Words, " ")),
			ServerLabel =
				if ServerRaw = null or ServerRaw = "host" then null
				else if ServerRaw = "outlook" then "Outlook"
				else if ServerRaw = "outlook_calendar" then "Calendar"
				else if ServerRaw = "m365_teams" then "Teams"
				else if ServerRaw = "m365_search" then "Microsoft 365"
				else if ServerRaw = "sharepoint_onedrive" then "SharePoint and OneDrive"
				else if ServerRaw = "me_profile" then "People"
				else if ServerRaw = "pbi_fabricaihub" then "Power BI"
				else if ServerRaw = "helpdesk-mcp" then "Helpdesk"
				else if ServerRaw = "d365_sales" then "Dynamics 365 Sales"
				else if ServerRaw = "graph" then "Microsoft Graph"
				else Text.Proper(Text.Replace(Text.Replace(ServerRaw, "_", " "), "-", " ")),
			Friendly = if ServerLabel = null then Cleaned else Cleaned & " (" & ServerLabel & ")"
		in
			Friendly
in
	fn
'@

if (-not (Test-Path -LiteralPath $SourceTemplate -PathType Leaf)) {
    throw "Source template not found: $SourceTemplate"
}

$outputDirectory = Split-Path $OutputTemplate -Parent
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$sourceHashBefore = (Get-FileHash -LiteralPath $SourceTemplate -Algorithm SHA256).Hash
Copy-Item -LiteralPath $SourceTemplate -Destination $OutputTemplate -Force

$stream = [System.IO.File]::Open(
    $OutputTemplate,
    [System.IO.FileMode]::Open,
    [System.IO.FileAccess]::ReadWrite,
    [System.IO.FileShare]::None
)
try {
    $archive = [System.IO.Compression.ZipArchive]::new(
        $stream,
        [System.IO.Compression.ZipArchiveMode]::Update,
        $false
    )
    try {
        $model = (Read-ZipText $archive 'DataModelSchema' $utf16) | ConvertFrom-Json -Depth 100
        $unapplied = (Read-ZipText $archive 'UnappliedChanges' $utf16) | ConvertFrom-Json -Depth 100

        $friendlyModelExpression = [pscustomobject][ordered]@{
            name = 'fnFriendlyToolName'
            description = @(
                'Converts unmapped technical tool identifiers into readable display labels.',
                'Curated FriendlyName values continue to take precedence; this function does not change category or value attribution.'
            )
            kind = 'm'
            expression = ConvertTo-MLines $friendlyNameExpression
            lineageTag = '0a11cbc7-fde4-4840-8e61-687164d19701'
        }
        $keptModelExpressions = @($model.model.expressions | Where-Object { $_.name -ne 'fnFriendlyToolName' })
        $model.model.expressions = Add-AfterName $keptModelExpressions $friendlyModelExpression 'fnLoadCsv'

        $queryOrderAnnotation = $model.model.annotations | Where-Object { $_.name -eq 'PBI_QueryOrder' } | Select-Object -First 1
        if ($null -eq $queryOrderAnnotation) {
            throw 'PBI_QueryOrder annotation not found.'
        }
        $queryOrder = [string[]]@($queryOrderAnnotation.value | ConvertFrom-Json)
        $queryOrder = [string[]]@($queryOrder | Where-Object { $_ -ne 'fnFriendlyToolName' })
        $queryOrderAnnotation.value = (Add-StringAfterValue $queryOrder 'fnFriendlyToolName' 'fnLoadCsv') | ConvertTo-Json -Compress

        $dimSkill = $model.model.tables | Where-Object { $_.name -eq 'Dim_CoworkSkill' } | Select-Object -First 1
        if ($null -eq $dimSkill) {
            throw 'Model table not found: Dim_CoworkSkill'
        }
        $dimPartition = $dimSkill.partitions | Select-Object -First 1
        $dimSource = ConvertTo-MText $dimPartition.source.expression
        $oldFallback = 'else [PluginName], type text)'
        $newFallback = 'else fnFriendlyToolName([PluginName]), type text)'
        if (-not $dimSource.Contains($oldFallback) -and -not $dimSource.Contains($newFallback)) {
            throw 'Expected Dim_CoworkSkill display fallback was not found.'
        }
        $dimSource = $dimSource.Replace($oldFallback, $newFallback)
        $dimPartition.source.expression = ConvertTo-MLines $dimSource

        $friendlyUnappliedQuery = [pscustomobject][ordered]@{
            name = 'fnFriendlyToolName'
            lineageTag = '0a11cbc7-fde4-4840-8e61-687164d19701'
            description = 'Readable fallback for unmapped technical tool identifiers; does not alter category or value attribution.'
            text = ConvertTo-MLines $friendlyNameExpression
            loadAsTableDisabled = $true
            resultType = 'Unknown'
            isHidden = $false
        }
        $keptUnappliedQueries = @($unapplied.queries | Where-Object { $_.name -ne 'fnFriendlyToolName' })
        $unapplied.queries = Add-AfterName $keptUnappliedQueries $friendlyUnappliedQuery 'fnLoadCsv'

        $dimUnapplied = $unapplied.queries | Where-Object { $_.name -eq 'Dim_CoworkSkill' } | Select-Object -First 1
        if ($null -eq $dimUnapplied) {
            throw 'Unapplied query not found: Dim_CoworkSkill'
        }
        $dimUnappliedSource = ConvertTo-MText $dimUnapplied.text
        if (-not $dimUnappliedSource.Contains($oldFallback) -and -not $dimUnappliedSource.Contains($newFallback)) {
            throw 'Expected unapplied Dim_CoworkSkill display fallback was not found.'
        }
        $dimUnappliedSource = $dimUnappliedSource.Replace($oldFallback, $newFallback)
        Set-UnappliedFormula $dimUnapplied $dimUnappliedSource

        Write-ZipText $archive 'DataModelSchema' ($model | ConvertTo-Json -Depth 100) $utf16
        Write-ZipText $archive 'UnappliedChanges' ($unapplied | ConvertTo-Json -Depth 100 -Compress) $utf16
    }
    finally {
        $archive.Dispose()
    }
}
finally {
    $stream.Dispose()
}

$sourceHashAfter = (Get-FileHash -LiteralPath $SourceTemplate -Algorithm SHA256).Hash
if ($sourceHashBefore -ne $sourceHashAfter) {
    throw 'Source template changed while the friendly-name derivative was being built.'
}

$item = Get-Item -LiteralPath $OutputTemplate
[pscustomobject]@{
    Path = $item.FullName
    Bytes = $item.Length
    Sha256 = (Get-FileHash -LiteralPath $OutputTemplate -Algorithm SHA256).Hash.ToLowerInvariant()
    SourceSha256 = $sourceHashAfter.ToLowerInvariant()
}
