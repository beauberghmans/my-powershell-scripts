<#
    .SYNOPSIS
    A script to send a system report to a Cisco Webex room.

    .DESCRIPTION
    Author:Beau Berghmans
#>
param (
    [string]$ServiceName = "Spooler"
)

# Webex Bot Token and Room ID
$WebexToken = "OGRiNjBlNzgtMjI5Zi00ODkxLTk5OTQtMTUzOTcyNWY4ODI5ZjZjYmU4ZTItODdl_P0A1_71b6b34c-abff-4407-ac50-5e62323aed80"
$RoomId = "Y2lzY29zcGFyazovL3VybjpURUFNOnVzLXdlc3QtMl9yL1JPT00vOTUyMmRhYTAtMzU1Zi0xMWYwLTg3ZGUtMTc3MWRmNWVlMDc3"

# Function to send message to Webex
function Send-WebexMessage {
    param (
        [string]$Token,
        [string]$RoomId,
        [string]$Message
    )

    $Uri = "https://webexapis.com/v1/messages"
    $Headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type"  = "application/json"
    }
    $Body = @{
        roomId = $RoomId
        text   = $Message
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $Uri -Method Post -Headers $Headers -Body $Body
}

# Function to get a basic system report
function Get-SystemReport {
    # Fix: convert WMI datetime to real DateTime
    $lastBoot = [System.Management.ManagementDateTimeConverter]::ToDateTime(
        (Get-WmiObject Win32_OperatingSystem).LastBootUpTime
    )
    $uptime = (Get-Date) - $lastBoot

    $cpu = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty LoadPercentage
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        "$($_.DeviceID): $([int]($_.FreeSpace / 1GB)) GB free"
    }

    $report = "System Report:`n"
    $report += "Uptime: $([int]$uptime.TotalHours) hours`n"
    $report += "CPU Load: $cpu%`n"
    $report += "Disk Free:`n$($disk -join "`n")"

    return $report
}

# Restart the service
Restart-Service -Name $ServiceName -Force

# Generate message
$health = Get-SystemReport
$message = "✅ The service '$ServiceName' has been restarted.`n`n$health"

# Send to Webex
Send-WebexMessage -Token $WebexToken -RoomId $RoomId -Message $message
