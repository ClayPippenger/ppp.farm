Add-Type -AssemblyName System.Drawing

# 1️⃣ Strip EXIF from new files in root
Write-Host "Stripping EXIF metadata (except DateTimeOriginal)..."

$incomingFiles = Get-ChildItem -Path . -File -Filter *.jp*g -Exclude *.json, *.ps1 | Where-Object {
    $_.DirectoryName -eq (Get-Location).Path -and $_.Name -notmatch '^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}'
}

foreach ($file in $incomingFiles) {
    & exiftool "-all=" "-tagsFromFile" '@' "-DateTimeOriginal" "-overwrite_original" $file.FullName
}

# 2️⃣ Rename and organize new files
Write-Host "`nOrganizing photos by timestamp into folders..."

$photos = @()

foreach ($file in $incomingFiles) {
    try {
        $image = [System.Drawing.Image]::FromFile($file.FullName)

        try {
            $propItem = $image.GetPropertyItem(36867)
            $dateString = [System.Text.Encoding]::ASCII.GetString($propItem.Value).Trim([char]0)
            $dateTaken = [datetime]::ParseExact($dateString, "yyyy:MM:dd HH:mm:ss", $null)
        }
        catch {
            $dateTaken = (Get-Item $file.FullName).LastWriteTime
        }

        $image.Dispose()

        $timestamp = $dateTaken.ToString("yyyy-MM-dd_HH-mm-ss")
        $year = $dateTaken.ToString("yyyy")
        $month = $dateTaken.ToString("MM")
        $newName = "$timestamp$($file.Extension.ToLower())"
        $targetFolder = ".\$year\$month"

        if (!(Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder | Out-Null
        }

        $targetPath = Join-Path $targetFolder $newName

        if (-not (Test-Path $targetPath)) {
            Move-Item -Path $file.FullName -Destination $targetPath
            Write-Host "Moved: $($file.Name) → $targetPath"
        }

    }
    catch {
        Write-Warning "Error processing $($file.Name). Skipping."
    }
}

# 3️⃣ Re-scan all images in folders and rebuild full photos.json
Write-Host "`nRebuilding photos.json from all organized images..."
$allFiles = Get-ChildItem -Recurse -File | Where-Object {
    $_.Extension -match '\.jpe?g$' -and $_.FullName -notmatch 'script\.ps1'
}

foreach ($file in $allFiles) {
    try {
        $image = [System.Drawing.Image]::FromFile($file.FullName)

        try {
            $propItem = $image.GetPropertyItem(36867)
            $dateString = [System.Text.Encoding]::ASCII.GetString($propItem.Value).Trim([char]0)
            $dateTaken = [datetime]::ParseExact($dateString, "yyyy:MM:dd HH:mm:ss", $null)
        }
        catch {
            $dateTaken = (Get-Item $file.FullName).LastWriteTime
        }

        $image.Dispose()

        $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1).Replace('\', '/')

        $photos += @{
            file = $relativePath
            date = $dateTaken.ToString("yyyy-MM-ddTHH:mm:ss")
        }
    }
    catch {
        Write-Warning "Error reading EXIF from $($file.FullName)."
    }
}

# 4️⃣ Write JSON file
$sortedPhotos = $photos | Sort-Object -Property date -Descending
Write-Host "`nFound $($sortedPhotos.Count) total photos."

if ($sortedPhotos.Count -gt 0) {
    $json = $sortedPhotos | ConvertTo-Json -Depth 3
    $json | Out-File -Encoding utf8 ".\photos.json"
    Write-Host "✅ photos.json created successfully."
} else {
    Write-Warning "No photos processed. photos.json not created."
}
