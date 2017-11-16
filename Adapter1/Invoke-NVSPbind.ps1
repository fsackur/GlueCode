<#

    .LINK
    https://gallery.technet.microsoft.com/Hyper-V-Network-VSP-Bind-cf937850

    .LINK
    https://blogs.technet.microsoft.com/jhoward/2010/01/25/announcing-nvspbind/

    .NOTES
    Throws exceptions with text:
        "Not found" if a specifed adapter is not found in the system
        "Access denied" if the code is run wihtout administrative privileges
#>

[CmdletBinding(DefaultParameterSetName='List')]
[OutputType(ParameterSetName='List', [PSObject[]])]
[OutputType(ParameterSetName='MoveToTop', [void])]

param (
    [Parameter(ParameterSetName='List')]
    [switch]$List,

    [Parameter(ParameterSetName='MoveToTop')]
    [switch]$MoveToTop,

    [Parameter(ParameterSetName='MoveToTop', Mandatory=$true)]
    [guid]$AdapterGuid
)

