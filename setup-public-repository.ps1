$ErrorActionPreference = "Stop"

$workspaceRoot      = $PSScriptRoot
$destinationPath    = Join-Path -Path $workspaceRoot -ChildPath "nixon-gitops"

function Get-GitRepository {
    $tempGuid      = [System.Guid]::NewGuid().ToString()
    $tempDir       = Join-Path -Path $workspaceRoot -ChildPath $tempGuid

    New-Item -ItemType Directory -Path $tempDir | Out-Null

    git clone "https://github.com/nixonjoshua98/nixon-gitops.git" $tempDir

    if (Test-Path -Path $destinationPath) {
        Remove-Item -Path $destinationPath -Recurse -Force
    }

    Copy-Item -Path $tempDir -Destination $destinationPath -Recurse -Force

    Remove-Item -Path $tempDir -Recurse -Force
}

function Remove-ImageRegistry {
    $registryPattern = '(?<![A-Za-z0-9-])[A-Za-z0-9-]+\.azurecr\.io(?![A-Za-z0-9.-])'

    Get-ChildItem -Path $destinationPath -File -Recurse -Force |
        Where-Object { 
            $_.FullName -notlike "$destinationPath\.git\*" 
        } |
        ForEach-Object {
            $content            = [System.IO.File]::ReadAllText($_.FullName)
            $anonymizedContent  = $content -replace $registryPattern, 'containerregistry.azurecr.io'

            if ($anonymizedContent -cne $content) {
                [System.IO.File]::WriteAllText($_.FullName, $anonymizedContent)
            }
        }
}

Get-GitRepository

Remove-ImageRegistry