<#
    .SYNOPSIS
    A script to reset the password of an AD user.

    .DESCRIPTION
    Revised "Set-NewPassword.ps1" by reworking the Get-RandomPassword function to meet the password requirtements of the domain.
    Also we will be using invoke-command with a $scriptblock instead of importing the ActiveDirectory module onto our system

    Author:Beau Berghmans
    Date: 25-05-2025
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$adUser, # Fill in samAccountName of user whos password you want to reset
    [Parameter(Mandatory=$true)]
    [string]$adminAccount, # User account with admin rights in AD
    [Parameter(Mandatory=$true)]
    [int]$lengthOfPassword # Length of password
)

$remoteComputer = "ADSRV01"
$creds = Get-Credential -Credential "$adminAccount"

function Get-RandomPassword {
    param(
        [int]$length = 12
    )

    $upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $lowerCase = "abcdefghijklmnopqrstuvwxyz"
    $numbers = "0123456789"
    $specialChars = "!@#$%^&*"

    $mandatory = @(
        $upperCase[(Get-Random -Maximum $upperCase.Length)]
        $lowerCase[(Get-Random -Maximum $lowerCase.Length)]
        $numbers[(Get-Random -Maximum $numbers.Length)]
        $specialChars[(Get-Random -Maximum $specialChars.Length)]
    )

    $allChars = $upperCase + $lowerCase + $numbers + $specialChars
    $remainingChars = (1..($length - 4)) | ForEach-Object { $allChars[(Get-Random -Maximum $allChars.length)] }

    $passwordChars = $mandatory + $remainingChars | Sort-Object { Get-Random }
    $finalPassword = -join $passwordChars

    return $finalPassword
}

$randomPassword = Get-RandomPassword -length $lengthOfPassword
$securePassword = ConvertTo-SecureString $randomPassword -AsPlainText -Force

$scriptBlock = {
    param($user, [securestring]$password)
    Set-ADAccountPassword -Identity $user -NewPassword $password -reset
}

$newSession = New-PSSession -ComputerName $remoteComputer -Credential $creds
Invoke-Command -Session $newSession -ScriptBlock $scriptBlock -ArgumentList $adUser, $securePassword

Write-Host "The new password is:" -ForegroundColor Blue
Write-Host "$randomPassword" -ForegroundColor Green

# Close PS session
Remove-PSSession $newSession