$Dir1 ="d:\home\TEMP\POR\added2.txt"
$Dir2 ="d:/home/TEMP/POR"

function Test-Diff($Dir1,$Dir2)
{
$fileList1 = Get-ChildItem $Dir1 -Recurse | Where-Object {!$_.PsIsContainer} | Get-Item | Sort-Object -Property Name
$fileList2 = Get-ChildItem $Dir2 -Recurse | Where-Object {!$_.PsIsContainer} | Get-Item | Sort-Object -Property Name

if( $fileList1.Count -ne $fileList2.Count )
{
    Write-Host "Following files are different:"
    Compare-Object -ReferenceObject $fileList1 -DifferenceObject $fileList2 -Property Name -PassThru | Format-Table FullName
    return $false
}
return $true
}

function Test-FileInSubPath([System.IO.DirectoryInfo]$Dir,[System.IO.FileInfo]$File)
{
	$File.FullName.StartsWith($Dir.FullName)
}

Test-FileInSubPath $Dir2 $Dir1 
#Test-Diff $Dir1 $Dir2
if($?) 
{ 
    Write-Output "Test OK" 
}
else
{ 
    Write-Host "Test FAILED" -BackgroundColor Red
}