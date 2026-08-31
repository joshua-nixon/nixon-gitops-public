$ErrorActionPreference = "Stop"

$workspaceRoot = $PSScriptRoot
$tempGuid      = [System.Guid]::NewGuid().ToString()
$tempDir       = Join-Path -Path $workspaceRoot -ChildPath $tempGuid

New-Item -ItemType Directory -Path $tempDir | Out-Null

git clone "https://github.com/nixonjoshua98/nixon-gitops.git" $tempDir

$destinationPath = Join-Path -Path $workspaceRoot -ChildPath "nixon-gitops"

if (Test-Path -Path $destinationPath) {
    Remove-Item -Path $destinationPath -Recurse -Force
}

Copy-Item -Path $tempDir -Destination $destinationPath -Recurse -Force

Remove-Item -Path $tempDir -Recurse -Force