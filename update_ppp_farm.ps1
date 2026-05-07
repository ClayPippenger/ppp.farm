#
# This is for updating ppp.farm Git
#
# Go to the X:\Codex\ppp.farm using Powershell
#

# 1️⃣ Temporarily allow scripts for this session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 4️⃣ Navigate to the photos folder
Set-Location "X:\Codex\ppp.farm\photos"

# 4.5⃣ De-duplicate
Write-Host "Running Photo Deduplicater..."
if (Test-Path "..\Remove-DuplicatImages.ps1") {
    ..\Remove-DuplicatImages.ps1
} else {
    Write-Warning "Remove-DuplicatImages.ps1 not found in X:\Codex\ppp.farm\"
}

# 5️⃣ Run the photo EXIF script (assumes it exists as script.ps1 in the same folder)
Write-Host "Running EXIF photo sorter..."
if (Test-Path ".\script.ps1") {
    .\script.ps1
} else {
    Write-Warning "script.ps1 not found in X:\Codex\ppp.farm\photos"
}

# 6️⃣ Done
Write-Host "`n✅ Update complete. photos.json should now be ready in X:\Codex\ppp.farm\"
Write-Host "`n✅ Will push everything to Git now..."

Pause

Set-Location "X:\Codex\ppp.farm\"

git add .
git commit -m "Updates to stuff"
git push origin main

Set-Location "X:\Codex\ppp.farm\"
	
Read-Host "Press Enter to exit"
Pause
