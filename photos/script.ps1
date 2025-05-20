# 3️⃣ Re-scan all images in folders and rebuild full photos.json
Write-Host "`nRebuilding photos.json from all organized images..."
$allFiles = Get-ChildItem -Recurse -File | Where-Object {
    $_.Extension -match '\.jpe?g$' -and $_.FullName -notmatch 'script\.ps1'
}

$projectRoot = (Resolve-Path "..").Path
$photos = @()
$skipped = 0

foreach ($file in $allFiles) {
    try {
        $image = [System.Drawing.Image]::FromFile($file.FullName)

        # Try to get DateTimeOriginal
        $propItem = $null
        try {
            $propItem = $image.GetPropertyItem(36867)
        } catch { }

        if ($propItem) {
            $dateString = [System.Text.Encoding]::ASCII.GetString($propItem.Value).Trim([char]0)
            $dateTaken = [datetime]::ParseExact($dateString, "yyyy:MM:dd HH:mm:ss", $null)
        } else {
            # Fallback: use file date
            $dateTaken = (Get-Item $file.FullName).LastWriteTime
        }

        $image.Dispose()

        # Build relative path
        $relativePath = $file.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')

        $photos += @{
            file = $relativePath
            date = $dateTaken.ToString("yyyy-MM-ddTHH:mm:ss")
        }
    }
    catch {
        Write-Warning "Failed to process $($file.FullName): $($_.Exception.Message)"
        $skipped++
    }
}

# Sort and write
$sortedPhotos = $photos | Sort-Object -Property date -Descending
Write-Host "`nFound $($sortedPhotos.Count) valid photos. Skipped $skipped."

if ($sortedPhotos.Count -gt 0) {
    $json = $sortedPhotos | ConvertTo-Json -Depth 3
    $json | Out-File -Encoding utf8 "..\photos.json"
    Write-Host "✅ photos.json created at: ..\photos.json"
} else {
    if ($sortedPhotos.Count -gt 0) {
    $json = $sortedPhotos | ConvertTo-Json -Depth 3
    $json | Out-File -Encoding utf8 "..\photos.json"
    Write-Host "photos.json created at: ..\photos.json"
} else {
    Write-Warning "photos.json not created -- no valid photos found."
}

}
