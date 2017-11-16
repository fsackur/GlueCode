<#
    .Synopsis
    A mock implementation of a configuration management database

    .Description
    Each account has ten devices, starting at account*10

    The account number is determined by dividing the device number and dropping the remainder.

    In each account, devices 0,1,2 are not Windows. 6,7 are cluster nodes. 8,9 are cluster objects.
#>

using module .\Info.Class.psm1  #this is relative path from current module, not from PWD
using namespace Info
using namespace System.Collections.Generic
using namespace System.Management.Automation




function Import-DeviceInfo {
    [CmdletBinding(DefaultParameterSetName = 'Device')]
    [OutputType([DeviceInfo[]])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Device')]
        [ValidatePattern('^\d+$')]
        [DeviceID[]]$Device,

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Account')]
        [ValidatePattern('^\d+$')]
        [AccountID]$Account
    )
    
    Write-Host "Performing expensive API call..." -ForegroundColor Yellow
    Start-Sleep 2

    if ($PSCmdlet.ParameterSetName -eq 'Account') {
        $Device = ([int][string]$Account * 10)..([int][string]$Account * 10 + 9)
    }

    foreach ($D in $Device) {
        $Account = [Math]::Truncate(([int][string]$D / 10))

        New-MockDeviceInfo $D $Account
    }

}


function Import-AccountInfo {
    [CmdletBinding()]
    [OutputType([AccountInfo])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidatePattern('^\d+$')]
        [AccountID]$Account
    )

    Write-Host "Performing expensive API call..." -ForegroundColor Yellow
    Start-Sleep 2

    $Device = ([int][string]$Account * 10)..([int][string]$Account * 10 + 9)

    [AccountInfo]@{ID = $Account; Device = $Device}
}


function New-MockDeviceInfo {
    param(
        [DeviceID]$Device,
        [AccountID]$Account
    )
    [DeviceInfo]@{
        ID              = $Device
        Account         = $Account
        Hostname        = ("{0}-Name" -f $Device)
        IP              = '0.0.0.0'
        CredentialList  = @()
        Domain          = "DOMAINCORP"
        AttachedDevices = $(if ([int][string]$Device % 10 -in (8, 9)) { ([string]$Account + "6", [string]$Account + "7") } else { $null })
        IsWindows       = [int][string]$Device % 10 -notin (0, 1, 2)
        IsCluster       = [int][string]$Device % 10 -in (8, 9)
        IsServer        = [int][string]$Device % 10 -in (2, 3, 4, 5, 6, 7)
    }
}


Export-ModuleMember Import-AccountInfo, Import-DeviceInfo
