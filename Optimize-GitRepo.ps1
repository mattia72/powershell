[CmdletBinding()]
param (
  [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "Path", ValueFromPipeline = $true)]
  [ValidateScript( { (Test-Path -Path $_) })]
  [String]$Path = (get-location).Path,
  [switch]$Recurse
)

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
function Optimize-GitRepo {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateScript({((Test-Path -Path $_) -and ((Get-Item $_) -is [System.IO.DirectoryInfo]))})]
    [String]$Path = (get-location).Path,
    [switch]$Recurse
  )

  begin {
    function Get-DirectoryStats {
      param( $Directory, $Recurse)

      $files = $Directory | Get-ChildItem -Force -Recurse:$Recurse | Where-Object { -not $_.PSIsContainer }
      if ( $files ) {
        $output = $files | Measure-Object -Sum -Property Length | Select-Object `
        @{Name = "Path"; Expression = { $Directory.FullName } },
        @{Name = "Files"; Expression = { $_.Count; $script:totalcount += $_.Count } },
        @{Name = "Size"; Expression = { $_.Sum; $script:totalbytes += $_.Sum } }
      }
      else {
        $output = "" | Select-Object `
        @{Name = "Path"; Expression = { $Directory.FullName } },
        @{Name = "Files"; Expression = { 0 } },
        @{Name = "Size"; Expression = { 0 } }
      }
      $output
    }
    $count = 0
    $sizeSumBefore = 0
    $sizeSumAfter = 0
  }

  process {
    Get-ChildItem -Path $Path -Filter ".git" -Recurse:$Recurse -Force -Attributes Directory |
    Where-Object {
      $count++
      $sizeBefore = Get-DirectoryStats -Directory $_
      $sizeSumBefore += $sizeBefore.Size
      Push-Location -Path $_.Parent.FullName
      Write-Host "Optimizing $((Get-Location).Path) ..." -ForegroundColor Blue
      git reflog expire --all --expire=now
      git gc --prune=now --aggressiv
      Pop-Location
      $sizeAfter = Get-DirectoryStats -Directory $_
      $sizeSumAfter += $sizeAfter.Size
      $reducedSize = $sizeBefore.Size - $sizeAfter.Size
      Write-Host "Optimized by $(Get-ByteSize -Size $reducedSize)" -ForegroundColor Blue
      Select-Object `
        @{Name = "Path"; Expression = { $_.FullName } },
        @{Name = "SizeBefore"; Expression = { $sizeBefore } },
        @{Name = "SizeAfter"; Expression = {$sizeAfter} },
        @{Name = "ReducedSize"; Expression = {$reducedSize} }
    }
  }

  end {
  Write-Host "$count directories optimized by $(Get-ByteSize -Size ($sizeSumBefore - $sizeSumAfter))." -ForegroundColor Green
  }
}

# Optimize-GitRepo -Path $(Join-Path $env:HOME "dev") -Recurse:$true | Format-Table -Property Path,SizeAfter,ReducedSize
# ($(12312*1024*1024*1024*1024), $(234*1024*1024*1024), 234234234234, 34445, 5) | Get-ByteSize
Optimize-GitRepo -Path $Path -Recurse:$Recurse | Format-Table -Property Path,SizeAfter,ReducedSize