
function Remove-LinesFromFile {
  param(
    $File,
    [int[]] $lineNums
  )
  $content = Get-Content $File
  $content | ForEach-Object {
    $count = 1 
    if ($lineNums.Contains($count++)) {
      $_
    }
  } | Set-Content -Path $File -NoNewline 
}

function Remove-BlockFromFile {
  param(
    $File,
    $Begin,
    $End,
    $Contain
  )

  Remove-BlockFromText -Text (Get-Content -Path $File -Raw) -Begin $Begin -End $End -Contain $Contain | 
    Set-Content -Path $File -NoNewline

  Write-Verbose "$File changed." 
}

$global:BlockPattern = "(?smi){0}(?:(?!{0})[\s\S\r])*?{2}[\s\S\r]*?{1}"
function Remove-BlockFromText {
  param(
    $Text,
    $Begin,
    $End,
    $Contain
  )

  $Text -replace $($global:BlockPattern -f $Begin,$End,$Contain), ''
}