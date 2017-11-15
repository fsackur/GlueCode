
function Write-Host {
    Write-Output "Write-host suppressed"
}

#$M = Import-Module .\Monolith.psm1 -PassThru

#Export-ModuleMember ([string[]]$M.ExportedFunctions.Keys) #-Variable ([string[]]$M.ExportedVariables.Keys)
