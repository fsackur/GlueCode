Set-Location $PSScriptRoot
Import-Module .\LegacyNetAdapter


.\NVSPbind\nvspbind.exe /?

.\NVSPbind\nvspbind.exe





$PrimaryAdapter = Get-WmiAdapter -Primary | Add-AdapterMagic

$PrimaryAdapter.WmiAdapter.GUID

