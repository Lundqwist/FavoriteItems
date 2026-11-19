# Builds the CurseForge upload folder:
#   curseforge\FavoriteItems-<version>.zip   the file to upload (contains FavoriteItems\...)
#   curseforge\description.md                paste into the project description (Markdown editor)
#   curseforge\changelog.md                  paste into the upload's Changelog box (Markdown): this version's CHANGELOG.md section
#   curseforge\avatar.png                    400x400 project avatar (the heart, from make-avatar.ps1)
#   curseforge\screenshots\                  in-game screenshots for the project's Images tab
# Usage (from the repo root): .\tools\package.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out  = Join-Path $root "curseforge"
$name = "FavoriteItems"

# version from the .toc
$toc = Get-Content (Join-Path $root "$name.toc")
$version = ($toc | Where-Object { $_ -match '^## Version:\s*(.+)$' } | ForEach-Object { $Matches[1].Trim() } | Select-Object -First 1)
if (-not $version) { throw "No '## Version:' line in $name.toc" }

# files that go into the addon folder in the zip
$files = @(
    "$name.toc",
    "LunarLink.lua",
    "$name.lua",
    "LICENSE",
    "README.md",
    "CHANGELOG.md",
    "Media\Heart.tga"
)
foreach ($f in $files) {
    if (-not (Test-Path (Join-Path $root $f))) { throw "Missing $f" }
}

New-Item -ItemType Directory -Force $out | Out-Null
Get-ChildItem $out -Filter "$name-*.zip" | Remove-Item -Force

# Build the zip by hand so entry names use forward slashes (Compress-Archive on
# Windows PowerShell writes backslashes, which other unzip tools mis-read).
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = Join-Path $out "$name-$version.zip"
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($f in $files) {
        $entry = "$name/" + ($f -replace '\\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $root $f), $entry, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally {
    $zip.Dispose()
}

Copy-Item (Join-Path $root "CURSEFORGE.md") (Join-Path $out "description.md") -Force

# This version's section of CHANGELOG.md, for the file upload's Changelog box
$changes = Get-Content (Join-Path $root "CHANGELOG.md") -Encoding UTF8
$start = -1; $end = $changes.Count
for ($i = 0; $i -lt $changes.Count; $i++) {
    if ($changes[$i] -match '^## (\S+)') {
        if ($start -ge 0) { $end = $i; break }
        if ($Matches[1] -eq $version) { $start = $i }
    }
}
if ($start -lt 0) { throw "No '## $version' section in CHANGELOG.md" }
$section = $changes[$start..($end - 1)] -join "`n"
$section = $section.Trim() + "`n`nFull history: https://github.com/Lundqwist/FavoriteItems/blob/main/CHANGELOG.md`n"
[System.IO.File]::WriteAllText((Join-Path $out "changelog.md"), $section, (New-Object System.Text.UTF8Encoding $false))
& (Join-Path $PSScriptRoot "make-avatar.ps1") -Size 400 -Png (Join-Path $out "avatar.png") | Out-Null

$shots = Get-ChildItem (Join-Path $root "screenshots") -Filter *.png -ErrorAction SilentlyContinue
if ($shots) {
    $shotDir = Join-Path $out "screenshots"
    New-Item -ItemType Directory -Force $shotDir | Out-Null
    $shots | Copy-Item -Destination $shotDir -Force
}

"Built $zipPath"
Get-ChildItem $out -Recurse -File | ForEach-Object { "  " + $_.FullName.Substring($out.Length + 1) + "  (" + $_.Length + " bytes)" }
