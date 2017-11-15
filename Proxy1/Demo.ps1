#$PSModuleAutoLoadingPreference = $null #'none'



#region 1
cls

Import-Module .\Monolith.psd1 -Force -ErrorAction Stop
Write-SplashScreen


#endregion 1







#region 2
#We want to suppress the host output without editing Monolith.psm1.
cls


Import-Module .\Monolith.psd1 -Force -ErrorAction Stop
function Write-Host {}
Write-SplashScreen
Remove-Item Function:\Write-Host



#endregion 2







#region 3
#We want to suppress the splash output but send the red host output to stdout
cls

#Install-Module MetaProgramming -Scope CurrentUser
#New-ProxyCommand Write-Host


function Write-Host {
    [CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkID=113426', RemotingCapability='None')]
    param(
        [System.ConsoleColor]
        ${ForegroundColor},

        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        [System.Object]
        ${Object},

        [switch]
        ${NoNewline},

        [System.Object]
        ${Separator},

        [System.ConsoleColor]
        ${BackgroundColor}
    )

    if ($ForegroundColor -ne [ConsoleColor]::Yellow) {
        Write-Output $Object
    }
}

Write-SplashScreen
Remove-Item Function:\Write-Host


#endregion 3








#region 4
#Does not achieve the desired result
cls


Remove-Module *Monolith -ErrorAction Ignore
Import-Module .\WrappedMonolith.psm1 -Force -ErrorAction Stop
Write-SplashScreen
Write-Host "Write-Host still works!" -ForegroundColor Magenta


#endregion 4






#region 5
#Does achieve the desired result - suboptimally
cls


function Write-Host {
    [CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkID=113426', RemotingCapability='None')]
    param(
        [System.ConsoleColor]
        ${ForegroundColor},

        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        [System.Object]
        ${Object},

        [switch]
        ${NoNewline},

        [System.Object]
        ${Separator},

        [System.ConsoleColor]
        ${BackgroundColor}
    )

    if ($PSCmdlet.SessionState.Module.Name -eq 'Monolith') {
        if ($ForegroundColor -ne [ConsoleColor]::Yellow) {
            Write-Output $Object
        }
    } else {
        Microsoft.PowerShell.Utility\Write-Host @PSBoundParameters
    }
}


Write-SplashScreen

Write-Host "Write-Host still works!" -ForegroundColor Magenta


Remove-Item Function:\Write-Host
#endregion 5





#region 6
#Achieves the desired result - by injecting code only where it is required
cls


Import-Module .\Monolith.psd1 -Force -ErrorAction Stop
& (Get-Module Monolith) {Import-Module .\NestedModule.psm1}

Write-SplashScreen
Write-Host "Write-Host still works!" -ForegroundColor Magenta


#endregion 6




###########################################################################




#region 7
cls

$Module = Import-Module .\Monolith.psd1 -Force -ErrorAction Stop -PassThru

Invoke-ComplexFunction -foo 1 -bar 2 -Verbose

gci *.log

#endregion 7




#region 8
cls


Remove-Item *.log
$Module = Import-Module .\Monolith.psd1 -Force -ErrorAction Stop -PassThru
& $Module {Import-Module .\NestedModule.psm1 -Force}

Invoke-ComplexFunction -foo 1 -bar 2 -Verbose

gci *.log





$env:LogPath = Join-Path $PWD 'GlueCode.log'
Invoke-ComplexFunction -foo 1 -bar 2 -Verbose
Get-Content $env:LogPath




Remove-Item *.log
$env:LogPath = $null
#endregion 8



