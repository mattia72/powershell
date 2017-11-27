function Copy-NewerItem
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $True)]
        [ValidateScript( { ((Get-Item $_) -is [System.IO.FileInfo]) -and (Test-Path -Path $_) })]
        [String]$Source,
        [ValidateScript( { ((Get-Item $_) -is [System.IO.FileInfo]) -and (Test-Path -Path $_) })]
        [String]$Destination
    )
    
    begin
    {
    }
    
    process
    {
        if ( $Source.LastWriteTime -gt $Destination.LastWriteTime )
        {
            Copy-Item -Path $Source -Destination $Destination -Verbose -Whatif
        }
        else 
        {
            if ($Source.LastWriteTime -eq $Destination.LastWriteTime)
            {
                Write-Verbose "${Destination.Name} has the same WriteTime."
            }
            else 
            {
                Write-Warning "${Destination.Name} is newer!"
            }
        }
        
    }
    
    end
    {
    }
}
