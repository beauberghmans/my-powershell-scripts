<#

.SYNOPSIS
Filters devices based on their Windows OS build version and adds them to a static Azure AD group.

.DESCRIPTION
This script connects to Microsoft Graph, retrieves all registered devices, compares their OperatingSystemVersion
to a specified build threshold, and adds devices with an older build to a specific static Azure Active Directory group.
It helps administrators automatically group devices with outdated builds for management or compliance purposes.

.PARAMETER groupId
The ObjectId of the Azure AD group to which the filtered devices will be added.

.PARAMETER thresholdBuild
The OS build version used as the threshold to filter devices. Devices with a lower build are added to the group.

.EXAMPLE
.\Update-DeviceGroupByBuild.ps1 -groupId "12345678-90ab-cdef-1234-567890abcdef" -thresholdBuild "10.0.22000"

Adds all devices with a Windows OS build lower than 10.0.22000 to the specified group.

#>

Import-Module Microsoft.Graph

$groupId = "4ff2b226-f926-4537-b7b3-62a6ca75ffc7"
$maxBuildVersion = "10.0.22000"

Connect-MgGraph -Scopes "Group.ReadWrite.All", "Device.Read.All"

function Compare-BuildVersion($v1, $v2) {
    $parts1 = $v1.Split('.') | ForEach-Object { if ($_ -match '^\d+$') { [int]$_ } else { 0 } }
    $parts2 = $v2.Split('.') | ForEach-Object { if ($_ -match '^\d+$') { [int]$_ } else { 0 } }
    $maxLength = [Math]::Max($parts1.Length, $parts2.Length)
    for ($i=0; $i -lt $maxLength; $i++) {
        $p1 = if ($i -lt $parts1.Length) { $parts1[$i] } else { 0 }
        $p2 = if ($i -lt $parts2.Length) { $parts2[$i] } else { 0 }
        if ($p1 -lt $p2) { return -1 }
        elseif ($p1 -gt $p2) { return 1 }
    }
    return 0
}

Write-Host "Fetching all Azure AD devices..."
$allDevices = Get-MgDevice -All

Write-Host "Filtering devices with OS build <= $maxBuildVersion and excluding devices with 'SRV' in their name..."
$filteredDevices = $allDevices | Where-Object {
    $_.OperatingSystemVersion -and
    (Compare-BuildVersion $_.OperatingSystemVersion $maxBuildVersion) -le 0 -and
    $_.DisplayName -notmatch "SRV"
}

Write-Host "Found $($filteredDevices.Count) devices with OS build <= $maxBuildVersion and no 'SRV' in name."

Write-Host "Fetching current group members..."
$currentMembers = Get-MgGroupMember -GroupId $groupId -All | Select-Object -ExpandProperty Id

foreach ($device in $filteredDevices) {
    if ($currentMembers -contains $device.Id) {
        Write-Host "Device '$($device.DisplayName)' already in group."
        continue
    }

    $uri = "https://graph.microsoft.com/v1.0/groups/$groupId/members/`$ref"
    $body = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/devices/$($device.Id)" } | ConvertTo-Json

    try {
        Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType "application/json"
        Write-Host "Added device '$($device.DisplayName)' with build $($device.OperatingSystemVersion) to group."
    }
    catch {
        Write-Warning "Failed to add device '$($device.DisplayName)': $_"
    }
}

Disconnect-MgGraph
