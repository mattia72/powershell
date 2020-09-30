[CmdletBinding()] 
Param (
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] 
    [string]$Path
)

$i = 0 
$lf = $false
$cr = $false
Get-ChildItem $Path -Include *.pas, *.dfm -Recurse | 
    ForEach-Object { 
        Write-Progress -Activity "Check End of Lines" -PercentComplete $($i++ % 100) -Status "Path: $($_.FullName)"
        $_ } |
    Where-Object {
      $content = $(Get-Content $_.FullName -Raw)
      $lf = $content -match '[^\r]\n' 
      $cr = $content -match '\r[^\n]'
      $lf -or $cr
    } | 
    Select-Object FullName, @{Name = 'EOL'; Expression = {if ($lf) {'LF'} elseif ($cr) {'CR'} else {'??'}}} |
    Tee-Object -Variable FilesWithInvalidEOL | Out-Null

Write-Progress -Activity "Check Encoding" -Completed 

#Clear-Host
$FilesWithInvalidEOL | Format-Table -AutoSize 
Write-Host "$($($FilesWithInvalidEOL | Measure-Object).Count) from $i file found."
Clear-Variable FilesWithInvalidEOL