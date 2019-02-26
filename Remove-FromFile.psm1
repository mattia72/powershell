<#
.SYNOPSIS
  Helper functions for block searching replacing
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>

$global:BlockPattern = "(?smi){0}(?:(?!{0})[\s\S\r])*?{2}[\s\S\r]*?{1}"
function Remove-LinesFromFile {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    [ValidateScript( { (Test-Path -Path $_) })]
    $FilePath,
    [int[]] $lineNums
  )
  $content = Get-Content $FilePath
  $content | ForEach-Object {
    $count = 1 
    if ($lineNums.Contains($count++)) {
      $_
    }
  } | Set-Content -Path $FilePath -NoNewline 
}

function Remove-BlockFromFile {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    [ValidateScript( {(Test-Path -Path $_)})]
    $FilePath,
    $Begin,
    $End,
    $Contain
  )
  begin {
    $count = 0
  }
  process {
    Remove-BlockFromText -Text (Get-Content -Path $FilePath -Raw) -Begin $Begin -End $End -Contain $Contain | 
      Set-Content -Path $FilePath -NoNewline

    Write-Verbose "Block removed from $FilePath successfully." 
  }
  end{
    Write-Verbose "$count file(s) changed."
  }
}
function Select-TextContainsBlock {
  [cmdletbinding()]
  param(
    $Text,
    $Begin,
    $End,
    $Contain
  )

  if($Text -match $($global:BlockPattern -f $Begin,$End,$Contain)){
    $Text
  }
}
function Select-FileContentContainsBlock {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    [ValidateScript( {(Test-Path -Path $_)})]
    $FilePath,
    $Begin,
    $End,
    $Contain
  )
  process {
    $Text = Get-Content -Path $FilePath -Raw
    $Text | Where-Object {$_ -match $($global:BlockPattern -f $Begin,$End,$Contain)}
  }
}

function Remove-BlockFromText {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    [string]$Text,
    $Begin,
    $End,
    $Contain,
    [switch] $FirstOnly
  )

  if ($FirstOnly) {
    $Text -replace $($global:BlockPattern -f $Begin,"${End}(?<AfterBlock>.*)",$Contain), '${AfterBlock}'
  }
  else{
    $Text -replace $($global:BlockPattern -f $Begin, $End, $Contain), ''
  }
}

Export-ModuleMember -Function Remove-BlockFromText, Remove-BlockFromFile, Remove-LinesFromFile, Select-TextContainsBlock, Select-FileContentContainsBlock