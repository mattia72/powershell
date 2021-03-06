
$TempFolder = ""

function New-TempFolder()
{
    $Guid = [System.Guid]::NewGuid().ToString()
    $global:TempFolder = $(Join-Path $env:TEMP $Guid)
    New-Item -Type Directory -Path $global:TempFolder
    return $global:TempFolder
}

function Remove-TempFolder()
{
    Push-Location $global:TempFolder
    Remove-Item '*.*' -Recurse -Force 
    Pop-Location
    Remove-Item $global:TempFolder
}

Export-ModuleMember -Function New-TempFolder, Remove-TempFolder