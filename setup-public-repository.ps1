$ErrorActionPreference = "Stop"

$workspaceRoot      = $PSScriptRoot
$tempGuid           = [System.Guid]::NewGuid().ToString()
$tempDir            = Join-Path -Path $workspaceRoot -ChildPath $tempGuid
$destinationPath    = Join-Path -Path $workspaceRoot -ChildPath "nixon-gitops"

function Get-GitRepository {
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    git clone "https://github.com/joshua-nixon/nixon-gitops.git" $tempDir
}

function Remove-ImageRegistry {
    $registryPattern = '(?<![A-Za-z0-9-])[A-Za-z0-9-]+\.azurecr\.io(?![A-Za-z0-9.-])'

    Get-ChildItem -Path $tempDir -File -Recurse -Force |
        ForEach-Object {
            $content            = [System.IO.File]::ReadAllText($_.FullName)
            $anonymizedContent  = $content -replace $registryPattern, 'containerregistry.azurecr.io'

            if ($anonymizedContent -cne $content) {
                [System.IO.File]::WriteAllText($_.FullName, $anonymizedContent)
            }
        }
}

function Clear-DestinationRepository {
    Get-ChildItem -LiteralPath $destinationPath -Force |
        Remove-Item -Recurse -Force
}

Get-GitRepository

Remove-ImageRegistry

Clear-DestinationRepository

Get-ChildItem -LiteralPath $tempDir -Force |
    Copy-Item -Destination $destinationPath -Recurse -Force

Remove-Item -Path $tempDir -Recurse -Force