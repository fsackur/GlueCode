<#
    .Synopsis
    This is the class definition for DeviceInfo and AccountInfo. 
    
    DeviceInfo represents a target computer, as stored in a configuration database.

    AccountInfo represents a container for computers. One account can have many devices (or none) but 
    each device can have only one account.
#>

using namespace System.Collections.Generic
using namespace System.Management.Automation.Runspaces


class DeviceID {
    hidden DeviceID () {}
    
    DeviceID ([string]$ID) {
        $this.ID = $ID
    }

    [ValidatePattern('^\d+$')]
    hidden [string]$ID

    #Override methods from Object
    [bool] Equals ($obj) {
        return $this.ID.Equals($obj.ToString())
    }

    [int] GetHashCode() {
        return $this.ID.GetHashCode()
    }

    [string] ToString() {
        return $this.ID
    }
}

class AccountID {
    hidden AccountID () {}
    
    AccountID ([string]$ID) {
        $this.ID = $ID
    }

    [ValidatePattern('^\d+$')]
    hidden [string]$ID

    #Override methods from Object
    [bool] Equals ($obj) {
        return $this.ID.Equals($obj.ToString())
    }

    [int] GetHashCode() {
        return $this.ID.GetHashCode()
    }

    [string] ToString() {
        return $this.ID
    }
}


class AccountInfo {
    
    hidden AccountInfo () {}

    AccountInfo ([AccountID]$ID) {
        $this.ID = $ID
    }

    AccountInfo ([AccountID]$ID, [DeviceID[]]$Device) {
        $this.ID = $ID
        $this.Device = $Device
    }

    [AccountID]$ID
    [DeviceID[]]$Device

    #Override methods from Object
    [bool] Equals ($obj) {
        return $this.ID.Equals($obj.ToString())
    }

    [int] GetHashCode() {
        return $this.ID.GetHashCode()
    }

    [string] ToString() {
        return $this.ID
    }
}


class DeviceInfo {
    
    hidden DeviceInfo () {}
    
    DeviceInfo ([DeviceID]$ID) {
        $this.ID = $ID
    }
    
    DeviceInfo ([DeviceID]$ID, [AccountID]$Account, [string]$Hostname, [ipaddress]$IP, [List[pscredential]]$CredentialList) {
        $this.ID = $ID
        $this.Hostname = $Hostname
        $this.IP = $IP
        $this.CredentialList = $CredentialList
    }

    DeviceInfo ([DeviceID]$ID, [AccountID]$Account, [string]$Hostname, [ipaddress]$IP, [List[pscredential]]$CredentialList, [string]$Domain, [string[]]$AttachedDevices, [bool]$IsWindows, [bool]$IsCluster, [bool]$IsServer) {
        $this.ID = $ID
        $this.Account = $Account
        $this.Hostname = $Hostname
        $this.IP = $IP
        $this.CredentialList = $CredentialList
        $this.Domain = $Domain
        $this.AttachedDevices = $AttachedDevices
        $this.IsWindows = $IsWindows
        $this.IsCluster = $IsCluster
        $this.IsServer = $IsServer
    }

    [DeviceID]$ID
    [AccountID]$Account
    [string]$Hostname
    [ipaddress]$IP
    hidden [List[pscredential]]$CredentialList
    hidden [PSSession]$Session
    hidden [System.Management.Automation.PSDriveInfo]$Drive
    [string]$Domain
    [string[]]$AttachedDevices
    [bool]$IsWindows
    [bool]$IsCluster
    [bool]$IsServer
    

    [pscredential] GetCredential () {
        return $this.CredentialList[0]
    }
    
    [PSSession] GetSession () {
        if ($null -ne $this.Session -and $this.Session.Availability -eq [RunspaceAvailability]::Available) {
            return $this.Session

        }
        else {
            $PSSessionSplat = @{
                ComputerName  = $this.IP
                Name          = $this.ID
                UseSSL        = [switch]::Present
                SessionOption = (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck)
            }

            #Testing on local machine
            if ($this.IP -eq [ipaddress]'127.0.0.1') {
                $PSSessionSplat.Remove('UseSSL')
            }

            $this.Session = New-PSSession -Credential $this.GetCredential() @PSSessionSplat
            return $this.Session
        }
    }

    [System.Management.Automation.PSDriveInfo] GetDrive () {
        if ($null -eq $this.Drive) {
            $this.Drive = New-PSDrive -PSProvider FileSystem -Name $this.ID -Root "\\$($this.IP)\C$" -Credential $this.GetCredential()
        }
        return $this.Drive
    }


    Dispose () {
        if ($null -ne $this.Session) {
            Remove-PSSession $this.Session
        }
        if ($null -ne $this.Drive) {
            Remove-PSDrive -Name $this.Drive.Name
        }
    }


    #Override methods from Object
    [bool] Equals ($obj) {
        return $this.ID.Equals($obj.ToString())
    }

    [int] GetHashCode() {
        return $this.ID.GetHashCode()
    }
    
    [string] ToString() {
        return $this.ID
    }
}
