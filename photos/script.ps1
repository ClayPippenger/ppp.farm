Add-Type -AssemblyName System.Drawing

$photos = @()
$files = Get-ChildItem -File | Where-Object { $_.Extension -match '\.jpe?g$' -or $_.Extension -match '\.JPE?G$' }

foreach ($file in $files) {
    try {
        $image = [System.Drawing.Image]::FromFile($file.FullName)

        # Try to read EXIF DateTimeOriginal (tag 36867)
        try {
            $propItem = $image.GetPropertyItem(36867)
            $dateString = [System.Text.Encoding]::ASCII.GetString($propItem.Value).Trim([char]0)
            $dateTaken = [datetime]::ParseExact($dateString, "yyyy:MM:dd HH:mm:ss", $null)
        }
        catch {
            # Fallback: use file's last modified date
            Write-Warning "No EXIF date found for $($file.Name). Using file date instead."
            $dateTaken = (Get-Item $file.FullName).LastWriteTime
        }

        $photos += @{
            file = $file.Name
            date = $dateTaken.ToString("yyyy-MM-ddTHH:mm:ss")
        }

        $image.Dispose()
    }
    catch {
        Write-Warning "Error processing $($file.Name). Skipping."
    }
}

# Sort descending by date
$sortedPhotos = $photos | Sort-Object -Property date -Descending

# Display results
Write-Host "`nFound $($sortedPhotos.Count) photos."
if ($sortedPhotos.Count -gt 0) {
    $json = $sortedPhotos | ConvertTo-Json -Depth 3
    $json | Out-File -Encoding utf8 "..\photos.json"
    Write-Host "✅ photos.json created successfully."
} else {
    Write-Warning "No photos processed. photos.json not created."
}
