<#
.SYNOPSIS
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>
[CmdletBinding(DefaultParameterSetName = "User")]
param (
  [parameter(Position = 0, Mandatory = $false, ParameterSetName = "User", HelpMessage = "reg file => reg key hashtable")]
  [hashtable[]] $BackupRegFileKeyHash
)
begin {
  # reg files can be imported by 
  # > reg import <file>.reg
  $cmd = {} 
  foreach ($regFileName in $BackupRegFileKeyHash.Keys) {
    $regKey = $BackupRegFileKeyHash."$regFileName"
    $cmd += "reg export `"$regKey`" `"$regFileName`"" 
  }
}
end {
  $cmds = $($cmd -join "`r`n")
  "Write-Host $cmds`r`n$cmds" | .\Start-AsAdmin.ps1 -WaitInTheEnd
}