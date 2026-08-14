Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name powershell-yaml | Select-Object -First 1)) {
    Install-Module powershell-yaml -Scope CurrentUser -Force -ErrorAction Stop
}

Import-Module powershell-yaml -ErrorAction Stop

$repoRoot               = Split-Path $PSScriptRoot -Parent
$manifestsRoot          = Join-Path $repoRoot 'argocd'
$appSetsRenderedRoot    = Join-Path $manifestsRoot 'appsets'
$valuesPath             = Join-Path $manifestsRoot 'config.yaml'
$templateRoot           = Join-Path $manifestsRoot 'templates'
$appsetTemplatePath     = Join-Path $templateRoot 'appset.tpl.yaml'
$renderValues           = Get-Content -LiteralPath $valuesPath -Raw | ConvertFrom-Yaml
$appsetTemplate         = Get-Content -LiteralPath $appsetTemplatePath -Raw

function To-Crlf ($text) {
    return ($text -replace "`r?`n", "`r`n")
}

function Has-Property([object] $object, [string] $name) {
    return (([PSCustomObject]$object).PSObject.Properties.Name -contains $name)
}

function Render-ArrayValue([object[]]$arrayValue) {
    $files = @($arrayValue)

    if ($files.Count -eq 0) {
        return '[]'
    }

    $quoted = $files | ForEach-Object { '"' + $_ + '"' }

    return '[' + ($quoted -join ', ') + ']'
}

function Normalize-RepoPath([string]$path) {
    return $path.TrimStart('/')
}

function To-RepoAbsolutePath([string]$path) {
    return '/' + (Normalize-RepoPath $path)
}

function Get-RepoRelativePath([string]$path) {
    $resolvedPath = [System.IO.Path]::GetFullPath($path)
    $repoRootPath = [System.IO.Path]::GetFullPath($repoRoot)
    $relativePath = [System.IO.Path]::GetRelativePath($repoRootPath, $resolvedPath)

    return ($relativePath -replace '\\', '/')
}

function Add-LocalChartDependencyPaths([string]$chartPath, [System.Collections.Generic.List[string]]$manifestPaths) {
    $resolvedChartPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot (Normalize-RepoPath $chartPath)))

    if (-not (Test-Path -LiteralPath $resolvedChartPath)) {
        return
    }

    $chartFilePath = Join-Path $resolvedChartPath 'Chart.yaml'

    if (-not (Test-Path -LiteralPath $chartFilePath)) {
        return
    }

    $chart = Get-Content -LiteralPath $chartFilePath -Raw | ConvertFrom-Yaml

    if (-not (Has-Property -Object $chart -Name 'dependencies')) {
        return
    }

    foreach ($dependency in @($chart.dependencies)) {
        if ($null -eq $dependency.repository) {
            continue
        }

        $repository = [string]$dependency.repository

        if (-not $repository.StartsWith('file://')) {
            continue
        }

        $dependencyPath         = $repository.Substring(7)
        $resolvedDependencyPath = [System.IO.Path]::GetFullPath((Join-Path $resolvedChartPath $dependencyPath))
        $relativeDependencyPath = Get-RepoRelativePath -path $resolvedDependencyPath

        $manifestPaths.Add((To-RepoAbsolutePath $relativeDependencyPath))

        Add-LocalChartDependencyPaths -chartPath $relativeDependencyPath -manifestPaths $manifestPaths
    }
}

function Get-ManifestGeneratePaths([hashtable]$item) {
    $manifestPaths = New-Object System.Collections.Generic.List[string]

    $appsetFiles = @(Resolve-Path -Path (Join-Path $repoRoot (Normalize-RepoPath $item.ARGO_FILE_PATH)) -ErrorAction Stop)

    foreach ($appsetFile in $appsetFiles) {
        $appset = Get-Content -LiteralPath $appsetFile.Path -Raw | ConvertFrom-Yaml

        if ($null -ne $appset.components) {
            foreach ($component in @($appset.components)) {
                if ($component.chart) {
                    $manifestPaths.Add((To-RepoAbsolutePath $component.chart))
                    Add-LocalChartDependencyPaths -chartPath $component.chart -manifestPaths $manifestPaths
                }
            }
        }
    }

    $manifestPaths.Add((To-RepoAbsolutePath $item.ARGO_FILE_PATH))

    foreach ($valueFile in @($item.VALUE_FILES)) {
        $manifestPaths.Add((To-RepoAbsolutePath $valueFile))
    }

    return ($manifestPaths | Select-Object -Unique) -join ';'
}

function Render-Template([string]$template, [object]$item) {
    $rendered = $template

    foreach ($key in $item.Keys) {
        $placeholder = '$(' + $key + ')'
        $value = $item[$key]

        if (($value -is [System.Collections.IEnumerable]) -and ($value -isnot [string])) {
            $value = Render-ArrayValue @($value)
        }

        $rendered = $rendered.Replace($placeholder, [string]$value)
    }

    return $rendered
}

foreach ($directory in @($appSetsRenderedRoot)) {
    if (-not (Test-Path -LiteralPath $directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }
}

foreach ($item in @($renderValues.appSetValues)) {
    $item.MANIFEST_GENERATE_PATHS = Get-ManifestGeneratePaths -item $item
    
    $rendered   = Render-Template -template $appsetTemplate -item $item
    $outputPath = Join-Path $appSetsRenderedRoot "$($item.APPSET_NAME).yaml"

    [System.IO.File]::WriteAllText($outputPath, (To-Crlf -text $rendered), [System.Text.UTF8Encoding]::new($false))

    Write-Host "Wrote $outputPath"
}
