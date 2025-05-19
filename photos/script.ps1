Add-Type -AssemblyName System.Drawing

# 1️⃣ Strip EXIF except DateTimeOriginal
Write-Host "Stripping EXIF metadata (except DateTimeOriginal)..."

$extensions = @("*.jpg", "*.jpeg", "*.JPG", "*.JPEG")
foreach ($ext in $extensions) {
    & exiftool "-all=" "-tagsFromFile" '@' "-DateTimeOriginal" "-overwrite_original" $ext
}

# 2️⃣ Process each image
Write-Host "`nRenaming and organizing files into folders by year/month..."

$photos = @()
$files = Get-ChildItem -File | Where-Object { $_.Extension -match '\.jpe?g$' -or $_.Extension -match '\.JPE?G$' }

foreach ($file in $files) {
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

        if ($file.FullName -ne $targetPath -and -not (Test-Path $targetPath)) {
            Move-Item -Path $file.FullName -Destination $targetPath
            Write-Host "Moved $($file.Name) → $targetPath"
        }

        $relativePath = "$year/$month/$newName"

        $photos += @{
            file = $relativePath
            date = $dateTaken.ToString("yyyy-MM-ddTHH:mm:ss")
        }
    }
    catch {
        Write-Warning "Error processing $($file.Name). Skipping."
    }
}

# 3️⃣ Save photos.json to root
$sortedPhotos = $photos | Sort-Object -Property date -Descending
Write-Host "`nFound $($sortedPhotos.Count) photos."

if ($sortedPhotos.Count -gt 0) {
    $json = $sortedPhotos | ConvertTo-Json -Depth 3
    $json | Out-File -Encoding utf8 ".\photos.json"
    Write-Host "✅ photos.json created successfully."
} else {
    Write-Warning "No photos processed. photos.json not created."
}
