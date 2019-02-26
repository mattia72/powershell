
# . .\Copy-Images.
Import-Module -Name $PSScriptRoot\Copy-Images -AsCustomObject

$From = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
$To = "$env:USERPROFILE\Pictures\Windows Spotlight"

if (!(Test-Path -Path $To)) {
    New-Item -ItemType Directory -Force -Path $To
}

Copy-Images -Source $From -Destination $To -NewExtension "jpg" -FilterWidth 1920 -Verbose

#Get-ItemsOlderThan -Days 30 -Path $To | Remove-Item -Verbose 

# Access denied :(
#Get-ImageFile -path $To -FilterWidth 1080 | Select-Object Name,Width,Height
#Get-ImageFile -path $To -FilterWidth 1080 | ForEach-Object { Remove-Item $_.FullName -Verbose } 
#Get-ImageFile -path $To -FilterWidth 1080 | ForEach-Object { 
    # Write-Host "delete $($_.BaseName)"
    # (Get-Item $_.FullName).Delete() 
# } 
