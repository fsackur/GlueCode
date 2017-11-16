Set-Location $PSScriptRoot
Import-Module .\LegacyNetAdapter
return




$PrimaryAdapter = Get-WmiAdapter -Primary | Add-AdapterMagic

$PrimaryAdapter.WmiAdapter.GUID





.\NVSPbind\nvspbind.exe /?

.\NVSPbind\nvspbind.exe





#This is what we will aim for
Invoke-NVSPbind -MoveToTop -AdapterGuid $PrimaryAdapter.WmiAdapter.GUID
