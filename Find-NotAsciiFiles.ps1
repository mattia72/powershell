[CmdletBinding()] 
Param (
    [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] 
    [string]$Path
)

$i = 0 
Get-ChildItem $Path -Include *.pas, *.dfm -Recurse | 
    ForEach-Object { 
        Write-Progress -Activity "Check Encoding" -PercentComplete $($i++ % 100) -Status "Path: $($_.FullName)"
        $_ } |
    Where-Object {
        $(.\Get-FileEncoding $_.FullName) -ne 'ascii'
    } | 
    Select-Object FullName, @{Name = 'Encoding'; Expression = { .\Get-FileEncoding $_.FullName } } |
    Tee-Object -Variable NonAsciiFiles | Out-Null

Write-Progress -Activity "Check Encoding" -Completed 

#Clear-Host
$NonAsciiFiles | Format-Table -AutoSize 
Write-Host "$($($NonAsciiFiles | Measure-Object).Count) from $i file found."

Clear-Variable NonAsciiFiles