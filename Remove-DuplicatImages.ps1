# Remove-DuplicateImages.ps1

$hashSet = @{}
$imageExtensions = @("*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.tiff", "*.webp")

function Get-MD5Hash($filePath) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $stream = [System.IO.File]::OpenRead($filePath)
    try {
        $hashBytes = $md5.ComputeHash($stream)
        return ([System.BitConverter]::ToString($hashBytes) -replace "-", "").ToLower()
    } finally {
        $stream.Close()
        $md5.Dispose()
    }
}

Write-Host "Scanning for duplicate image files in $PWD..." -ForegroundColor Cyan

foreach ($ext in $imageExtensions) {
    Get-ChildItem -Recurse -Filter $ext -File | ForEach-Object {
        $hash = Get-MD5Hash $_.FullName
        if ($hashSet.ContainsKey($hash)) {
            Write-Host "Duplicate found: $($_.FullName)" -ForegroundColor Yellow
            Remove-Item $_.FullName -Force
        } else {
            $hashSet[$hash] = $_.FullName
        }
    }
}

Write-Host "Deduplication complete." -ForegroundColor Green
#Pause