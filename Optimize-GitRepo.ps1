[CmdletBinding()]
param (
  [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "Path", ValueFromPipeline = $true)]
  [ValidateScript( { (Test-Path -Path $_) })]
  [String]$Path = (get-location).Path,
  [switch]$Recurse
)
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
      Write-Host "Optimizing $((Get-Location).Path) ..." 
      git reflog expire --all --expire=now
      git gc --prune=now --aggressiv
      Pop-Location
      $sizeAfter = Get-DirectoryStats -Directory $_
      $sizeSumAfter += $sizeAfter.Size
      $reducedSize = $sizeBefore.Size - $sizeAfter.Size
      Write-Host "Optimized by $($reducedSize/1MB) MB." 
      Select-Object `
        @{Name = "Path"; Expression = { $_.FullName } },
        @{Name = "SizeBefore"; Expression = { $sizeBefore } },
        @{Name = "SizeAfter"; Expression = {$sizeAfter} },
        @{Name = "ReducedSize"; Expression = {$reducedSize} }
    }
  }
    
  end {
    Write-Host "$count directories optimized by $(($sizeSumBefore - $sizeSumAfter)/1MB) MB"
  }
}

# Optimize-GitRepo -Path $(Join-Path $env:HOME "dev") -Recurse:$true | Format-Table -Property Path,SizeAfter,ReducedSize
Optimize-GitRepo -Path $Path -Recurse:$Recurse | Format-Table -Property Path,SizeAfter,ReducedSize