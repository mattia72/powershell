
function Get-ByteSize{
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
    $Size
  )
  process {
    if( ($Size / 1TB) -gt 0.9)     { "$("{0:n2}" -f ($Size / 1TB)) TB" }
    elseif( ($Size / 1GB) -gt 0.9) { "$("{0:n2}" -f ($Size / 1GB)) GB" }
    elseif( ($Size / 1MB) -gt 0.9) { "$("{0:n2}" -f ($Size / 1MB)) MB" }
    elseif( ($Size / 1KB) -gt 0.9) { "$("{0:n2}" -f ($Size / 1KB)) KB" }
    else { "$Size B" }
  }
}

function Get-DirectoryStats {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "Path", ValueFromPipeline = $true)]
    [ValidateScript( { (Test-Path -Path $_) })]
    [String]$Directory = (get-location).Path,
    [switch]$Recurse
  )

  process {
    $files = $Directory | Get-ChildItem -Force -Recurse:$Recurse | Where-Object { -not $_.PSIsContainer }
    if ( $files ) {
      $output = $files | Measure-Object -Sum -Property Length | Select-Object `
      @{Name = "Path"; Expression = { $Directory } },
      @{Name = "Files"; Expression = { $_.Count; $script:totalcount += $_.Count } },
      @{Name = "Size"; Expression = { $_.Sum; $script:totalbytes += $_.Sum } }
    }
    else {
      $output = "" | Select-Object `
      @{Name = "Path"; Expression = { $Directory } },
      @{Name = "Files"; Expression = { 0 } },
      @{Name = "Size"; Expression = { 0 } }
    }
    $output
  }
}

Export-ModuleMember -Function Get-DirectoryStats, Get-Bytesize