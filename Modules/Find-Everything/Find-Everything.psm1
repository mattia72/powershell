function Find-Files {
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, 
      HelpMessage = "Source path directory")]
    [string] $Path,
    [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true, 
      HelpMessage = "File name or part of file name, wildcards are not supported")]
    [string] $FileName,
    [switch] $UseEverything = $false
  )
  
  # use everything for search if exists in the path
  $EverythingFound = $(Get-Command "es.exe" -ErrorAction SilentlyContinue)
  
  if ($UseEverything -and -not $EverythingFound) {
    Write-Warning "Everything executable not found in the path." 
  }
  
  if ($UseEverything -and $EverythingFound) {
    Write-Verbose "File search performed by everything"
    es.exe -path $Path $FileName | Get-Item
  }
  else {
    Write-Verbose "File search performed by powershell"
    Get-ChildItem -Recurse -Path $Path -Include ("*$FileName*") #| Sort-Object -Property LastWriteTime -Descending
  }
}

Export-ModuleMember -Function Find-Files