$versionFile = "$PSScriptRoot\..\version.txt"
$content = (Get-Content $versionFile -Raw).Trim()

if ($content -match '^(\d+)\.(\d+)\.(\d+)$') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]

    Write-Host "Current version: $major.$minor.$patch"

    $newPatch = $patch + 1
    $newVersion = "$major.$minor.$newPatch"

    Write-Host "New version: $newVersion"

    Set-Content $versionFile $newVersion -NoNewline

    Write-Host "Version incremented successfully to $newVersion"
} else {
    Write-Host "Could not parse version from version.txt (expected format: X.Y.Z)"
    exit 1
}
