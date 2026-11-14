# Copies the addon into the WoW: Forever AddOns folder.
$ErrorActionPreference = "Stop"
$target = "D:\Blizzard\World of Warcraft\_forever_\Interface\AddOns\FavoriteItems"
New-Item -ItemType Directory -Force "$target\Media" | Out-Null
Copy-Item "$PSScriptRoot\FavoriteItems.toc", "$PSScriptRoot\FavoriteItems.lua" $target -Force
Copy-Item "$PSScriptRoot\Media\Heart.tga" "$target\Media" -Force
Write-Host "Installed to $target. Run /reload in game (or restart) to load the changes."
