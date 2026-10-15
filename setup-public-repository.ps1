$ErrorActionPreference = "Stop"

$workspaceRoot      = $PSScriptRoot
$tempGuid           = [System.Guid]::NewGuid().ToString()
$tempDir            = Join-Path -Path $workspaceRoot -ChildPath $tempGuid
$destinationPath    = Join-Path -Path $workspaceRoot -ChildPath "nixon-gitops"

function Get-GitRepository {
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    git clone "https://github.com/joshua-nixon/nixon-gitops.git" $tempDir
}

function Update-RegexString([string]$regex, [string]$replacement) {
    $registryPattern = $regex

    Get-ChildItem -Path $tempDir -File -Recurse -Force |
        ForEach-Object {
            $content            = [System.IO.File]::ReadAllText($_.FullName)
            $anonymizedContent  = $content -replace $registryPattern, $replacement

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

Update-RegexString `
    -regex '(?<![A-Za-z0-9-])[A-Za-z0-9-]+\.azurecr\.io(?![A-Za-z0-9.-])' `
    -replacement 'containerregistry.azurecr.io'

Update-RegexString `
    -regex '(?<![A-Za-z0-9-])[A-Za-z0-9-]+\.vault\.azure\.net(?![A-Za-z0-9.-])' `
    -replacement 'keyvault.azure.net'

Update-RegexString `
    -regex '(?<![A-Za-z0-9-])[A-Za-z0-9-]+\.blob\.core\.windows\.net(?![A-Za-z0-9.-])' `
    -replacement 'storageaccount.blob.core.windows.net'

Clear-DestinationRepository

Get-ChildItem -LiteralPath $tempDir -Force |
    Copy-Item -Destination $destinationPath -Recurse -Force

Remove-Item -Path $tempDir -Recurse -Force