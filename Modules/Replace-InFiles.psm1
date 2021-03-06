function Get-ReplaceMatches() {
    [CmdletBinding()]
    param (
        [System.Array]$content,
        [string]$original,
        [string]$replace
    )

    $count=0
    foreach ($line in $content) {
        if ($line -match $original) {
            $count++
            [PSCustomObject]@{
                Match = $line
                Count = $count
                ReplaceText = $line -replace $original, $replace
            }
        }
    }
    if ($count -eq 0){
            [PSCustomObject]@{
                Match = ""
                Count = $count
                ReplaceText = ""
            }
    }
}
function Set-ReplacedTextContent() {
    [CmdletBinding()]
    param (
        [parameter( Mandatory, ParameterSetName  = 'Path', Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,
        [parameter( Mandatory, ParameterSetName = 'LiteralPath', Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]]$LiteralPath,
        [parameter( Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $OriginalText,
        [parameter( Mandatory, Position = 2, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $SubstituteText,
        [parameter( Mandatory, Position = 3, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String] $OutputFilePath
    )
    begin {
        # $enc = New-Object System.Text.UTF8Encoding($true)
    }
    process {
        # Resolve path(s)
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $resolvedPaths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
        } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            $resolvedPaths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
        }
        foreach ($item in $resolvedPaths) {
            $file=Get-Item -LiteralPath $item

            $content = Get-Content $file.FullName
            $matches = Get-ReplaceMatches $content $OriginalText $SubstituteText

            foreach ($match in  $matches) {
                [PSCustomObject]@{
                    Path = $file.Name
                    Count = $match.Count
                    OldContent = $match.Match
                    NewContent = $match.ReplaceText
                }
            }
            if ($matches.Count -gt 0) {
                $content | ForEach-Object {$_ -replace $OriginalText, $SubstituteText} | Set-Content -path $OutputFilePath -Encoding UTF8
            }
        }
    }
}
Export-ModuleMember -Function Set-ReplacedTextContent, Get-ReplaceMatches 