Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name powershell-yaml | Select-Object -First 1)) {
    Install-Module powershell-yaml -Scope CurrentUser -Force -ErrorAction Stop
}

Import-Module powershell-yaml -ErrorAction Stop

$repoRoot               = Split-Path $PSScriptRoot -Parent
$manifestsRoot          = Join-Path $repoRoot 'argocd'
$appSetsRenderedRoot    = Join-Path $manifestsRoot 'appsets'
$workloadsRenderedRoot  = Join-Path $manifestsRoot 'workloads'
$valuesPath             = Join-Path $manifestsRoot 'config.yaml'
$templateRoot           = Join-Path $manifestsRoot 'templates'
$appsetTemplatePath     = Join-Path $templateRoot 'appset.tpl.yaml'
$renderValues           = Get-Content -LiteralPath $valuesPath -Raw | ConvertFrom-Yaml
$appsetTemplate         = Get-Content -LiteralPath $appsetTemplatePath -Raw

function Has-Property([object] $object, [string] $name) {
    return (([PSCustomObject]$object).PSObject.Properties.Name -contains $name)
}

function Get-PropertyValue([object] $object, [string] $name, [object] $defaultValue = $null) {
    if (Has-Property -Object $object -Name $name) {
        return $object.$name
    }

    return $defaultValue
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

function Get-ManifestGeneratePaths([string]$workloadPath, [object]$applicationSet, [object[]]$valueFiles) {
    $manifestPaths = New-Object System.Collections.Generic.List[string]

    foreach ($application in @($applicationSet.applications)) {
        $chartPath = Get-PropertyValue -object $application -name 'chart' -defaultValue 'charts/nixon-deployable'

        $manifestPaths.Add((To-RepoAbsolutePath $chartPath))
        Add-LocalChartDependencyPaths -chartPath $chartPath -manifestPaths $manifestPaths
    }

    $manifestPaths.Add((To-RepoAbsolutePath $workloadPath))

    foreach ($valueFile in $valueFiles) {
        $manifestPaths.Add((To-RepoAbsolutePath $valueFile))
    }

    return ($manifestPaths | Select-Object -Unique) -join ';'
}

function Get-Applications([string]$applicationSetName, [object]$applicationSet) {
    $applications = @()
    $environments = @(Get-PropertyValue -object $applicationSet -name 'environments' -defaultValue @())

    foreach ($application in @($applicationSet.applications)) {
        $namespaceOverride = Get-PropertyValue -object $application -name 'namespace'
        $chart = Get-PropertyValue -object $application -name 'chart' -defaultValue 'charts/nixon-deployable'

        if ($environments.Count -eq 0) {
            $applications += [PSCustomObject]@{
                name        = $application.name
                chart       = $chart
                namespace   = if ($null -ne $namespaceOverride) { $namespaceOverride } else { $applicationSetName }
            }
        }
        else {
            foreach ($environment in $environments) {
                $applications += [PSCustomObject]@{
                    name        = $application.name
                    chart       = $chart
                    environment = $environment
                    namespace   = if ($null -ne $namespaceOverride) { $namespaceOverride } else { "$applicationSetName-$environment" }
                }
            }
        }
    }

    return $applications
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

if (Test-Path -LiteralPath $workloadsRenderedRoot) {
    Remove-Item -LiteralPath $workloadsRenderedRoot -Recurse -Force
}

foreach ($directory in @($appSetsRenderedRoot, $workloadsRenderedRoot)) {
    [System.IO.Directory]::CreateDirectory($directory) | Out-Null
}

foreach ($applicationSetName in $renderValues.applicationSets.Keys) {
    $applicationSet = $renderValues.applicationSets[$applicationSetName]
    $applications = @(Get-Applications -applicationSetName $applicationSetName -applicationSet $applicationSet)
    $valueFiles = @(Get-PropertyValue -object $applicationSet -name 'valueFiles' -defaultValue @())
    $workload = [PSCustomObject]@{
        applications = $applications
    }
    $workloadPath = "argocd/workloads/$applicationSetName-workload.yaml"
    $workloadOutputPath = Join-Path $workloadsRenderedRoot "$applicationSetName-workload.yaml"

    [System.IO.File]::WriteAllText($workloadOutputPath, ($workload | ConvertTo-Yaml), [System.Text.UTF8Encoding]::new($false))

    Write-Host "Wrote $workloadOutputPath"

    $item = [ordered]@{
        APPSET_NAME            = "$applicationSetName-appset"
        ARGO_FILE_PATH          = $workloadPath
        MANIFEST_GENERATE_PATHS = Get-ManifestGeneratePaths -workloadPath $workloadPath -applicationSet $applicationSet -valueFiles $valueFiles
        NAME_TEMPLATE           = $applicationSet.applicationNameTemplate
        VALUE_FILES             = $valueFiles
    }
    $rendered = Render-Template -template $appsetTemplate -item $item
    $outputPath = Join-Path $appSetsRenderedRoot "$applicationSetName-appset.yaml"

    [System.IO.File]::WriteAllText($outputPath, $rendered, [System.Text.UTF8Encoding]::new($false))

    Write-Host "Wrote $outputPath"
}
