param(
    [string]$folder,
    [switch]$decode
)

function Generate-Key {
    param([int]$length = 10)
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    return -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

function XOR-Encrypt-Decrypt {
    param([string]$content, [string]$key)
    $output = ""
    for ($i = 0; $i -lt $content.Length; $i++) {
        $output += [char]([byte][char]$content[$i] -bxor [byte][char]$key[$i % $key.Length])
    }
    return $output
}

function Split-File {
    param([string]$content, [int]$partSize)
    $parts = @()
    for ($i = 0; $i -lt $content.Length; $i += $partSize) {
        $parts += $content.Substring($i, [Math]::Min($partSize, $content.Length - $i))
    }
    return $parts
}

function Merge-Parts {
    param([string]$folder, [string]$baseName, [int]$totalParts)
    $fullContent = ""
    for ($i = 1; $i -le $totalParts; $i++) {
        $partPath = "$folder\$baseName`_part$i.txt"
        if (!(Test-Path $partPath)) {
            Write-Host "Error: Missing part $i for file $baseName"
            return $null
        }
        $fullContent += Get-Content -Path $partPath -Raw
    }
    return $fullContent
}

function Encode-Files {
    param([string]$folder, [int]$partSize = 500000)

    Get-ChildItem -Path $folder -File | ForEach-Object {
        $filePath = $_.FullName
        $fileName = $_.BaseName
        $extension = $_.Extension

        $binaryContent = [System.IO.File]::ReadAllBytes($filePath)
        $stringContent = [System.Text.Encoding]::UTF8.GetString($binaryContent)

        $key = Generate-Key
        $encryptedContent = XOR-Encrypt-Decrypt -content $stringContent -key $key
        $parts = Split-File -content $encryptedContent -partSize $partSize

        for ($i = 0; $i -lt $parts.Count; $i++) {
            $partFile = "$folder\$fileName`_part$($i+1).txt"
            if ($i -eq 0) {
                "$extension`n$key" | Out-File -FilePath $partFile -Encoding utf8
            }
            $parts[$i] | Out-File -FilePath $partFile -Append -Encoding utf8
        }
        
        Write-Host "Converted: $($_.Name) -> $($parts.Count) parts"
    }
}

function Decode-Files {
    param([string]$folder)
    $decodedFiles = @{}

    Get-ChildItem -Path $folder -File | Where-Object { $_.Name -match '_part\d+\.txt$' } | ForEach-Object {
        $baseName = $_.Name -replace '_part\d+\.txt$', ''
        $partNum = [int]($_.Name -replace '^.*_part(\d+)\.txt$', '$1')

        if (-not $decodedFiles.ContainsKey($baseName)) {
            $decodedFiles[$baseName] = @()
        }
        $decodedFiles[$baseName] += @{ PartNum = $partNum; FileName = $_.FullName }
    }

    foreach ($baseFile in $decodedFiles.Keys) {
        $parts = $decodedFiles[$baseFile] | Sort-Object PartNum
        $totalParts = $parts.Count
        $fullContent = Merge-Parts -folder $folder -baseName $baseFile -totalParts $totalParts

        if ($null -eq $fullContent) { continue }

        $lines = $fullContent -split "`n", 3
        $originalExtension = $lines[0].Trim()
        $key = $lines[1].Trim()
        $encryptedContent = if ($lines.Count -gt 2) { $lines[2] } else { "" }

        $decryptedContent = XOR-Encrypt-Decrypt -content $encryptedContent -key $key
        $originalFilename = "$folder\$baseFile$originalExtension"

        [System.IO.File]::WriteAllBytes($originalFilename, [System.Text.Encoding]::UTF8.GetBytes($decryptedContent))
        Write-Host "Restored: $baseFile -> $originalFilename"
    }
}

if ($decode) {
    Decode-Files -folder $folder
} else {
    Encode-Files -folder $folder
}
