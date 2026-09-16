[CmdletBinding()]
param(
    [string]$PresentationPath,
    [Parameter(Mandatory = $true)]
    [string]$PdfPath
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
if (-not $PresentationPath) {
    $PresentationPath = Join-Path $repositoryRoot 'Cowork Value Intelligence V1.0 In Testing - Interpretation Storyboard.pptx'
}
$resolvedRepositoryRoot = [System.IO.Path]::GetFullPath(
    $repositoryRoot + [System.IO.Path]::DirectorySeparatorChar
)
$resolvedPdfPath = [System.IO.Path]::GetFullPath($PdfPath)
if ($resolvedPdfPath.StartsWith(
    $resolvedRepositoryRoot,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw 'PDF output must be outside the repository so label metadata can be reviewed before distribution.'
}

$powerPoint = $null
$presentation = $null
$temporaryPresentation = Join-Path (
    [System.IO.Path]::GetTempPath()
) ("cowork-storyboard-{0}.pptx" -f [guid]::NewGuid().ToString('N'))

try {
    Copy-Item -LiteralPath $PresentationPath -Destination $temporaryPresentation
    $powerPoint = New-Object -ComObject PowerPoint.Application
    $presentation = $powerPoint.Presentations.Open(
        $temporaryPresentation,
        $true,
        $true,
        $false
    )
    $presentation.SaveAs($resolvedPdfPath, 32)
    $presentation.Close()
    $presentation = $null
}
finally {
    if ($presentation) {
        $presentation.Close()
    }
    if ($powerPoint) {
        $powerPoint.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($powerPoint) | Out-Null
    }
    Remove-Item -LiteralPath $temporaryPresentation -Force -ErrorAction SilentlyContinue
}

Get-Item -LiteralPath $resolvedPdfPath
