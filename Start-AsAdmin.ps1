<#
.SYNOPSIS
  Start command as admin
.DESCRIPTION
  Start command as admin in a separate powershell window
.EXAMPLE
  PS C:\> Start-AsAdmin -Command "cd $env:home; dir" -WaitInTheEnd
  List directories as admin in HOME Directory, don't close wondow automatically

  PS C:\> "cd $env:home; dir" | Start-AsAdmin  -WaitInTheEnd
  List directories as admin in HOME Directory, don't close wondow automatically
  
.INPUTS
  Command with parameters between apostrophes
.OUTPUTS
  n.a.
.NOTES
  General notes
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline= $true, HelpMessage = "Command with parameters")]
    [string] $Command,
    [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline= $true, HelpMessage = "Don't close window automatically")]
    [switch] $WaitInTheEnd = $false
)

$commandText = $Command
if ($WaitInTheEnd) {
  $commandText = "$Command; Read-Host -Prompt `'Press Enter to continue`'"
}

Start-Process powershell -Verb RunAs -ArgumentList ("-Command `"$commandText`"") 