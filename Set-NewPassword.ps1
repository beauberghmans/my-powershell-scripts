<#
    .DESCRIPTION
    Author:Beau Berghmans
#>
#Variables
$remoteComputer = "ADSRV01"
$creds = Get-Credential -Credential "PersonalLab191\administrator"
$user = "xxx.xxx" #Fill in samAccountName of user whos password you want to reset

#Generate a random password
function Get-RandomPassword {
    param(
            [int]$Length = 12
    )
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()'
    -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}
$password = Get-RandomPassword 8

#Connect to remote computer
$newSession = New-PSSession -ComputerName $remoteComputer -Credential $creds
Import-Module -PSSession $newSession -Name ActiveDirectory

#Set new password
Set-ADAccountPassword -Identity "$user" -NewPassword (ConvertTo-SecureString "$password" -AsPlainText -Force) -Reset 

Write-Host "The new password is:" -ForegroundColor Blue
Write-Host "$password" -ForegroundColor Green