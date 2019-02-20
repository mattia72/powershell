
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
}
function Remove-BlockFromText {
  param(
    $Text,
    $Begin,
    $End,
    $Contain
  )

  $pattern = "(?smi)$Begin(?:(?!$Begin)[\s\S\r])*?$Contain[\s\S\r]*?$End"
  $Text -replace $Pattern, ''
}