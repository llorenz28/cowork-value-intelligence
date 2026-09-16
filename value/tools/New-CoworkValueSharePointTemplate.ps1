[CmdletBinding()]
param(
    [string]$SourceTemplate = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Cowork Value V1 Testing.pbit'),
    [string]$OutputTemplate = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Cowork Value V1.2 SharePoint Testing.pbit')
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

function Replace-TextRange {
    param(
        [string]$Text,
        [string]$StartMarker,
        [string]$EndMarker,
        [string]$Replacement
    )

    $start = $Text.IndexOf($StartMarker, [System.StringComparison]::Ordinal)
    if ($start -lt 0) {
        throw "Expected range start was not found: $StartMarker"
    }

    $end = $Text.IndexOf($EndMarker, $start, [System.StringComparison]::Ordinal)
    if ($end -lt 0) {
        throw "Expected range end was not found: $EndMarker"
    }

    return $Text.Substring(0, $start) + $Replacement + $Text.Substring($end)
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

$purviewAuditParsed = @'
let
	Files0 = SharePointDataFiles,
	CsvOnly = Table.SelectRows(Files0, each Text.Lower([Extension]) = ".csv"),

	FinalSchema = type table [
		RecordId = text, CreationDateParsed = nullable datetime, DateKey = nullable Int64.Type,
		Audit_UserId = nullable text, Audit_UserId_Normalized = nullable text,
		Workload = nullable text, ClientRegion = nullable text, AppIdentity = nullable text, AppHost = nullable text, ThreadId = nullable text, LicenseType = nullable text,
		TriggerType = nullable text,
		Message_Count = Int64.Type, Message_PromptCount = Int64.Type,
		Plugin_Count = Int64.Type, Plugin_FirstId = nullable text, Plugin_FirstName = nullable text,
		Resource_Count = Int64.Type, AccessedResource_FirstSiteUrl = nullable text, AccessedResource_FirstAction = nullable text,
		ModelProviderName = nullable text,
		_messages = list, _plugins = list, _resources = list, _models = list
	],
	EmptyPerFile = #table(FinalSchema, {}),

	ToText = (value as any) as nullable text =>
		let
			Scalar =
				if value = null then null
				else if Value.Is(value, type list) then
					List.First(List.RemoveNulls(List.Transform(value, each try Text.From(_) otherwise null)), null)
				else
					try Text.From(value) otherwise null,
			Trimmed = if Scalar = null then null else Text.Trim(Scalar),
			ParsedList = if Trimmed <> null and Text.StartsWith(Trimmed, "[") then try Json.Document(Trimmed) otherwise null else null,
			FirstParsed =
				if ParsedList <> null and Value.Is(ParsedList, type list)
				then List.First(List.RemoveNulls(List.Transform(ParsedList, each try Text.From(_) otherwise null)), null)
				else null
		in
			if FirstParsed = null then Trimmed else Text.Trim(FirstParsed),
	FirstText = (values as list) as nullable text =>
		List.First(List.Select(List.Transform(values, each ToText(_)), each _ <> null and _ <> ""), null),

	ProcessOneFile = (fileContent as binary, sourcePath as text) as table =>
		let
			Attempt = try
				let
					Parsed = Csv.Document(fileContent, [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
					Promoted = Table.PromoteHeaders(Parsed, [PromoteAllScalars = true]),
					HasAuditData = Table.HasColumns(Promoted, {"AuditData"}),
					Base =
						if not HasAuditData then EmptyPerFile
						else
							let
								Indexed = Table.AddIndexColumn(Promoted, "_sourceRow", 1, 1, Int64.Type),
								AddJson = Table.AddColumn(Indexed, "_json", each
									let a = try Json.Document(Text.ToBinary(Text.From([AuditData])))
									in if a[HasError] or not Value.Is(a[Value], type record) then null else a[Value]
								),
								OnlyValidJson = Table.SelectRows(AddJson, each [_json] <> null),
								AddOperation = Table.AddColumn(OnlyValidJson, "_operation", (row as record) =>
									FirstText({
										Record.FieldOrDefault(row, "Operation", null),
										Record.FieldOrDefault(row, "Operations", null),
										Record.FieldOrDefault(row[_json], "Operation", null),
										Record.FieldOrDefault(row[_json], "Operations", null)
									}), type nullable text),
								OnlyCopilot = Table.SelectRows(AddOperation, each [_operation] <> null and Text.Lower(Text.Trim([_operation])) = "copilotinteraction"),

								AddAuditUser = Table.AddColumn(OnlyCopilot, "_auditUserId", (row as record) =>
									FirstText({
										Record.FieldOrDefault(row, "UserId", null),
										Record.FieldOrDefault(row, "UserIds", null),
										Record.FieldOrDefault(row[_json], "UserId", null),
										Record.FieldOrDefault(row[_json], "UserIds", null)
									}), type nullable text),
								AddCreationText = Table.AddColumn(AddAuditUser, "_creationDate", (row as record) =>
									FirstText({
										Record.FieldOrDefault(row, "CreationDate", null),
										Record.FieldOrDefault(row[_json], "CreationDate", null),
										Record.FieldOrDefault(row[_json], "CreationTime", null)
									}), type nullable text),
								AddCed = Table.AddColumn(AddCreationText, "_ced", each try [_json][CopilotEventData] otherwise null),

								AddWorkload = Table.AddColumn(AddCed, "Workload", each try ToText([_json][Workload]) otherwise null, type nullable text),
								AddClientRegion = Table.AddColumn(AddWorkload, "ClientRegion", each try ToText([_json][ClientRegion]) otherwise null, type nullable text),
								AddAppIdentity = Table.AddColumn(AddClientRegion, "AppIdentity", each try ToText([_json][AppIdentity]) otherwise null, type nullable text),
								AddAppHost = Table.AddColumn(AddAppIdentity, "AppHost", each if [_ced] = null then null else (try ToText([_ced][AppHost]) otherwise null), type nullable text),
								AddThreadId = Table.AddColumn(AddAppHost, "ThreadId", each if [_ced] = null then null else (try ToText([_ced][ThreadId]) otherwise null), type nullable text),
								AddLicenseType = Table.AddColumn(AddThreadId, "LicenseType", each if [_ced] = null then null else (try ToText([_ced][LicenseType]) otherwise null), type nullable text),
								AddTriggerType = Table.AddColumn(AddLicenseType, "TriggerType", each if [_ced] = null then null else (try ToText([_ced][TriggerType]) otherwise null), type nullable text),

								AddMsgList = Table.AddColumn(AddTriggerType, "_messages", each if [_ced] = null then {} else (let m = try [_ced][Messages] otherwise null in if Value.Is(m, type list) then m else {})),
								AddMsgCount = Table.AddColumn(AddMsgList, "Message_Count", each List.Count([_messages]), Int64.Type),
								AddPromptCount = Table.AddColumn(AddMsgCount, "Message_PromptCount", each List.Count(List.Select([_messages], each (try _[isPrompt] otherwise false) = true)), Int64.Type),

								AddPluginList = Table.AddColumn(AddPromptCount, "_plugins", each if [_ced] = null then {} else (let p = try [_ced][AISystemPlugin] otherwise null in if Value.Is(p, type list) then p else {})),
								AddPluginCount = Table.AddColumn(AddPluginList, "Plugin_Count", each List.Count([_plugins]), Int64.Type),
								AddPluginFirstName = Table.AddColumn(AddPluginCount, "Plugin_FirstName", each if List.IsEmpty([_plugins]) then null else (try ToText([_plugins]{0}[Name]) otherwise null), type nullable text),
								AddPluginFirstId = Table.AddColumn(AddPluginFirstName, "Plugin_FirstId", each if List.IsEmpty([_plugins]) then null else (try ToText([_plugins]{0}[Id]) otherwise null), type nullable text),

								AddResList = Table.AddColumn(AddPluginFirstId, "_resources", each if [_ced] = null then {} else (let r = try [_ced][AccessedResources] otherwise null in if Value.Is(r, type list) then r else {})),
								AddResCount = Table.AddColumn(AddResList, "Resource_Count", each List.Count([_resources]), Int64.Type),
								AddResSiteUrl = Table.AddColumn(AddResCount, "AccessedResource_FirstSiteUrl", each if List.IsEmpty([_resources]) then null else (try ToText([_resources]{0}[SiteUrl]) otherwise null), type nullable text),
								AddResAction = Table.AddColumn(AddResSiteUrl, "AccessedResource_FirstAction", each if List.IsEmpty([_resources]) then null else (let a = try ToText([_resources]{0}[Action]) otherwise null in if a <> null then a else (try ToText([_resources]{0}[Type]) otherwise null)), type nullable text),

								AddModelList = Table.AddColumn(AddResAction, "_models", each if [_ced] = null then {} else (let mo = try [_ced][ModelTransparencyDetails] otherwise null in if Value.Is(mo, type list) then mo else {})),
								AddModelProvider = Table.AddColumn(AddModelList, "ModelProviderName", each if List.IsEmpty([_models]) then null else (try ToText([_models]{0}[ModelProviderName]) otherwise null), type nullable text),

								AddRecordId = Table.AddColumn(AddModelProvider, "_recordId", (row as record) =>
									let
										Observed = FirstText({
											Record.FieldOrDefault(row, "RecordId", null),
											Record.FieldOrDefault(row, "Id", null),
											Record.FieldOrDefault(row[_json], "RecordId", null),
											Record.FieldOrDefault(row[_json], "Id", null)
										})
									in
										if Observed = null then sourcePath & "#" & Text.From(row[_sourceRow]) else Observed,
									type text),
								AddDateParsed = Table.AddColumn(AddRecordId, "CreationDateParsed", each
									let
										t = [_creationDate],
										a = if t = null then null else try DateTimeZone.RemoveZone(DateTimeZone.FromText(t)) otherwise null
									in
										if a <> null then a else if t = null then null else (try DateTime.FromText(t) otherwise null),
									type nullable datetime),
								AddDateKey = Table.AddColumn(AddDateParsed, "DateKey", each
									if [CreationDateParsed] = null then null
									else Date.Year(DateTime.Date([CreationDateParsed])) * 10000 + Date.Month(DateTime.Date([CreationDateParsed])) * 100 + Date.Day(DateTime.Date([CreationDateParsed])),
									Int64.Type),
								AddUpnNorm = Table.AddColumn(AddDateKey, "_auditUserIdNormalized", each if [_auditUserId] = null then null else Text.Lower(Text.Trim([_auditUserId])), type nullable text),

								Projected = Table.SelectColumns(AddUpnNorm, {
									"_recordId", "CreationDateParsed", "DateKey", "_auditUserId", "_auditUserIdNormalized",
									"Workload", "ClientRegion", "AppIdentity", "AppHost", "ThreadId", "LicenseType", "TriggerType",
									"Message_Count", "Message_PromptCount",
									"Plugin_Count", "Plugin_FirstId", "Plugin_FirstName",
									"Resource_Count", "AccessedResource_FirstSiteUrl", "AccessedResource_FirstAction",
									"ModelProviderName", "_messages", "_plugins", "_resources", "_models"
								}),
								Renamed = Table.RenameColumns(Projected, {
									{"_recordId", "RecordId"},
									{"_auditUserId", "Audit_UserId"},
									{"_auditUserIdNormalized", "Audit_UserId_Normalized"}
								})
							in
								Value.ReplaceType(Renamed, FinalSchema)
				in
					Base
		in
			if Attempt[HasError] then EmptyPerFile else Attempt[Value],

	AddProcessed = Table.AddColumn(CsvOnly, "Processed", each ProcessOneFile([Content], Text.From([Folder Path]) & Text.From([Name]))),
	AllExtracted = if Table.IsEmpty(AddProcessed) then EmptyPerFile else Table.Combine(AddProcessed[Processed]),
	Deduped = Table.Distinct(AllExtracted, {"RecordId"})
in
	Deduped
'@

$auditWithLists = @'
let
	MergeUser = Table.NestedJoin(PurviewAuditParsed, {"Audit_UserId_Normalized"}, Dim_User, {"UserPrincipalName"}, "u", JoinKind.LeftOuter),
	AddUserKeyExpanded = Table.ExpandTableColumn(MergeUser, "u", {"UserKey"}, {"UserKey"}),
	Final = Table.SelectColumns(AddUserKeyExpanded, {
		"RecordId", "CreationDateParsed", "DateKey", "Audit_UserId", "Audit_UserId_Normalized", "UserKey",
		"Workload", "ClientRegion", "AppIdentity", "AppHost", "ThreadId", "LicenseType", "TriggerType",
		"Message_Count", "Message_PromptCount",
		"Plugin_Count", "Plugin_FirstId", "Plugin_FirstName",
		"Resource_Count", "AccessedResource_FirstSiteUrl", "AccessedResource_FirstAction",
		"ModelProviderName", "_messages", "_plugins", "_resources", "_models"
	})
in
	Final
'@

$dimUserSeedBlock = @'
// Build the user population from both recognized Purview Cowork events and the
					// Cowork usage export. This keeps usage-only customers visible while clearly
					// leaving Purview-dependent facts unavailable.
					PurviewCoworkRows = Table.SelectRows(
						PurviewAuditParsed,
						each [Audit_UserId_Normalized] <> null
							and [AppHost] <> null
							and Text.Contains(Text.Lower(Text.Trim(Text.From([AppHost]))), "cowork")
					),
					PurviewUpns = List.Distinct(List.RemoveNulls(PurviewCoworkRows[Audit_UserId_Normalized])),
					UsageLookup =
						try
							let
								UsageSource = Csv.Document(CoworkUsageCsvContent, [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
								UsagePromoted = Table.PromoteHeaders(UsageSource, [PromoteAllScalars = true]),
								UsageSelected = Table.SelectColumns(UsagePromoted, {"UserPrincipalName", "DisplayName"}),
								UsageNormalized = Table.AddColumn(UsageSelected, "_upnNorm", each
									if [UserPrincipalName] = null then null else Text.Lower(Text.Trim(Text.From([UserPrincipalName]))),
									type nullable text),
								UsageValid = Table.SelectRows(UsageNormalized, each [_upnNorm] <> null and [_upnNorm] <> ""),
								UsageGrouped = Table.Group(UsageValid, {"_upnNorm"}, {
									{"_usageDisplayName", each List.First(List.Select([DisplayName], each _ <> null and Text.Trim(Text.From(_)) <> ""), null), type nullable text}
								})
							in
								UsageGrouped
						otherwise
							#table(type table [_upnNorm = text, _usageDisplayName = nullable text], {}),
					DynamicCoworkUpns = List.Distinct(List.Combine({PurviewUpns, UsageLookup[_upnNorm]})),
					CoworkUpnTable = Table.FromList(DynamicCoworkUpns, Splitter.SplitByNothing(), {"_upnNorm"}),


'@

$coworkUsageTypedBlock = @'
Typed = Table.TransformColumnTypes(Checked, {{"TotalTasks", Int64.Type}, {"ScheduledTasks", Int64.Type}, {"UserInitiatedTasks", Int64.Type}, {"ActiveDays", Int64.Type}, {"LastActivityDate", type datetime}}),
								NormalizedUpn = Table.TransformColumns(Typed, {{"UserPrincipalName", each if _ = null then null else Text.Lower(Text.Trim(Text.From(_))), type nullable text}})
							in
								NormalizedUpn
'@

$templateDataReadiness = @'
VAR _purviewCoworkRows =
    COUNTROWS(
        FILTER(
            ALL(Fact_CopilotAuditRaw),
            CONTAINSSTRING(LOWER(TRIM(COALESCE(Fact_CopilotAuditRaw[AppHost], ""))), "cowork")
        )
    )
VAR _usageRows =
    COUNTROWS(
        FILTER(
            ALL(Fact_CoworkUsage),
            CONTAINSSTRING(Fact_CoworkUsage[DataQuality], "discovered under")
        )
    )
VAR _unmatchedUsageRows =
    COUNTROWS(
        FILTER(
            ALL(Fact_CoworkUsage),
            CONTAINSSTRING(Fact_CoworkUsage[DataQuality], "discovered under")
                && ISBLANK(Fact_CoworkUsage[UserKey])
        )
    )
VAR _users = COUNTROWS(ALL(Dim_User))
VAR _consumptionReady = [Consumption Data Available]
RETURN
SWITCH(
    TRUE(),
    _purviewCoworkRows = 0 && _usageRows = 0,
        "ACTION REQUIRED: No recognized Purview Cowork events or Cowork usage rows loaded. Verify the SharePoint folder, then export CopilotInteraction rows with AuditData and AppHost containing cowork.",
    _purviewCoworkRows = 0,
        "PARTIAL LOAD: " & FORMAT(_usageRows, "#,0") & " Cowork usage rows loaded for " & FORMAT(_users, "#,0") & " users, but no recognized Purview Cowork events. Purview-dependent activity, skills, task detail, and value remain unavailable.",
    _unmatchedUsageRows > 0,
        "ACTION REQUIRED: Purview loaded, but " & FORMAT(_unmatchedUsageRows, "#,0") & " Cowork usage rows did not match a user after normalized UPN matching. Check for blank or anonymized user IDs.",
    _usageRows = 0,
        "CORE ACTIVITY READY: " & FORMAT(_purviewCoworkRows, "#,0") & " recognized Purview Cowork events. Cowork usage is absent, so scheduled versus user-initiated metrics are unavailable." &
        IF(_consumptionReady, "", " Consumption is also absent, so credit, cost, utilization, ROI, and Right-Sizing are unavailable."),
    NOT _consumptionReady,
        "CORE ACTIVITY READY: " & FORMAT(_purviewCoworkRows, "#,0") & " recognized Purview Cowork events and " & FORMAT(_usageRows, "#,0") & " usage rows. Consumption is absent, so credit, cost, utilization, ROI, and Right-Sizing are unavailable.",
    "ALL CORE INPUTS READY: " & FORMAT(_purviewCoworkRows, "#,0") & " recognized Purview Cowork events, " & FORMAT(_usageRows, "#,0") & " usage rows, and matched consumption data."
)
'@

$pageGateUsage = @'
VAR _usageRows =
    COUNTROWS(
        FILTER(
            ALL(Fact_CoworkUsage),
            CONTAINSSTRING(Fact_CoworkUsage[DataQuality], "discovered under")
        )
    )
VAR _unmatchedRows =
    COUNTROWS(
        FILTER(
            ALL(Fact_CoworkUsage),
            CONTAINSSTRING(Fact_CoworkUsage[DataQuality], "discovered under")
                && ISBLANK(Fact_CoworkUsage[UserKey])
        )
    )
RETURN
SWITCH(
    TRUE(),
    _usageRows = 0, "Connect the Cowork usage export to enable reported usage metrics.",
    _unmatchedRows > 0, "Cowork usage loaded, but " & FORMAT(_unmatchedRows, "#,0") & " row(s) did not match a user. Check for blank or anonymized user IDs.",
    BLANK()
)
'@

$coworkFilterHealth = @'
VAR RawRows = COUNTROWS(ALL(Fact_CopilotAuditRaw))
VAR CoworkRows =
    COUNTROWS(
        FILTER(
            ALL(Fact_CopilotAuditRaw),
            CONTAINSSTRING(
                LOWER(TRIM(COALESCE(Fact_CopilotAuditRaw[AppHost], ""))),
                "cowork"
            )
        )
    )
RETURN
    SWITCH(
        TRUE(),
        RawRows = 0, "No audit data loaded.",
        CoworkRows = 0, "WARNING: audit data is present but no AppHost value contains ""cowork"". Re-inspect a known Cowork user's records before trusting this report.",
        "OK - " & FORMAT(CoworkRows, "#,0") & " Cowork records isolated."
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
        $auditText = $auditWithLists
        $auditExpression.expression = ConvertTo-MLines $auditText
        $auditExpression.description = @(
            'Adds resolved user keys to the shared Purview parser for audit facts and resource/plugin bridges.'
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
            (New-ModelExpression -Name 'PurviewAuditParsed' -LineageTag '0dce9a7d-d592-4c4b-b38a-67bf6151d67e' -Expression $purviewAuditParsed -Description @('Parses both current Operations/UserIds and legacy Operation/UserId Purview Audit Search CSV formats before user resolution.') -ResultType 'Table')
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
            'PurviewAuditParsed',
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
                'Text.Lower(Text.From([AppHost])) = "cowork"' = '[AppHost] <> null and Text.Contains(Text.Lower(Text.Trim(Text.From([AppHost]))), "cowork")'
            }
            'Fact_Tasks' = [ordered]@{
                'Text.Lower(Text.From([AppHost])) = "cowork"' = '[AppHost] <> null and Text.Contains(Text.Lower(Text.Trim(Text.From([AppHost]))), "cowork")'
            }
            'Bridge_CoworkPlugin' = [ordered]@{
                'Text.Lower([AppHost]) = "cowork"' = '[AppHost] <> null and Text.Contains(Text.Lower(Text.Trim(Text.From([AppHost]))), "cowork")'
            }
            'Bridge_CoworkResource' = [ordered]@{
                'Text.Lower([AppHost]) = "cowork"' = '[AppHost] <> null and Text.Contains(Text.Lower(Text.Trim(Text.From([AppHost]))), "cowork")'
            }
            'Fact_CoworkAction' = [ordered]@{
                'Text.Lower(Text.From([AppHost])) = "cowork"' = '[AppHost] <> null and Text.Contains(Text.Lower(Text.Trim(Text.From([AppHost]))), "cowork")'
            }
            'Fact_CoworkThread' = [ordered]@{
                'Text.Lower([AppHost]) = "cowork"' = '[AppHost] <> null and Text.Contains(Text.Lower(Text.Trim(Text.From([AppHost]))), "cowork")'
            }
            'Fact_CoworkUsage' = [ordered]@{
                'File.Contents(CoworkUsageCsvPath)' = 'CoworkUsageCsvContent'
                'under DataFolderPath' = 'under SharePointFolderUrl'
                'Text.Lower([AppHost]) = "cowork"' = '[AppHost] <> null and Text.Contains(Text.Lower(Text.Trim(Text.From([AppHost]))), "cowork")'
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

            if ($tableName -eq 'Dim_User') {
                $sourceText = Replace-TextRange `
                    -Text $sourceText `
                    -StartMarker '// Dynamically detect Cowork-eligible users from the connected Purview export.' `
                    -EndMarker "`n`tFiles0 = SharePointDataFiles," `
                    -Replacement $dimUserSeedBlock
                $sourceText = Replace-Literal `
                    $sourceText `
                    'RealNormalized0 = Table.AddColumn(RealRenamed, "_upnNorm", each Text.Lower(Text.Trim([UserPrincipalName])), type text)' `
                    'RealNormalized0 = Table.AddColumn(RealRenamed, "_upnNorm", each if [UserPrincipalName] = null then null else Text.Lower(Text.Trim(Text.From([UserPrincipalName]))), type nullable text)'
                $sourceText = Replace-Literal `
                    $sourceText `
                    'ExpandIdentity = Table.ExpandTableColumn(MergeIdentity, "identity", {"UserID", "DisplayName", "UserPrincipalName"}, {"UserID", "DisplayName", "UserPrincipalName"}),' `
                    @'
ExpandIdentity = Table.ExpandTableColumn(MergeIdentity, "identity", {"UserID", "DisplayName", "UserPrincipalName"}, {"UserID", "DisplayName", "UserPrincipalName"}),
					MergeUsage = Table.NestedJoin(ExpandIdentity, {"_upnNorm"}, UsageLookup, {"_upnNorm"}, "usage", JoinKind.LeftOuter),
					ExpandUsage = Table.ExpandTableColumn(MergeUsage, "usage", {"_usageDisplayName"}, {"_usageDisplayName"}),
'@
                $sourceText = Replace-TextRange `
                    -Text $sourceText `
                    -StartMarker 'AddIdentityQuality = Table.AddColumn(ExpandIdentity, "IdentityDataQuality", each' `
                    -EndMarker 'FillUpn = Table.AddColumn' `
                    -Replacement @'
AddIdentityQuality = Table.AddColumn(ExpandUsage, "IdentityDataQuality", each
						if [UserPrincipalName] <> null then "Real (confirmed via Entra export)"
						else if List.Contains(PurviewUpns, [_upnNorm]) then "Real Cowork activity (Purview); no matching Entra identity record found"
						else "Real Cowork usage export; no recognized Purview event or matching Entra identity record found", type text),

'@
                $sourceText = Replace-Literal `
                    $sourceText `
                    'FillDisplay = Table.AddColumn(FillUpn, "DisplayNameFinal", each if [DisplayName] = null then [_upnNorm] else [DisplayName], type text),' `
                    'FillDisplay = Table.AddColumn(FillUpn, "DisplayNameFinal", each if [DisplayName] <> null then [DisplayName] else if [_usageDisplayName] <> null and Text.Trim(Text.From([_usageDisplayName])) <> "" then Text.Trim(Text.From([_usageDisplayName])) else [_upnNorm], type text),'
            }
            elseif ($tableName -eq 'Fact_CoworkUsage') {
                $sourceText = Replace-TextRange `
                    -Text $sourceText `
                    -StartMarker 'Typed = Table.TransformColumnTypes(Checked' `
                    -EndMarker 'otherwise' `
                    -Replacement ($coworkUsageTypedBlock + "`n`t`t")
            }
            elseif ($tableName -eq 'Fact_Consumption') {
                $sourceText = Replace-Literal `
                    $sourceText `
                    'RealTyped = Table.TransformColumnTypes(TryLoad, {{"Monthly credit limit", Int64.Type}, {"Monthly credits used", Int64.Type}, {"Session Count", Int64.Type}}),' `
                    @'
RealTyped = Table.TransformColumnTypes(TryLoad, {{"Monthly credit limit", Int64.Type}, {"Monthly credits used", Int64.Type}, {"Session Count", Int64.Type}}),
										RealNormalized = Table.TransformColumns(RealTyped, {{"User Principal Name", each if _ = null then null else Text.Lower(Text.Trim(Text.From(_))), type nullable text}}),
'@
                $sourceText = Replace-Literal $sourceText 'MergeReal = Table.NestedJoin(RealUsers, {"UserPrincipalName"}, RealTyped, {"User Principal Name"}, "cred", JoinKind.LeftOuter),' 'MergeReal = Table.NestedJoin(RealUsers, {"UserPrincipalName"}, RealNormalized, {"User Principal Name"}, "cred", JoinKind.LeftOuter),'
            }
            elseif ($tableName -eq 'Dim_UserOrg') {
                $sourceText = Replace-Literal `
                    $sourceText `
                    'Deduped = Table.Distinct(Checked, {"userPrincipalName"})' `
                    @'
NormalizedUpn = Table.TransformColumns(Checked, {{"userPrincipalName", each if _ = null then null else Text.Lower(Text.Trim(Text.From(_))), type nullable text}}),
								Deduped = Table.Distinct(NormalizedUpn, {"userPrincipalName"})
'@
            }
            $partition.source.expression = ConvertTo-MLines $sourceText

            $query = $unapplied.queries | Where-Object { $_.name -eq $tableName } | Select-Object -First 1
            if ($null -eq $query) {
                throw "Unapplied query not found: $tableName"
            }
            Set-UnappliedFormula $query $sourceText
        }

        $coworkDetailTable = $model.model.tables | Where-Object { $_.name -eq 'Fact_CoworkDetail' } | Select-Object -First 1
        if ($null -eq $coworkDetailTable) {
            throw 'Calculated table not found: Fact_CoworkDetail'
        }
        $coworkDetailPartition = $coworkDetailTable.partitions | Select-Object -First 1
        $coworkDetailText = ConvertTo-MText $coworkDetailPartition.source.expression
        $coworkDetailText = Replace-Literal `
            $coworkDetailText `
            "'Fact_CopilotAuditRaw'[AppHost] = `"cowork`"" `
            "CONTAINSSTRING(LOWER(TRIM(COALESCE('Fact_CopilotAuditRaw'[AppHost], `"`"))), `"cowork`")"
        $coworkDetailPartition.source.expression = ConvertTo-MLines $coworkDetailText

        $auditTable = $model.model.tables | Where-Object { $_.name -eq 'Fact_CopilotAuditRaw' } | Select-Object -First 1
        if ($null -ne $auditTable -and $auditTable.PSObject.Properties.Name -contains 'description') {
            $auditTable.description = @(
                'Additive fact table with one row per Purview CopilotInteraction audit record.',
                'Raw Purview export CSVs are discovered recursively below SharePointFolderUrl.'
            )
        }
        $coworkFilterHealthMeasure = $auditTable.measures | Where-Object { $_.name -eq 'Cowork Filter Health' } | Select-Object -First 1
        if ($null -eq $coworkFilterHealthMeasure) {
            throw 'Measure not found: Fact_CopilotAuditRaw[Cowork Filter Health]'
        }
        $coworkFilterHealthMeasure.expression = ConvertTo-MLines $coworkFilterHealth

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
            'PurviewAuditParsed',
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
            (New-UnappliedQuery -Name 'PurviewAuditParsed' -LineageTag '0dce9a7d-d592-4c4b-b38a-67bf6151d67e' -Expression $purviewAuditParsed -ResultType 'Table' -Description 'Shared dual-format Purview parser used before user-key resolution.')
            $auditUnapplied
        )
        $keptUnappliedQueries = @($unapplied.queries | Where-Object { $_.name -notin $removedExpressionNames })
        $unapplied.queries = @($newUnappliedQueries + $keptUnappliedQueries)

        $measuresTable = $model.model.tables | Where-Object { $_.name -eq '_Measures' } | Select-Object -First 1
        if ($null -eq $measuresTable) {
            throw 'Measures table not found.'
        }
        $usageGateMeasure = $measuresTable.measures | Where-Object { $_.name -eq 'Page Gate - Usage' } | Select-Object -First 1
        if ($null -eq $usageGateMeasure) {
            throw 'Page Gate - Usage measure not found.'
        }
        $usageGateMeasure.expression = ConvertTo-MLines $pageGateUsage
        $readinessMeasure = [pscustomobject][ordered]@{
            name = 'Template Data Readiness'
            description = 'Plain-language source and matching status shown on Start Here after refresh.'
            expression = ConvertTo-MLines $templateDataReadiness
            lineageTag = '6e075337-4b0f-47cf-8867-f33479ebbb27'
        }
        $measuresTable.measures = @(
            @($measuresTable.measures | Where-Object { $_.name -ne 'Template Data Readiness' })
            $readinessMeasure
        )

        $modelJson = ($model | ConvertTo-Json -Depth 100).Replace('DataFolderPath', 'SharePointFolderUrl')
        $unappliedJson = ($unapplied | ConvertTo-Json -Depth 100 -Compress).Replace('DataFolderPath', 'SharePointFolderUrl')
        Write-ZipText $archive 'DataModelSchema' $modelJson $utf16
        Write-ZipText $archive 'UnappliedChanges' $unappliedJson $utf16

        $startHereTitleEntry = 'Report/definition/pages/00_start_here/visuals/sh_card4_title/visual.json'
        $startHereTitle = Read-ZipText $archive $startHereTitleEntry $utf8
        $startHereTitle = Replace-Literal $startHereTitle 'How do I connect customer data?' 'Data readiness and next action'
        Write-ZipText $archive $startHereTitleEntry $startHereTitle $utf8

        $startHereEntry = 'Report/definition/pages/00_start_here/visuals/sh_card4_desc/visual.json'
        $startHereCurrent = (Read-ZipText $archive $startHereEntry $utf8) | ConvertFrom-Json -Depth 100
        $readinessCard = (Read-ZipText $archive 'Report/definition/pages/97_value_tiers/visuals/vt_subtitle/visual.json' $utf8) | ConvertFrom-Json -Depth 100
        $readinessCard.name = 'sh_card4_desc'
        $readinessCard.position = Copy-JsonObject $startHereCurrent.position
        $readinessCard.visual.query.queryState.Values.projections[0].field.Measure.Expression.SourceRef.Entity = '_Measures'
        $readinessCard.visual.query.queryState.Values.projections[0].field.Measure.Property = 'Template Data Readiness'
        $readinessCard.visual.query.queryState.Values.projections[0].queryRef = '_Measures.Template Data Readiness'
        $readinessCard.visual.query.queryState.Values.projections[0].nativeQueryRef = 'Template Data Readiness'
        $readinessCard.visual.objects.labels[0].properties.color.solid.color.expr.Literal.Value = "'#003087'"
        $readinessCard.visual.objects.labels[0].properties.fontSize.expr.Literal.Value = '9D'
        $readinessCard.visual.visualContainerObjects.background[0].properties.color.solid.color.expr.Literal.Value = "'#F3F7FC'"
        $readinessCard.visual.visualContainerObjects.border[0].properties.color.solid.color.expr.Literal.Value = "'#B4C6E7'"
        $readinessCard.visual.visualContainerObjects.general[0].properties.altText.expr.Literal.Value = "'Data readiness and next action based on recognized Purview, Cowork usage, and consumption inputs.'"
        Write-ZipText $archive $startHereEntry ($readinessCard | ConvertTo-Json -Depth 100) $utf8

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
