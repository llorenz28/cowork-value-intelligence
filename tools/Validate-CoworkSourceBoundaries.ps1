[CmdletBinding()]
param(
    [string]$SemanticModelPath
)

$ErrorActionPreference = 'Stop'

if (-not $SemanticModelPath) {
    $repositoryRoot = Split-Path -Parent $PSScriptRoot
    $SemanticModelPath = Join-Path $repositoryRoot 'src\Cowork Value Intelligence.SemanticModel'
}

function Get-RequiredContent {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required model file not found: $Path"
    }

    return Get-Content -LiteralPath $Path -Raw
}

function Assert-Contains {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Text -notmatch $Pattern) {
        throw $FailureMessage
    }
}

function Remove-TmdlComments {
    param([string]$Text)

    $withoutBlockComments = [regex]::Replace($Text, '(?s)/\*.*?\*/', '')
    return [regex]::Replace($withoutBlockComments, '(?m)^\s*//.*$', '')
}

$definitionPath = Join-Path $SemanticModelPath 'definition'
$tablesPath = Join-Path $definitionPath 'tables'

$expressions = Get-RequiredContent (Join-Path $definitionPath 'expressions.tmdl')
$usage = Get-RequiredContent (Join-Path $tablesPath 'Fact_CoworkUsage.tmdl')
$detailTables = @{
    Fact_CoworkDetail = Get-RequiredContent (Join-Path $tablesPath 'Fact_CoworkDetail.tmdl')
    Fact_CoworkThread = Get-RequiredContent (Join-Path $tablesPath 'Fact_CoworkThread.tmdl')
    Fact_Tasks = Get-RequiredContent (Join-Path $tablesPath 'Fact_Tasks.tmdl')
    Bridge_CoworkPlugin = Get-RequiredContent (Join-Path $tablesPath 'Bridge_CoworkPlugin.tmdl')
    Bridge_CoworkResource = Get-RequiredContent (Join-Path $tablesPath 'Bridge_CoworkResource.tmdl')
}

$expectedUsageColumns = @(
    'ActiveDays'
    'DataQuality'
    'DisplayName'
    'LastActivityDate'
    'ScheduledTasks'
    'TotalTasks'
    'UserInitiatedTasks'
    'UserKey'
    'UserPrincipalName'
)

$actualUsageColumns = [regex]::Matches(
    $usage,
    '(?m)^\s*column\s+(?<name>''[^'']+''|[^=\r\n]+?)(?:\s*=.*)?\s*$'
) | ForEach-Object {
    $_.Groups['name'].Value.Trim().Trim("'")
} | Sort-Object

$columnDifference = Compare-Object $expectedUsageColumns $actualUsageColumns
if ($columnDifference) {
    $differenceText = ($columnDifference | ForEach-Object {
        "$($_.SideIndicator) $($_.InputObject)"
    }) -join '; '
    throw "Fact_CoworkUsage must remain a user-level aggregate snapshot. Column contract changed: $differenceText"
}

Assert-Contains $expressions 'expression\s+CoworkUsageCsvPath\s*=' `
    'CoworkUsageCsvPath is missing from expressions.tmdl.'
Assert-Contains $expressions 'Operation\]\s*=\s*"CopilotInteraction"' `
    'The Purview parser no longer filters to CopilotInteraction records.'
Assert-Contains $expressions 'AddAppHost\s*=\s*Table\.AddColumn' `
    'The Purview parser no longer extracts CopilotEventData.AppHost.'
Assert-Contains $expressions 'AddPluginList\s*=\s*Table\.AddColumn' `
    'The Purview parser no longer extracts the full plugin list used for activity classification.'

foreach ($tableName in $detailTables.Keys) {
    if ((Remove-TmdlComments $detailTables[$tableName]) -match 'Fact_CoworkUsage') {
        throw "$tableName references Fact_CoworkUsage. Detailed activity must come from Purview, not the aggregate usage export."
    }
}

Assert-Contains $detailTables.Fact_CoworkDetail `
    'FILTER\(''Fact_CopilotAuditRaw'',\s*''Fact_CopilotAuditRaw''\[AppHost\]\s*=\s*"cowork"\)' `
    'Fact_CoworkDetail is no longer isolated from Purview rows with AppHost = "cowork".'
Assert-Contains $detailTables.Fact_CoworkThread 'Fact_CopilotAuditRaw_WithLists' `
    'Fact_CoworkThread is no longer sourced from the shared Purview parser.'
Assert-Contains $detailTables.Fact_Tasks 'Fact_CopilotAuditRaw' `
    'Fact_Tasks is no longer sourced from parsed Purview activity.'
Assert-Contains $detailTables.Bridge_CoworkPlugin 'Table\.ExpandListColumn\(HasAny,\s*"_plugins"\)' `
    'Bridge_CoworkPlugin no longer expands every Purview plugin invocation.'
Assert-Contains $detailTables.Bridge_CoworkResource 'Table\.ExpandListColumn\(HasAny,\s*"_resources"\)' `
    'Bridge_CoworkResource no longer expands every Purview resource event.'

Write-Host 'PASS: Cowork usage export is limited to user-level aggregate fields.'
Write-Host 'PASS: Detailed Cowork activity, threads, skills, categories, and resources are sourced from Purview.'
