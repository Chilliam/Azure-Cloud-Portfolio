param(
    [string]$CsvPath = ".\users.csv",
    [switch]$WhatIf
)

$users = Import-Csv -Path $CsvPath
$results = @()

foreach ($user in $users) {
    $existing = az ad user show --id $user.UserPrincipalName 2>$null

    if ($existing) {
        Write-Host "SKIPPED (already exists): $($user.UserPrincipalName)" -ForegroundColor Yellow
        $results += [PSCustomObject]@{ User = $user.UserPrincipalName; Action = "Skipped"; Reason = "Already exists" }
        continue
    }

    if ($WhatIf) {
        Write-Host "WHATIF: Would create $($user.UserPrincipalName) and add to $($user.Group)" -ForegroundColor Cyan
        $results += [PSCustomObject]@{ User = $user.UserPrincipalName; Action = "WhatIf-Create"; Reason = "-WhatIf specified" }
        continue
    }

    $randomPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_})
    $randomPassword = $randomPassword + "!1"

    try {
        $newUserJson = az ad user create --display-name $user.DisplayName --user-principal-name $user.UserPrincipalName --mail-nickname $user.MailNickname --password $randomPassword --force-change-password-next-sign-in true -o json

        if ($LASTEXITCODE -ne 0) { throw "az ad user create failed" }

        $newUser = $newUserJson | ConvertFrom-Json
        az ad group member add --group $user.Group --member-id $newUser.id

        if ($LASTEXITCODE -ne 0) { throw "az ad group member add failed" }

        Write-Host "CREATED: $($user.UserPrincipalName) -> added to $($user.Group)" -ForegroundColor Green
        $results += [PSCustomObject]@{ User = $user.UserPrincipalName; Action = "Created"; Reason = "Success" }
    }
    catch {
        Write-Host "FAILED: $($user.UserPrincipalName) - $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{ User = $user.UserPrincipalName; Action = "Failed"; Reason = $_.Exception.Message }
    }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputPath = ".\bulk-user-results-$timestamp.csv"
$results | Export-Csv -Path $outputPath -NoTypeInformation
Write-Host ""
Write-Host "Done. Results written to $outputPath"