function Find-WithEverything {
  [CmdletBinding()]
  param (
    [Parameter()]
    [string] $SearchPattern,
    [switch] $MatchFullName,
    [switch] $UseRegex
  )

  # use everything for search if exists in the path
  $EverythingFound = $(Get-Command "es.exe" -ErrorAction SilentlyContinue)

  if (-not $EverythingFound) {
    Write-Error "Everything executable not found in the path." 
    exit
  }
  
  Write-Verbose "File search performed by everything"
  # https://www.voidtools.com/support/everything/searching/
  if ($MatchFullName) { 
    $SearchPattern = "wholefilename:$SearchPattern" 
  } 
  if ($UseRegex) {
    $SearchPattern = "regex:$SearchPattern" 
  }
  es.exe -path $Path "$SearchPattern" | Get-Item
}
function Find-Files {
  param (
    [CmdletBinding()]
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, 
      HelpMessage = "Source path directory")]
    [string] $Path,
    [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true, 
      HelpMessage = "File name or part of file name, wildcards are not supported")]
    [string] $SearchPattern,
    [switch] $MatchFullName,
    [switch] $UseRegex,
    [switch] $UseEverything
  )
  
  
  if ($UseEverything ) {
    Find-WithEverything -SearchPattern $SearchPattern -MatchFullName:$MatchFullName -UseRegex:$UseRegex
  }
  else {
    Write-Verbose "File search performed by powershell"

    if ($UseRegex) {
      if ($MatchFullName) { 
        Get-ChildItem -Recurse -Path $Path | Where-Object { $_.Name -match $SearchPattern }
      }
      else {
        Get-ChildItem -Recurse -Path $Path | Where-Object { $_.FullName -match $SearchPattern }
      }
    }
    else {
      if ($MatchFullName) { 
        Get-ChildItem -Recurse -Path $Path -Include ("$SearchPattern") 
      }
      else {
        Get-ChildItem -Recurse -Path $Path -Include ("*$SearchPattern*") 
        
      }
    }
  }
}

Export-ModuleMember -Function Find-Files, Find-WithEverything