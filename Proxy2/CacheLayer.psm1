using module .\Info.Class.psm1  #this is relative path from current module, not from PWD
using namespace Info
using module .\Cache.Class.psm1
using namespace Cache
using namespace DEntry
using namespace System.Management.Automation


Import-Module $PSScriptRoot\DB.psm1 -Force


$Cache = [Cache]::GetInstance()


function Import-DeviceInfo {
    <#
    .SYNOPSIS
    Imports devices from a configuration management database
    
    .DESCRIPTION
    Imports devices as DeviceInfo, which is defined in the Info.Class.psm1 file.

    Fetches device ID in the database, IP address, credentials. Everything required to manage a device.
    
    .PARAMETER Device
    The unique ID for the device in the configuration management database
    
    .PARAMETER Account
    The unique ID for the account in the configuration management database. When this parameter is specified, all devices in the account will be returned.
    
    .EXAMPLE
    Import-DeviceInfo 109223

    ID     Account Hostname IP
    --     ------- -------- --
    109223 41233   UKEXCH01 10.24.0.77

    .EXAMPLE
    Import-DeviceInfo 109223, 109272
    
    ID     Account Hostname IP
    --     ------- -------- --
    109223 41233   UKEXCH01 10.24.0.77
    109272 41233   UKDB04   10.16.0.20

    #>
    [CmdletBinding(DefaultParameterSetName='Device')]
    [OutputType([DeviceInfo[]])]
    param(
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='Device', ValueFromPipeline=$true)]
        [DeviceID[]]$Device,

        [Parameter(Mandatory=$true, Position=0, ParameterSetName='Account')]
        [AccountID]$Account
    )
    
    begin {
        if ($PSCmdlet.ParameterSetName -ne 'Device') {throw 'Not implemented yet'}
        [DeviceID[]]$CacheMisses = @()
    }
    
    process {
        foreach ($ID in $Device) {
            $DeviceInfo = $Cache.ReadDevice($ID, $ErrorCallback)
            if ($DeviceInfo) {
                $DeviceInfo
            } else {
                $CacheMisses += $ID
            }
        }
    }

    end {
        if ($CacheMisses) {
            $PSBoundParameters['Device'] = $CacheMisses
            $DeviceInfo = & DB\Import-DeviceInfo @PSBoundParameters
            $DeviceInfo | % {
                $Cache.WriteDevice($_)
                $_
            }
        }
    }
}


function Import-AccountInfo {
    <#
    .SYNOPSIS
    Imports a customer account from a configuration management database
    
    .DESCRIPTION
    Imports accounts as AccountInfo, which is defined in the Info.Class.psm1 file.

    Fetches account ID in the database and the IDs of all devices that belong to that account
    
    .PARAMETER Account
    The unique ID for the account in the configuration management database
    
    .PARAMETER ErrorCallback
    A scriptblock that is invoked when common exceptions occur. The purpose of this is to allow error-handling code to be contained in the most logical place, rather than inline with the processing code.
    
    .EXAMPLE
    Import-AccountInfo 41233

    ID    Device
    --    ------
    41233 {109223, 109228, 109272, 109314...}

    #>
    [CmdletBinding()]
    [OutputType([AccountInfo])]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [AccountID]$Account
    )

    $AccountInfo = $Cache.ReadAccount($Account)
    if ($AccountInfo) {
        $AccountInfo
        
    } else {
        $AccountInfo = & DB\Import-AccountInfo @PSBoundParameters
        $Cache.WriteAccount($AccountInfo)
        $AccountInfo
    }
}


Export-ModuleMember Import-DeviceInfo, Import-AccountInfo
