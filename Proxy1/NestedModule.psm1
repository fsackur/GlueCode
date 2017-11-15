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

    if ($ForegroundColor -eq [ConsoleColor]::Yellow) {
        Write-Information "Output suppressed" -InformationAction Continue
    } else {
        Write-Output $Object
    }
}


function Write-Verbose {
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Verbose
    .ForwardHelpCategory Cmdlet

    #>
    [CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkID=113429', RemotingCapability='None')]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [string]
        ${Message}
    )

    begin
    {
        #https://blogs.technet.microsoft.com/heyscriptingguy/2014/04/26/weekend-scripter-access-powershell-preference-variables/
        $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')


        #region Added functionality
        if ($env:LogPath) {
            $LogLine = "{0,-20:s} {1,-12} {2}" -f (
                (Get-Date),
                "Verbose",
                $Message
            )
            $LogLine | Out-File $env:LogPath -Append
        }
        #endregion Added functionality


        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Verbose', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }

}
