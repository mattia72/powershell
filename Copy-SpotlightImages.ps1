$minImageCount = 20
$maxImageCount = 50
$maxImageSize = 50 * 1024 * 1024

# . .\Copy-Images.
Import-Module -Name $PSScriptRoot\Modules\Copy-Images -Force
Import-Module -Name $PSScriptRoot\Modules\Get-DirectoryStats -Force

$From = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
$FromBing = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Themes\CachedFiles\"
$To = "$env:USERPROFILE\Pictures\Windows Spotlight"

if (!(Test-Path -Path $To)) {
  New-Item -ItemType Directory -Force -Path $To
}

Copy-Images -Source $From -Destination $To -NewExtension "jpg" -FilterWidth 1920 -Verbose

$imgFiles = Get-ImageFiles -Path $FromBing  -FilterWidth 1920 
foreach ($imgFile in $imgFiles) {
  $destFile = Join-Path $To "$($imgFile.BaseName)_$($imgFile.DateCreated.ToString('yyyyMMddhhmmss')).jpg"
  Copy-Item -Path $imgFile.FullName -Destination $destFile
}

$imageDirStat = $(Get-DirectoryStats -Directory $To)
Write-Host "$To Count: $($imageDirStat.Count) Size: $(Get-ByteSize $($imageDirStat.Size))"

if ( $imageDirStat.Count -gt $maxImageCount -or $imageDirStat.Size -gt $maxImageSize) {
  $oldies = Get-ItemsOlderThan -Days 90 -Path $To  
  $oldiesCount = $($oldies | Measure-Object ).Count
  if ($imageDirStat.Count - $oldiesCount -gt $minImageCount ) {
    $oldies | Remove-Item -Verbose 
  }
}

