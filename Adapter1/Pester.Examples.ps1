
#region Mocking out external commands


Mock Invoke-Expression -ParameterFilter {$Command -match 'nvspbind'} -MockWith {
    $Tokens = $Command -split '\s+'

    if (
        ($Tokens[1] -match '^(/|-)n$') -and
        ($Tokens[2] -match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
    ) {
        return "The command completed successfully."
    } else {
        return "Invalid syntax"
    }
}


#endregion Mocking out external commands




#region Mocking out WMI


Mock Get-WmiObject -ParameterFilter {$Class -eq 'Win32_NetworkAdapter'} -MockWith {
    $MockObj = new-object PSObject -Property @{
        GUID = New-Guid
        Index = 99
    }


}




Mock Get-WmiObject -ParameterFilter {$Class -eq 'Win32_NetworkAdapterConfiguration'} -MockWith {
    $MockObj = new-object PSObject -Property @{
        IPAddress = [string[]](,"127.0.0.1")
        IPSubnet =  [string[]](,"255.0.0.0")
    }

    #https://msdn.microsoft.com/en-us/library/aa393295(v=vs.85).aspx
    $MockObj | Add-Member -MemberType ScriptMethod -Name SetDNSServerSearchOrder -Value {
        param([string[]]$DNSServerSearchOrder)

        return 0
    }
}


#endregion Mocking out WMI
