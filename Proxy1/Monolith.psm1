#region Monolith.psm1


function Write-SplashScreen {

    Write-Host -ForegroundColor Yellow @'
 _____       _           _     _ 
/  ___|     | |         | |   | |
\ `--. _ __ | | __ _ ___| |__ | |
 `--. \ '_ \| |/ _` / __| '_ \| |
/\__/ / |_) | | (_| \__ \ | | |_|
\____/| .__/|_|\__,_|___/_| |_(_)
      | |                        
      |_|                     
'@
    
    Write-Host -ForegroundColor Red (
        "$($ExecutionContext.SessionState.Module.Name) module, version $($ExecutionContext.SessionState.Module.Version)"
    )
}








function Invoke-ComplexFunction {
    [CmdletBinding()]
    param (
        $foo,
        $bar
    )

    Write-Verbose "foo is: $foo"
    Write-Verbose "bar is: $bar"

    Write-Debug "Entering some arcane code"

    Write-Output "All finished"

}


#endregion Monolith.psm1