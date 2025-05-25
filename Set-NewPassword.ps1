<#
    .SYNOPSIS
    A script to reset the password of an AD user.

    .DESCRIPTION
    Author:Beau Berghmans
#>

# Parameters
param {
    [Parameter(Mandatory=$true)]
    [string]$userToResetInAD # Fill in samAccountName of user whos password you want to reset
    [Parameter(Mandatory=$true)]
    [string]$authenticatedUser # User account with admin rights in AD
}

$remoteComputer = "ADSRV01"
$creds = Get-Credential -Credential "$authenticatedUser"

# Generate a random password
function Get-RandomPassword {
    param(
            [int]$Length = 12
    )
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()'
    -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}
$password = Get-RandomPassword 8

# Connect to remote computer
$newSession = New-PSSession -ComputerName $remoteComputer -Credential $creds
Import-Module -PSSession $newSession -Name ActiveDirectory

# Set new password
Set-ADAccountPassword -Identity "$userToResetInAD" -NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force) -Reset 

Write-Host "The new password is:" -ForegroundColor Blue
Write-Host "$password" -ForegroundColor Green