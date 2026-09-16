[CmdletBinding()]
param(
    [string]$SourceTemplate = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Cowork Value V1 Testing.pbit'),
    [string]$OutputTemplate = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Cowork Value V1 SharePoint Testing.pbit')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$utf16 = [System.Text.UnicodeEncoding]::new($false, $false)
$utf8 = [System.Text.UTF8Encoding]::new($false)

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
    if ($null -ne $existing) {
        $existing.Delete()
    }

    $entry = $Archive.CreateEntry($EntryName, [System.IO.Compression.CompressionLevel]::Optimal)
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

function Copy-JsonObject {
    param([object]$Value)
    return ($Value | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100)
}

function New-ModelExpression {
    param(
        [string]$Name,
        [string]$LineageTag,
        [string]$Expression,
        [string[]]$Description = @(),
        [string]$ResultType = ''
    )

    $properties = [ordered]@{
        name = $Name
    }
    if ($Description.Count -gt 0) {
        $properties.description = $Description
    }
    $properties.kind = 'm'
    $properties.expression = if ($Expression.Contains("`n")) { ConvertTo-MLines $Expression } else { $Expression }
    $properties.lineageTag = $LineageTag
    if ($ResultType -ne '') {
        $properties.annotations = @(
            [pscustomobject][ordered]@{
                name = 'PBI_ResultType'
                value = $ResultType
            }
        )
    }

    return [pscustomobject]$properties
}

function New-UnappliedQuery {
    param(
        [string]$Name,
        [string]$LineageTag,
        [string]$Expression,
        [string]$ResultType,
        [string]$Description = ''
    )

    $properties = [ordered]@{
        name = $Name
        lineageTag = $LineageTag
    }
    if ($Description -ne '') {
        $properties.description = $Description
    }
    $properties.text = ConvertTo-MLines $Expression
    $properties.loadAsTableDisabled = $true
    $properties.resultType = $ResultType
    $properties.isHidden = $false

    return [pscustomobject]$properties
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

function Replace-Literal {
    param(
        [string]$Text,
        [string]$OldValue,
        [string]$NewValue
    )

    if (-not $Text.Contains($OldValue)) {
        throw "Expected text was not found: $OldValue"
    }
    return $Text.Replace($OldValue, $NewValue)
}

$normalizeFolderUrl = @'
let
	fn = (raw as nullable text) as text =>
		let
			Trimmed = if raw = null then "" else Text.Trim(raw),
			Unquoted =
				let
					Length = Text.Length(Trimmed),
					Quotes = {"""", "'", "“", "”", "„", "‟", "‘", "’"}
				in
					if Length >= 2
						and List.Contains(Quotes, Text.At(Trimmed, 0))
						and List.Contains(Quotes, Text.At(Trimmed, Length - 1))
					then Text.Middle(Trimmed, 1, Length - 2)
					else Trimmed,
			Parts = try Uri.Parts(Unquoted) otherwise null,
			IdPath =
				if Parts <> null and Record.HasFields(Parts, "Query") and Parts[Query] is record
				then Record.FieldOrDefault(Parts[Query], "id", null)
				else null,
			HasIdPath = IdPath <> null and Parts <> null,
			QueryIndex = Text.PositionOfAny(Unquoted, {"?", "#"}),
			NoQuery = if QueryIndex >= 0 then Text.Start(Unquoted, QueryIndex) else Unquoted,
			DecodeInput = if HasIdPath then "" else NoQuery,
			HexValue = (character as text) as number =>
				let
					Code = Character.ToNumber(character)
				in
					if Code >= 48 and Code <= 57 then Code - 48
					else if Code >= 65 and Code <= 70 then Code - 55
					else if Code >= 97 and Code <= 102 then Code - 87
					else -1,
			Segments =
				let
					PartsByPercent = Text.Split(DecodeInput, "%"),
					Head = {{"t", PartsByPercent{0}}},
					Tail = List.Skip(PartsByPercent, 1)
				in
					List.Accumulate(
						Tail,
						Head,
						(state, part) =>
							if Text.Length(part) >= 2 then
								let
									High = HexValue(Text.At(part, 0)),
									Low = HexValue(Text.At(part, 1)),
									Rest = Text.Middle(part, 2)
								in
									if High >= 0 and Low >= 0
									then state & {{"b", {High * 16 + Low}}, {"t", Rest}}
									else state & {{"t", "%" & part}}
							else state & {{"t", "%" & part}}
					),
			NonEmptySegments =
				List.Select(
					Segments,
					(segment) => not (segment{0} = "t" and segment{1} = "")
				),
			MergedSegments =
				List.Accumulate(
					NonEmptySegments,
					{},
					(state, segment) =>
						if List.Count(state) > 0
							and (List.Last(state)){0} = "b"
							and segment{0} = "b"
						then List.RemoveLastN(state, 1) & {{"b", (List.Last(state)){1} & segment{1}}}
						else state & {segment}
				),
			DecodedDirect =
				Text.Combine(
					List.Transform(
						MergedSegments,
						(segment) =>
							if segment{0} = "t"
							then segment{1}
							else Text.FromBinary(Binary.FromList(segment{1}), TextEncoding.Utf8)
					)
				),
			Decoded =
				if HasIdPath
				then Text.From(Parts[Scheme]) & "://" & Text.From(Parts[Host]) & Text.From(IdPath)
				else DecodedDirect,
			StripSharingMarker = (url as text, marker as text) as text =>
				let
					Position = Text.PositionOf(Text.Lower(url), marker)
				in
					if Position < 0
					then url
					else Text.Start(url, Position) & "/" & Text.Range(url, Position + Text.Length(marker)),
			CheckedLink =
				if Text.Contains(Text.Lower(Decoded), "/:f:/s/")
					or Text.Contains(Text.Lower(Decoded), "/:f:/g/")
				then error "This opaque SharePoint sharing link does not contain a folder path. Open the folder and copy its address, use an AllItems.aspx?id= link, or use a path-bearing /:f:/r/ link."
				else Decoded,
			NoReadMarker = StripSharingMarker(CheckedLink, "/:f:/r/")
		in
			Text.Trim(NoReadMarker)
in
	fn
'@

$sharePointDataFiles = @'
let
	SiteRaw = if SharePointSiteUrl = null then "" else Text.Trim(SharePointSiteUrl),
	SiteNormalized = Text.TrimEnd(fnNormalizeSharePointFolderUrl(SiteRaw), "/"),
	FolderBase = Text.TrimEnd(fnNormalizeSharePointFolderUrl(SharePointFolderUrl), "/"),
	CheckedSite =
		if SiteRaw = "" then
			error "Enter the SharePoint site root in SharePointSiteUrl, for example https://contoso.sharepoint.com/sites/CoworkAnalytics."
		else if not Text.StartsWith(Text.Lower(SiteNormalized), "https://") or not Text.Contains(Text.Lower(SiteNormalized), "sharepoint") then
			error "SharePointSiteUrl must be an https SharePoint site root, not a local path or file link."
		else
			SiteNormalized,
	CheckedFolder =
		if FolderBase = "" then
			error "Enter the SharePoint folder link in SharePointFolderUrl."
		else if not Text.StartsWith(Text.Lower(FolderBase), Text.Lower(CheckedSite & "/")) then
			error "SharePointFolderUrl must point to a folder inside SharePointSiteUrl."
		else
			FolderBase & "/",
	AllFiles = SharePoint.Files(SharePointSiteUrl, [ApiVersion = 15]),
	InFolder =
		Table.SelectRows(
			AllFiles,
			each
				let
					CurrentFolder = Text.TrimEnd(fnNormalizeSharePointFolderUrl([Folder Path]), "/") & "/"
				in
					Text.StartsWith(Text.Lower(CurrentFolder), Text.Lower(CheckedFolder))
		)
in
	InFolder
'@

$findCsvContent = @'
let
	fn = (preferredNames as list, requiredColumns as list) as nullable binary =>
		let
			CsvFiles = Table.SelectRows(SharePointDataFiles, each Text.Lower([Extension]) = ".csv"),
			PreferredLower = List.Transform(preferredNames, each Text.Lower(Text.From(_))),
			HasRequiredColumns = (row as record) as logical =>
				let
					Parsed = try Table.PromoteHeaders(
						Csv.Document(row[Content], [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
						[PromoteAllScalars = true]
					) otherwise null
				in
					Value.Is(Parsed, type table) and List.IsEmpty(List.Difference(requiredColumns, Table.ColumnNames(Parsed))),
			Named = Table.SelectRows(CsvFiles, each List.Contains(PreferredLower, Text.Lower([Name]))),
			NamedValid = Table.SelectRows(Named, each HasRequiredColumns(_)),
			SchemaValid = if Table.IsEmpty(NamedValid) then Table.SelectRows(CsvFiles, each HasRequiredColumns(_)) else NamedValid,
			Ordered = Table.Sort(SchemaValid, {{"Folder Path", Order.Ascending}, {"Name", Order.Ascending}}),
			Match = if Table.IsEmpty(Ordered) then null else Ordered{0}
		in
			if Match = null then null else Match[Content]
in
	fn
'@

$loadCsv = @'
let
	fn = (content as binary) as table =>
		let
			Source = Csv.Document(content, [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
			Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
			Required = {"Display Name", "User Principal Name", "Monthly credit limit", "Monthly credits used", "User ID", "Microsoft 365 Copilot license", "Last activity date", "Session Count", "% Used"},
			Actual = Table.ColumnNames(Promoted),
			Missing = List.Difference(Required, Actual),
			Checked = if List.Count(Missing) > 0 then error "fnLoadCsv: missing required column(s): " & Text.Combine(Missing, ", ") else Promoted
		in
			Checked
in
	fn
'@

$creditCsvContent = @'
fnFindCsvContent(
	{"CoworkConsumptionDetails.csv", "Consumption - Users.csv"},
	{"Display Name", "User Principal Name", "Monthly credit limit", "Monthly credits used", "User ID", "Microsoft 365 Copilot license", "Last activity date", "Session Count", "% Used"}
)
'@

$coworkUsageCsvContent = @'
fnFindCsvContent(
	{"CoworkUserDetails.csv", "Cowork Usage.csv"},
	{"UserPrincipalName", "DisplayName", "TotalTasks", "ScheduledTasks", "UserInitiatedTasks", "ActiveDays", "LastActivityDate"}
)
'@

$orgCsvContent = @'
fnFindCsvContent(
	{"CoworkUserOrgDetails.csv", "Cowork User Organization.csv"},
	{"userPrincipalName", "displayName", "department", "jobTitle", "jobFamily", "city", "country", "costCenter", "manager", "businessUnit"}
)
'@

if (-not (Test-Path -LiteralPath $SourceTemplate -PathType Leaf)) {
    throw "Source template not found: $SourceTemplate"
}

$outputDirectory = Split-Path $OutputTemplate -Parent
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}
Copy-Item -LiteralPath $SourceTemplate -Destination $OutputTemplate -Force

$stream = [System.IO.File]::Open($OutputTemplate, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
try {
    $archive = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Update, $false)
    try {
        $model = (Read-ZipText $archive 'DataModelSchema' $utf16) | ConvertFrom-Json -Depth 100
        $unapplied = (Read-ZipText $archive 'UnappliedChanges' $utf16) | ConvertFrom-Json -Depth 100

        $expressionByName = @{}
        foreach ($expression in $model.model.expressions) {
            $expressionByName[$expression.name] = $expression
        }

        $auditExpression = Copy-JsonObject $expressionByName['Fact_CopilotAuditRaw_WithLists']
        $auditText = ConvertTo-MText $auditExpression.expression
        $auditText = Replace-Literal $auditText 'Files0 = Folder.Files(CopilotAuditFolderPath),' 'Files0 = SharePointDataFiles,'
        $auditText = $auditText.Replace('under DataFolderPath', 'under SharePointFolderUrl')
        $auditExpression.expression = ConvertTo-MLines $auditText
        $auditExpression.description = @(
            'Shared parser used by the audit fact and resource/plugin bridges.',
            'It reads every schema-valid Purview CSV below SharePointFolderUrl.'
        )

        $siteParameter = New-ModelExpression `
            -Name 'SharePointSiteUrl' `
            -LineageTag 'b1e60d8d-49f4-4b3b-8af8-1c1315a48201' `
            -Expression 'null meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]' `
            -Description @(
                'Required SharePoint site root used by the static SharePoint.Files connector.',
                'Example: https://contoso.sharepoint.com/sites/CoworkAnalytics'
            ) `
            -ResultType 'Text'

        $folderParameter = New-ModelExpression `
            -Name 'SharePointFolderUrl' `
            -LineageTag 'df9c98a5-48ab-489a-923a-cd3235d7e8cc' `
            -Expression 'null meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]' `
            -Description @(
                'Required direct, path-bearing /:f:/r/, or AllItems.aspx SharePoint folder link.',
                'All supported CSV files below this folder are discovered recursively.'
            ) `
            -ResultType 'Text'

        $newExpressions = @(
            $siteParameter
            $folderParameter
            (New-ModelExpression -Name 'fnNormalizeSharePointFolderUrl' -LineageTag 'd1cdf204-b0d5-447a-ae1a-4dc3f24955ea' -Expression $normalizeFolderUrl -Description @('Normalizes direct and copied SharePoint folder links without changing the connector data-source root.'))
            (New-ModelExpression -Name 'SharePointDataFiles' -LineageTag 'd389ebad-49f7-45dc-9b91-f3a65fd52228' -Expression $sharePointDataFiles -Description @('Lists files below SharePointFolderUrl through the static SharePointSiteUrl connector.') -ResultType 'Table')
            (New-ModelExpression -Name 'fnFindCsvContent' -LineageTag 'a4d7bb28-a6b5-4974-9bb0-fdb01de09f82' -Expression $findCsvContent -Description @('Finds an optional CSV below SharePointFolderUrl by preferred filename, then by required headers.'))
            (New-ModelExpression -Name 'fnLoadCsv' -LineageTag '38d1df1b-008d-45ff-b72c-506be9198f23' -Expression $loadCsv -Description @('Loads and validates the optional Microsoft admin center Consumption - Users CSV from SharePoint binary content.'))
            (New-ModelExpression -Name 'CreditCsvContent' -LineageTag '42ce1bbf-ae41-46a0-80e7-a61843e91fe0' -Expression $creditCsvContent -Description @('Optional Microsoft admin center Consumption - Users CSV content discovered below SharePointFolderUrl.'))
            (New-ModelExpression -Name 'CoworkUsageCsvContent' -LineageTag 'b1436d3a-1657-4199-8e91-09673a96dc2c' -Expression $coworkUsageCsvContent -Description @('Optional Microsoft admin center Cowork usage CSV content discovered below SharePointFolderUrl.'))
            (New-ModelExpression -Name 'OrgCsvContent' -LineageTag '8f6b1a2e-3c7d-4e5f-9a1b-2d4c6e8f0a1b' -Expression $orgCsvContent -Description @('Optional Entra or HR organization CSV content discovered below SharePointFolderUrl.'))
            $auditExpression
        )

        $removedExpressionNames = @(
            'DataFolderPath',
            'fnFindCsvPath',
            'fnLoadCsv',
            'CreditCsvPath',
            'CopilotAuditFolderPath',
            'CoworkUsageCsvPath',
            'OrgCsvPath',
            'SampleDataFolder',
            'Fact_CopilotAuditRaw_WithLists'
        )
        $keptExpressions = @($model.model.expressions | Where-Object { $_.name -notin $removedExpressionNames })
        $model.model.expressions = @($newExpressions + $keptExpressions)

        $partitionReplacements = [ordered]@{
            'Dim_User' = [ordered]@{
                'Folder.Files(CopilotAuditFolderPath)' = 'SharePointDataFiles'
                'Folder.Files(SampleDataFolder)' = 'SharePointDataFiles'
                'fnLoadCsv(CreditCsvPath)' = 'fnLoadCsv(CreditCsvContent)'
                'under DataFolderPath' = 'under SharePointFolderUrl'
            }
            'Fact_Consumption' = [ordered]@{
                'fnLoadCsv(CreditCsvPath)' = 'fnLoadCsv(CreditCsvContent)'
                'under DataFolderPath' = 'under SharePointFolderUrl'
            }
            'Fact_CoworkUsage' = [ordered]@{
                'File.Contents(CoworkUsageCsvPath)' = 'CoworkUsageCsvContent'
                'under DataFolderPath' = 'under SharePointFolderUrl'
            }
            'Dim_UserOrg' = [ordered]@{
                'File.Contents(OrgCsvPath)' = 'OrgCsvContent'
                'under DataFolderPath' = 'under SharePointFolderUrl'
            }
            'Metric Glossary' = [ordered]@{
                '"DataFolderPath", "The one required setup input. Place the real Purview/Copilot audit exports and any optional consumption, usage, identity, or organization CSVs anywhere under this folder; the model discovers supported files by filename or schema. (Real, required)"' = '"SharePoint connection", "Two required setup inputs: SharePointSiteUrl is the site root used for authentication; SharePointFolderUrl is the protected folder link containing Purview and optional CSV exports. Discovery is recursive. (Real, required)"'
                'in DataFolderPath' = 'below SharePointFolderUrl'
            }
        }

        foreach ($tableName in $partitionReplacements.Keys) {
            $table = $model.model.tables | Where-Object { $_.name -eq $tableName } | Select-Object -First 1
            if ($null -eq $table) {
                throw "Model table not found: $tableName"
            }

            $partition = $table.partitions | Select-Object -First 1
            $sourceText = ConvertTo-MText $partition.source.expression
            foreach ($oldValue in $partitionReplacements[$tableName].Keys) {
                $sourceText = Replace-Literal $sourceText $oldValue $partitionReplacements[$tableName][$oldValue]
            }
            $partition.source.expression = ConvertTo-MLines $sourceText

            $query = $unapplied.queries | Where-Object { $_.name -eq $tableName } | Select-Object -First 1
            if ($null -eq $query) {
                throw "Unapplied query not found: $tableName"
            }
            Set-UnappliedFormula $query $sourceText
        }

        $auditTable = $model.model.tables | Where-Object { $_.name -eq 'Fact_CopilotAuditRaw' } | Select-Object -First 1
        if ($null -ne $auditTable -and $auditTable.PSObject.Properties.Name -contains 'description') {
            $auditTable.description = @(
                'Additive fact table with one row per Purview CopilotInteraction audit record.',
                'Raw Purview export CSVs are discovered recursively below SharePointFolderUrl.'
            )
        }

        $queryOrderAnnotation = $model.model.annotations | Where-Object { $_.name -eq 'PBI_QueryOrder' } | Select-Object -First 1
        if ($null -eq $queryOrderAnnotation) {
            throw 'PBI_QueryOrder annotation not found.'
        }
        $oldQueryOrder = @($queryOrderAnnotation.value | ConvertFrom-Json)
        $newQueryNames = @(
            'SharePointSiteUrl',
            'SharePointFolderUrl',
            'fnNormalizeSharePointFolderUrl',
            'SharePointDataFiles',
            'fnFindCsvContent',
            'fnLoadCsv',
            'CreditCsvContent',
            'CoworkUsageCsvContent',
            'OrgCsvContent',
            'Fact_CopilotAuditRaw_WithLists'
        )
        $keptQueryOrder = @($oldQueryOrder | Where-Object { $_ -notin $removedExpressionNames -and $_ -notin $newQueryNames })
        $queryOrderAnnotation.value = @($newQueryNames + $keptQueryOrder) | ConvertTo-Json -Compress

        $oldUnappliedByName = @{}
        foreach ($query in $unapplied.queries) {
            $oldUnappliedByName[$query.name] = $query
        }
        $auditUnapplied = Copy-JsonObject $oldUnappliedByName['Fact_CopilotAuditRaw_WithLists']
        $auditUnapplied.name = 'Fact_CopilotAuditRaw_WithLists'
        if ($auditUnapplied.PSObject.Properties.Name -contains 'description') {
            $auditUnapplied.description = 'Shared SharePoint-backed parser for the audit fact and resource/plugin bridges.'
        }
        else {
            $auditUnapplied | Add-Member -NotePropertyName description -NotePropertyValue 'Shared SharePoint-backed parser for the audit fact and resource/plugin bridges.'
        }
        Set-UnappliedFormula $auditUnapplied $auditText

        $newUnappliedQueries = @(
            (New-UnappliedQuery -Name 'SharePointSiteUrl' -LineageTag 'b1e60d8d-49f4-4b3b-8af8-1c1315a48201' -Expression 'null meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]' -ResultType 'Text' -Description 'Required SharePoint site root, for example https://contoso.sharepoint.com/sites/CoworkAnalytics.')
            (New-UnappliedQuery -Name 'SharePointFolderUrl' -LineageTag 'df9c98a5-48ab-489a-923a-cd3235d7e8cc' -Expression 'null meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]' -ResultType 'Text' -Description 'Required direct, path-bearing /:f:/r/, or AllItems.aspx link to the protected SharePoint folder containing the CSV exports.')
            (New-UnappliedQuery -Name 'fnNormalizeSharePointFolderUrl' -LineageTag 'd1cdf204-b0d5-447a-ae1a-4dc3f24955ea' -Expression $normalizeFolderUrl -ResultType 'Unknown')
            (New-UnappliedQuery -Name 'SharePointDataFiles' -LineageTag 'd389ebad-49f7-45dc-9b91-f3a65fd52228' -Expression $sharePointDataFiles -ResultType 'Table')
            (New-UnappliedQuery -Name 'fnFindCsvContent' -LineageTag 'a4d7bb28-a6b5-4974-9bb0-fdb01de09f82' -Expression $findCsvContent -ResultType 'Unknown')
            (New-UnappliedQuery -Name 'fnLoadCsv' -LineageTag '38d1df1b-008d-45ff-b72c-506be9198f23' -Expression $loadCsv -ResultType 'Unknown')
            (New-UnappliedQuery -Name 'CreditCsvContent' -LineageTag '42ce1bbf-ae41-46a0-80e7-a61843e91fe0' -Expression $creditCsvContent -ResultType 'Unknown')
            (New-UnappliedQuery -Name 'CoworkUsageCsvContent' -LineageTag 'b1436d3a-1657-4199-8e91-09673a96dc2c' -Expression $coworkUsageCsvContent -ResultType 'Unknown')
            (New-UnappliedQuery -Name 'OrgCsvContent' -LineageTag '8f6b1a2e-3c7d-4e5f-9a1b-2d4c6e8f0a1b' -Expression $orgCsvContent -ResultType 'Unknown')
            $auditUnapplied
        )
        $keptUnappliedQueries = @($unapplied.queries | Where-Object { $_.name -notin $removedExpressionNames })
        $unapplied.queries = @($newUnappliedQueries + $keptUnappliedQueries)

        $modelJson = ($model | ConvertTo-Json -Depth 100).Replace('DataFolderPath', 'SharePointFolderUrl')
        $unappliedJson = ($unapplied | ConvertTo-Json -Depth 100 -Compress).Replace('DataFolderPath', 'SharePointFolderUrl')
        Write-ZipText $archive 'DataModelSchema' $modelJson $utf16
        Write-ZipText $archive 'UnappliedChanges' $unappliedJson $utf16

        $startHereEntry = 'Report/definition/pages/00_start_here/visuals/sh_card4_desc/visual.json'
        $startHere = Read-ZipText $archive $startHereEntry $utf8
        $startHere = Replace-Literal `
            $startHere `
            'Choose one DataFolderPath. Add Purview audit CSVs plus optional consumption, usage, identity, and organization exports; supported files are discovered automatically.' `
            'Enter the SharePoint site URL and folder link. Add Purview audit CSVs plus optional consumption, usage, identity, and organization exports; supported files are discovered recursively.'
        Write-ZipText $archive $startHereEntry $startHere $utf8

        $modelBreakdownEntry = 'Report/definition/pages/92g_model_breakdown/visuals/mb_narrative/visual.json'
        $modelBreakdown = Read-ZipText $archive $modelBreakdownEntry $utf8
        $modelBreakdown = Replace-Literal `
            $modelBreakdown `
            'load customer Purview exports through DataFolderPath.' `
            'load customer Purview exports through the SharePoint folder connection.'
        Write-ZipText $archive $modelBreakdownEntry $modelBreakdown $utf8
    }
    finally {
        $archive.Dispose()
    }
}
finally {
    $stream.Dispose()
}

$hash = (Get-FileHash -LiteralPath $OutputTemplate -Algorithm SHA256).Hash.ToLowerInvariant()
$item = Get-Item -LiteralPath $OutputTemplate
[pscustomobject]@{
    Path = $item.FullName
    Bytes = $item.Length
    Sha256 = $hash
}
