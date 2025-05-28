#
# This is for updating ppp.farm Git
#
# Go to the R:\Shared\ppp.farm using Powershell
#

# 1️⃣ Temporarily allow scripts for this session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 2️⃣ Remove Y: drive mapping if it exists
if (Test-Path -Path "Y:\") {
    Write-Host "Disconnecting existing Y: drive..."
    net use Y: /delete /y
    Start-Sleep -Seconds 2
}
#
# 3️⃣ Re-map Y: to shared network location
Write-Host "Mapping Y: to \\Blue1\Data\Shared..."
net use Y: "\\Blue1\Data\Shared" /persistent:no
Start-Sleep -Seconds 2

# 4️⃣ Navigate to the photos folder
Set-Location "Y:\ppp.farm\photos"

# 4.5⃣ De-duplicate
Write-Host "Running Photo Deduplicater..."
if (Test-Path "..\Remove-DuplicatImages.ps1") {
    ..\Remove-DuplicatImages.ps1
} else {
    Write-Warning "Remove-DuplicatImages.ps1 not found in Y:\ppp.farm\"
}

# 5️⃣ Run the photo EXIF script (assumes it exists as script.ps1 in the same folder)
Write-Host "Running EXIF photo sorter..."
if (Test-Path ".\script.ps1") {
    .\script.ps1
} else {
    Write-Warning "script.ps1 not found in Y:\ppp.farm\photos"
}

# 6️⃣ Done
Write-Host "`n✅ Update complete. photos.json should now be ready in Y:\ppp.farm"
Write-Host "`n✅ Will posh everything to Git now..."

#Pause

Set-Location "Y:\ppp.farm\"

git add .
git commit -m "Updates to stuff"
git push origin main

Set-Location "C:\"
	
# 2️⃣ Remove Y: drive mapping if it exists
if (Test-Path -Path "Y:\") {
    Write-Host "Disconnecting existing Y: drive..."
    net use Y: /delete /y
    Start-Sleep -Seconds 2
}
	
#
#
Pause