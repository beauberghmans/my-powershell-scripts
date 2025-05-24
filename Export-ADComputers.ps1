<#
    .DESCRIPTION
    Author:Beau Berghmans
#>
# Modules
Import-Module ActiveDirectory

# Variables
$twoMonthsInDays = 60
$twoMonths = (Get-Date).AddDays(-$twoMonthsInDays)
$domain = "enteryourdomainhere"

# Query AD and add to variable
$computers = Get-ADComputer -Server $domain -Filter {
    OperatingSystem -like "*Windows 10*" -and
    LastLogonDate -ge $twoMonths
} -Property Name, OperatingSystem, LastLogonDate

# Display results
$computers | Select-Object Name, OperatingSystem, LastLogonDate | Format-Table -AutoSize

# Export to CSV
$computers | Select-Object Name, OperatingSystem, LastLogonDate | Export-Csv -Path "C:\Temp\Export.csv" -Delimiter ";" -NoTypeInformation
