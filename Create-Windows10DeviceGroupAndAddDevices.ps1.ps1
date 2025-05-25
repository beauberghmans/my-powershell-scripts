<#
.SYNOPSIS
    Creates a security group in Microsoft Entra (Entra ID) and adds all Windows 10 devices below a specified build number to this group.

.DESCRIPTION
    This script connects to Microsoft Graph with appropriate permissions, retrieves all devices from the tenant, filters for Windows devices with a build number less than 22000, this way we exclude Windows 11 devices.
    We also filter out devices that are servers based on their displayname.
    then creates a security group named "Windows 10 Devices". Finally, it adds the filtered Windows 10 devices to the newly created group.

    The script requires the Microsoft.Graph PowerShell module and permissions Device.ReadWrite.All and Group.ReadWrite.All.

.NOTES
    Author: Beau Berghmans
    Date: 25-05-2025
#>

# Check if Microsoft Graph module is installed.
Get-Module Microsoft.Graph -ListAvailable

# Login to Graph with required permissions.
Connect-MgGraph -Scopes "Device.ReadWrite.All", "Group.ReadWrite.All"

# Retrieve all devices and store in a variable.
$devices = Get-MgDevice

# Filter for Windows devices with a build number less than 22000
# We focus on the third segment in OperatingSystemVersion, e.g. 10.0.19041.1237 -> 19041 (to exclude Windows 11)
$windowsDevices = $devices | Where-Object {
    $_.OperatingSystem.ToLower() -eq "windows" -and
    ($_.OperatingSystemVersion.Split('.')[2] -as [int]) -lt 22000
} 

# Exclude Windows Servers (hybrid joined) by filtering out device names containing "srv" or "server"
$filteredDevices = $windowsDevices | Where-Object {
    $_.DisplayName -notlike ("*srv*") -and 
    $_.DisplayName -notlike ("*server*")
}

# Define parameters for the new security group
$groupParams = @{
    DisplayName         = "Windows 10 Devices"
    MailEnabled         = $false
    MailNickname        = "w10devices"
    SecurityEnabled     = $true
}

# Create the security group in Entra ID
$group = New-MgGroup @groupParams

# Add each filtered device as a member of the created group
foreach ($device in $filteredDevices) {
    # Create hashtable of API call
    $body = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/devices/$($device.Id)"
    }
    # Add device to the group we created earlier.
    New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter $body
}

# Output the group creation result
Write-Host "Group created with displayname: ""$($group.DisplayName)"" and ID: ""$($group.Id)"". Following devices have been added:"

foreach($device in $filteredDevices) {
    Write-Host "- $($device.DisplayName)"
}

# Disconnect the Microsoft Graph session
Disconnect-MgGraph

Write-Host "Disconnected from Microsoft Graph."