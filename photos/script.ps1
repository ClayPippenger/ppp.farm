# Set root location
$projectRoot = (Resolve-Path "..").Path

# Get only .jpeg/.jpg files from root
$incomingFiles = Get-ChildItem -Path . -File -Filter *.jp*g | Where-Object {
    $_.DirectoryName -eq (Get-Location).Path -and $_.Name -notmatch '^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}'
}

# Strip EXIF but keep DateTimeOriginal
Write-Host "Stripping EXIF metadata (except DateTimeOriginal)..."
foreach ($file in $incomingFiles) {
    & exiftool "-all=" "-tagsFromFile" '@' "-DateTimeOriginal" "-overwrite_original" $file.FullName | Out-Null
}

# Rename and move new photos
$photos = @()
foreach ($file in $incomingFiles) {
    $date = & exiftool -DateTimeOriginal -s3 "$($file.FullName)"
    if (-not $date) {
        $dateTaken = (Get-Item $file.FullName).LastWriteTime
    } else {
        $dateTaken = [datetime]::ParseExact($date, "yyyy:MM:dd HH:mm:ss", $null)
    }

    $timestamp = $dateTaken.ToString("yyyy-MM-dd_HH-mm-ss")
    $year = $dateTaken.ToString("yyyy")
    $month = $dateTaken.ToString("MM")
    $ext = $file.Extension.ToLower()
    $newName = "$timestamp$ext"
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

# Rebuild photos.json
Write-Host "`nRebuilding photos.json..."
$allPhotos = @()
$allFiles = Get-ChildItem -Recurse -File | Where-Object {
    $_.Extension -match '\.jpe?g$'
}

foreach ($file in $allFiles) {
    $date = & exiftool -DateTimeOriginal -s3 "$($file.FullName)"
    if (-not $date) {
        $dateTaken = (Get-Item $file.FullName).LastWriteTime
    } else {
        $dateTaken = [datetime]::ParseExact($date, "yyyy:MM:dd HH:mm:ss", $null)
    }

    $relativePath = $file.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')

    $allPhotos += @{
        file = $relativePath
        date = $dateTaken.ToString("yyyy-MM-ddTHH:mm:ss")
    }
}

$sorted = $allPhotos | Sort-Object -Property date -Descending
$json = $sorted | ConvertTo-Json -Depth 3
$json | Out-File -Encoding utf8 "..\photos.json"
Write-Host "✅ photos.json updated: $($sorted.Count) photos."
