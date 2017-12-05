
function Write-Host {
    Write-Output "Write-host suppressed by override in WrappedMonolith.psm1"
}

$M = Import-Module .\Monolith.psd1 -PassThru

#Export-ModuleMember ([string[]]$M.ExportedFunctions.Keys) -Variable ([string[]]$M.ExportedVariables.Keys)
