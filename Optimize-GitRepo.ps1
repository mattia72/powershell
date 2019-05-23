[CmdletBinding()]
param (
  [Parameter(Position = 0, Mandatory = $false, ParameterSetName = "Path", ValueFromPipeline = $true)]
  [ValidateScript( { (Test-Path -Path $_) })]
  [String]$Path = (get-location).Path,
  [switch]$Recurse
)

Import-Module ${env:HOME}\dev\powershell\Modules\Get-DirectoryStats -Force

function Optimize-GitRepo {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateScript({((Test-Path -Path $_) -and ((Get-Item $_) -is [System.IO.DirectoryInfo]))})]
    [String]$Path = (get-location).Path,
    [switch]$Recurse
  )

  begin {
    $count = 0
    $sizeSumBefore = 0
    $sizeSumAfter = 0
  }

  process {
    Get-ChildItem -Path $Path -Filter ".git" -Recurse:$Recurse -Force -Attributes Directory |
    Where-Object {
      $count++
      $sizeBefore = Get-DirectoryStats -Directory $_.FullName
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
  Write-Host "$count directories optimized." -ForegroundColor Green
  Write-Host "Full size was $(Get-ByteSize -Size $sizeSumBefore )." -ForegroundColor Green
  Write-Host "Full size is  $(Get-ByteSize -Size $sizeSumAfter)." -ForegroundColor Green
  Write-Host "Reduced size  $(Get-ByteSize -Size ($sizeSumBefore - $sizeSumAfter))." -ForegroundColor Green
  }
}

#  Optimize-GitRepo -Path $(Join-Path $env:HOME "dev") -Recurse:$true | Format-Table -Property Path,SizeAfter,ReducedSize
# ($(12312*1024*1024*1024*1024), $(234*1024*1024*1024), 234234234234, 34445, 5) | Get-ByteSize
Optimize-GitRepo -Path $Path -Recurse:$Recurse | Format-Table -Property Path,SizeAfter,ReducedSize