
<# 
    .SYNOPSIS
        Asks for closing a process
    .DESCRIPTION
        Asks for closing a process
    .EXAMPLE
        PS C:\> @("process1","process2","process3") | Stop-ProcessMessageBox
        If process runs it asks for closing it, else does nothing
    .INPUTS
        Name of a process
    .OUTPUTS
        Nothing
    .NOTES
        General notes
#>

. ./Show-MessageBox

function Stop-ProcessMessageBox 
{


    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        $Name
    )
    
    begin {
    }
    
    process {
        try {
            $path = Get-Process -name $Name -ErrorAction Stop | Select-Object -ExpandProperty Path 
        }
        catch {
            return
        }
        $answer = Show-MessageBox -YesNo -Question -TopMost -Title "Stop Process" -Msg "$($path)`r`nDo you want to stop the process(es) above?"
        if ($answer -eq "Yes")
        {
            stop-process -name  $Name
        }
    }
    
    end {
    }
}
