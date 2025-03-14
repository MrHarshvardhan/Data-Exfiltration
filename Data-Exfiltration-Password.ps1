param (
    [string]$folder,
    [switch]$decode
)

function Get-EncryptionKey {
    param ([SecureString]$securePassword)
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) # Securely remove from memory
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    return $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($password))
}

function Encrypt-File {
    param ([string]$filePath, [byte[]]$key)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key
    $aes.GenerateIV()
    $iv = $aes.IV

    $encryptor = $aes.CreateEncryptor()
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    $encryptedBytes = $encryptor.TransformFinalBlock($fileBytes, 0, $fileBytes.Length)

    $result = New-Object byte[] ($iv.Length + $encryptedBytes.Length)
    [System.Buffer]::BlockCopy($iv, 0, $result, 0, $iv.Length)
    [System.Buffer]::BlockCopy($encryptedBytes, 0, $result, $iv.Length, $encryptedBytes.Length)

    return $result
}

function Decrypt-File {
    param ([byte[]]$encryptedData, [byte[]]$key)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $key

    $iv = $encryptedData[0..15]
    $cipherText = $encryptedData[16..($encryptedData.Length - 1)]

    $aes.IV = $iv
    $decryptor = $aes.CreateDecryptor()
    return $decryptor.TransformFinalBlock($cipherText, 0, $cipherText.Length)
}

function Encode-Files {
    param ([string]$folder)
    $securePassword = Read-Host "Enter encryption password" -AsSecureString
    $key = Get-EncryptionKey -securePassword $securePassword

    Get-ChildItem -Path $folder -File | ForEach-Object {
        $filePath = $_.FullName
        $fileName = $_.Name
        $encryptedData = Encrypt-File -filePath $filePath -key $key
        $encodedData = [Convert]::ToBase64String($encryptedData)

        $header = "Confidential Report - Internal Use Only`n`n"
        $outputContent = $header + $encodedData
        $outputPath = "$folder\$fileName.txt"
        [System.IO.File]::WriteAllText($outputPath, $outputContent)

        Write-Host "Encoded: $fileName -> $outputPath"
    }
}

function Decode-Files {
    param ([string]$folder)
    $securePassword = Read-Host "Enter decryption password" -AsSecureString
    $key = Get-EncryptionKey -securePassword $securePassword

    Get-ChildItem -Path $folder -File | Where-Object { $_.Extension -eq ".txt" } | ForEach-Object {
        $filePath = $_.FullName
        $fileName = $_.BaseName
        $content = [System.IO.File]::ReadAllText($filePath)
        $encodedData = $content -replace "^.*?`n`n", ""
        $encryptedData = [Convert]::FromBase64String($encodedData)
        $decryptedData = Decrypt-File -encryptedData $encryptedData -key $key
        $outputPath = "$folder\$fileName"
        [System.IO.File]::WriteAllBytes($outputPath, $decryptedData)

        Write-Host "Decoded: $filePath -> $outputPath"
    }
}

if ($decode) {
    Decode-Files -folder $folder
} else {
    Encode-Files -folder $folder
}
