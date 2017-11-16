using module .\Info.Class.psm1  #this is relative path from current module, not from PWD
using namespace Info
using namespace System.Management.Automation
using namespace System.Collections.Generic


$DeviceTTL = 7200  #seconds before a device cache entry expires
$AccountTTL = 86400  #seconds before an account cache entry expires


class DEntry {
    DEntry ([DeviceInfo]$DeviceInfo) {
        $this.DeviceInfo = $DeviceInfo
        $this.RefreshTime = [datetime]::Now
    }
    [DeviceInfo]$DeviceInfo
    [DateTime]$RefreshTime
    [bool] IsExpired () {
        return $this.RefreshTime.AddSeconds($Script:DeviceTTL) -lt [datetime]::Now
    }
}

class AEntry {
    AEntry ([AccountInfo]$AccountInfo) {
        $this.AccountInfo = $AccountInfo
        $this.RefreshTime = [datetime]::Now
    }
    [AccountInfo]$AccountInfo
    [DateTime]$RefreshTime
    [bool] IsExpired () {
        return $this.RefreshTime.AddSeconds($Script:AccountTTL) -lt [datetime]::Now
    }
}

class Cache {
    
    #Singleton
    #hidden Cache () {}

    static [Cache] GetInstance() {
        if ([Cache]::Instance -eq $null) {[Cache]::Instance = [Cache]::new()}
        return [Cache]::Instance
    }

    hidden static [Cache]$Instance

    [IDictionary[DeviceID, DEntry]]$DeviceCache = [Dictionary[DeviceID, DEntry]]::New()
    [IDictionary[AccountID, AEntry]]$AccountCache = [Dictionary[AccountID, AEntry]]::New()
    [IDictionary[DeviceID, DEntry]]$InvalidDeviceCache = [Dictionary[DeviceID, DEntry]]::New()   #To cache ObjectNotFound. Anything in here does not exist.
    [IDictionary[AccountID, AEntry]]$InvalidAccountCache = [Dictionary[AccountID, AEntry]]::New()
    

    [DeviceInfo] ReadDevice ([DeviceID]$ID) {
        #Pass by ref - $Value gets assigned if found in cache
        [DEntry]$Value = $null
        $CacheHit = $this.DeviceCache.TryGetValue($ID, [ref]$Value)

        if ($CacheHit) {
            if ($Value.IsExpired()) {
                Write-Verbose "Cache expired: $ID"
                return $null
            } else {
                Write-Verbose "Cache hit: $ID"
                return $Value.DeviceInfo
            }
        } else {
            Write-Verbose "Cache miss: $ID"
            return $null
        }
    }

    [DeviceInfo] ReadDevice ([DeviceID]$ID, [Action[ErrorRecord, ref]]$ErrorCallback) {
        if ($this.InvalidDeviceCache.ContainsKey($ID)) {
            Write-Verbose "Invalid-cache hit: $ID"
            $ErrorCallback.Invoke((New-Error ObjectNotFound $ID), [ref]$null)
            return $null
        }
        return $this.ReadDevice($ID)
    }

    PurgeDevice ([DeviceID]$ID) {
        $CacheHit = $this.DeviceCache.Remove($ID)
        if ($CacheHit) {
            Write-Verbose "Cache hit (purge): $ID"
        } else {
            Write-Verbose "Cache miss (purge): $ID"
        }
    }

    WriteDevice ([DeviceInfo]$DeviceInfo) {
        $ID = $DeviceInfo.ID
        $this.DeviceCache[$ID] = [DEntry]::New($DeviceInfo)
        Write-Verbose "Cache write: $ID"
    }

    #Remember when a device does not exist, so we don't keep querying the DB for it
    WriteInvalidDevice ([DeviceID]$DeviceID) {
        $this.InvalidDeviceCache[$DeviceID] = [DEntry]::New([DeviceInfo]$DeviceID)
        Write-Verbose "Invalid-cache write: $DeviceID"
    }


    [AccountInfo] ReadAccount ([AccountID]$ID) {
        #Pass by ref - $Value gets assigned if found in cache
        [AEntry]$Value = $null
        $CacheHit = $this.AccountCache.TryGetValue($ID, [ref]$Value)

        if ($CacheHit) {
            if ($Value.IsExpired()) {
                Write-Verbose "Cache expired: $ID"
                return $null
            } else {
                Write-Verbose "Cache hit: $ID"
                return $Value.AccountInfo
            }
        } else {
            Write-Verbose "Cache miss: $ID"
            return $null
        }
    }

    [AccountInfo] ReadAccount ([AccountID]$ID, [Action[ErrorRecord, ref]]$ErrorCallback) {
        if ($this.InvalidAccountCache.ContainsKey($ID)) {
            Write-Verbose "Invalid-cache hit: $ID"
            $ErrorCallback.Invoke((New-Error ObjectNotFound $ID), [ref]$null)
            return $null
        }
        return $this.ReadAccount($ID)
    }

    PurgeAccount ([AccountID]$ID) {
        $CacheHit = $this.AccountCache.Remove($ID)
        if ($CacheHit) {
            Write-Verbose "Cache hit (purge): $ID"
        } else {
            Write-Verbose "Cache miss (purge): $ID"
        }
    }

    WriteAccount ([AccountInfo]$AccountInfo) {
        $ID = $AccountInfo.ID
        $this.AccountCache[$ID] = [AEntry]::New($AccountInfo)
        Write-Verbose "Cache write: $ID"
    }

    #Remember when an account does not exist, so we don't keep querying the DB for it
    WriteInvalidAccount ([AccountID]$AccountID) {
        $this.InvalidAccountCache[$AccountID] = [AEntry]::New([AccountInfo]$AccountID)
        Write-Verbose "Invalid-cache write: $AccountID"
    }
}