function Clean-GitRepo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { (Test-Path -Path $_) })]
        [String]$Path
    )
    
    begin {
    }
    
    process {
    }
    
    end {
    }
}