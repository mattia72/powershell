$TortoisProcPath = "TortoiseProc.exe"

Import-Module $PSScriptRoot\Show-MessageBox

function Show-SVNCommitDialog
{
    <#
    .SYNOPSIS
    Opens TortoiseSVN commit dialog
    
    .DESCRIPTION
    Opens TortoiseSVN commit dialog with given directories or files. 
    
    .PARAMETER CommitPathList
    Array of files or directories
    
    .PARAMETER Separate
    If the given files are in different repos, you can handle them separate

    .PARAMETER ShowNoChangeMsgBox
    If there is no change to commit, then a msgbox will be shown
    
    .EXAMPLE
    @("full\path1", "full\path2") | Show-SVNCommitDialog  
    
    .NOTES
    v1.0 Initial version
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [ValidateScript( { $_ | ForEach-Object {Test-Path -Path $_}})]
        [String[]]$CommitPathList,
        [Parameter(Mandatory = $False)]
        [switch]$Separate = $False,
        [Parameter(Mandatory = $False)]
        [switch]$ShowNoChangeMsgBox = $False
    )
    
    begin
    {
        $CommitPathString = ""
    }

    process
    {
        foreach ($path in $CommitPathList)
        {
            if ($Separate)
            {
                if ($(Get-Item $path).PSIsContainer -and $(Test-Modified($path)))
                {
                    & $TortoisProcPath /command:commit /path:$path
                }
                elseif ($ShowNoChangeMsgBox)
                {
                    Show-MessageBox -Msg "$path has no changes." -Title "SVN status" -Information | Out-Null
                }
            }
            else
            {
                $CommitPathString = "$($path)*$($CommitPathString)"
                
            }
        }
    }

    end
    {
        if (-not $Separate)  
        {
            $CommitPathString = $CommitPathString.Substring(0, $commitPathString.Length - 1)
            # & "C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe" /command:commit /pathfile:$tempFile #/deletepathfile 
            & $TortoisProcPath /command:commit /path:$CommitPathString /closeonend:3
        }

    }
}

function Test-Modified ($path)
{
    Push-Location
    Set-Location $path
    $changedFiles = svn status -q
    Pop-Location
    return $changedFiles -ne $null
}

Export-ModuleMember -Function Show-SVNCommitDialog, Test-Modified