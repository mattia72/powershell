$TortoisProcPath = "TortoiseProc.exe"


Import-Module $PSScriptRoot\Show-MessageBox

function Show-TortoiseSVNDialog
{
  <#
    .SYNOPSIS
    Opens TortoiseSVN commit dialog
    
    .DESCRIPTION
    Opens TortoiseSVN commit dialog with given directories or files. 
    
    .PARAMETER PathList
    Array of files or directories
    
    .PARAMETER Separate
    If the given files are in different repos, you can handle them separate

    .PARAMETER ShowNoChangeMsgBox
    If there is no change to commit, then a msgbox will be shown
    
    .PARAMETER ShowConfirmationMsgBox
    show confirmation msg box before each dialog

    .EXAMPLE
    @("full\path1", "full\path2") | Show-TortoiseSVNDialog -Command commit  
    
    .NOTES
    v2.0 Log support
    v1.0 Initial version
    #>

  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [ValidateScript( { $_ | ForEach-Object {Test-Path -Path $_}})]
    [String[]]$PathList,
    [Parameter(Mandatory = $True)] [ValidateSet('commit', 'log')] [String]$Command,
    [Parameter(Mandatory = $False)] [switch]$Separate = $False,
    [Parameter(Mandatory = $False)] [switch]$ShowNoChangeMsgBox = $False,
    [Parameter(Mandatory = $False)] [switch]$ShowConfirmationMsgBox = $False
  )
    
  begin
  {
    $CommitPathString = ""
  }

  process
  {
    foreach ($path in $PathList)
    {
      if ($Separate)
      {
        switch ($Command)
        {
          'commit'
          {  
            $modified = $(Test-Modified($path))

            if ($ShowConfirmationMsgBox)
            {
              $a = Show-MessageBox -YesNo -Question -Msg "Show commit dialog for ${path}?" -Title "SVN Commit" 
            }

            if ($modified -and ((-not $ShowConfirmationMsgBox) -or $a -eq 'Yes'))
            {
              & $TortoisProcPath /command:$Command /path:$path
            }

            if ((-not $modified) -and $ShowNoChangeMsgBox)
            {
              Show-MessageBox -Msg "$path has no changes." -Title "SVN status" -Information | Out-Null
            }
          }
          'log'
          {
            if ($ShowConfirmationMsgBox)
            {
              $a = Show-MessageBox -YesNo -Question -Msg "Show log of ${path}?" -Title "SVN Log" 
            }
            if ((-not $ShowConfirmationMsgBox) -or $a -eq 'Yes')
            {
              & $TortoisProcPath /command:$Command /path:$path
            }
          }
          Default {}
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
      $pathes = $CommitPathString.Replace('*', ' ')
      $modified = $(Test-Modified($pathes))
      if ($ShowConfirmationMsgBox)
      {
        $a = Show-MessageBox -YesNo -Question -Msg "Show commit dialog for the following pathes`n$($CommitPathString.Replace('*', ', '))?" -Title "SVN Commit" 
      }
      
      if ((-not $ShowConfirmationMsgBox) -or $a -eq 'Yes')
      {
        # & "C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe" /command:commit /pathfile:$tempFile #/deletepathfile 
        & $TortoisProcPath /command:$Command /path:$CommitPathString /closeonend:3
      }
      if ((-not $modified) -and $ShowNoChangeMsgBox)
      {
        Show-MessageBox -Msg "$path has no changes." -Title "SVN status" -Information | Out-Null
      }
    }

  }
}

function Test-Modified ($path)
{
  Push-Location
  $changedFiles = svn status -q $path
  return $changedFiles -ne $null
}

Export-ModuleMember -Function Show-TortoiseSVNDialog, Test-Modified