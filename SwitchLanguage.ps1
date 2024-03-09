param(
    [string]$Mode # Expected values: 'English', 'Chinese', 'Restore'
)

function Switch-Language {
    param(
        [string]$desiredLang,
        [bool]$restoreFullList
    )

    $currentList = Get-WinUserLanguageList
    $listCount = $currentList.Count

    # Save the original list to a file if it has more than one language
    if ($listCount -gt 1) {
        $originalListJson = $currentList | ConvertTo-Json
        Set-Content "originalList.txt" -Value $originalListJson
    }

    if ($desiredLang -ne $null) {
        if ($restoreFullList) {
            # Temporarily add desired language, delay, then restore
            $tempList = New-WinUserLanguageList $desiredLang
            Set-WinUserLanguageList $tempList -Force
            Start-Sleep -Seconds 2
            Restore-OriginalList
        } else {
            # For English, clear all other input methods, keeping only en-US
            $newList = New-WinUserLanguageList $desiredLang
            Set-WinUserLanguageList $newList -Force
        }
    }
}

function Restore-OriginalList {
    $logPath = "restoreLog.txt"
    "Starting to restore the original list of input languages..." | Out-File $logPath -Append

    $filePath = "originalList.txt"
    if (Test-Path $filePath) {
        "File $filePath exists. Proceeding with restore operation." | Out-File $logPath -Append
        try {
            $jsonContent = Get-Content $filePath -Raw
            "Loaded JSON content from file:" | Out-File $logPath -Append
            $jsonContent | Out-File $logPath -Append

            $languageTags = $jsonContent | ConvertFrom-Json | ForEach-Object { $_.LanguageTag }
            "Extracted Language Tags:" | Out-File $logPath -Append
            $languageTags | Out-File $logPath -Append
            
            $newLangList = New-WinUserLanguageList $zh-CN
            foreach ($tag in $languageTags) {
                "Processing Language Tag: $tag" | Out-File $logPath -Append
                $newLangList.Add($tag)
            }

            Set-WinUserLanguageList $newLangList -Force
            "Original list of input languages restored successfully." | Out-File $logPath -Append
        }
        catch {
            "Error occurred during restore operation:" | Out-File $logPath -Append
            $_.Exception.Message | Out-File $logPath -Append
            $_.Exception | Format-List * | Out-File $logPath -Append
        }
    }
    else {
        "File $filePath not found. Cannot restore the original list of input languages." | Out-File $logPath -Append
    }
}


switch ($Mode) {
    "English" {
        Switch-Language -desiredLang "en-US" -restoreFullList $false
    }
    "Chinese" {
        Switch-Language -desiredLang "zh-CN" -restoreFullList $false
    }
    "Restore" {
        Restore-OriginalList
    }
}
