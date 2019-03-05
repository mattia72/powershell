$fgColors = @(
  "Black",
  "DarkBlue",
  "DarkGreen",
  "DarkCyan",
  "DarkRed",
  "DarkMagenta",
  "DarkYellow",
  "Gray",
  "DarkGray",
  "Blue",
  "Green",
  "Cyan",
  "Red",
  "Magenta",
  "Yellow",
  "White"
)
$bgColors = @(
  "Black",
  "DarkBlue",
  "DarkGreen",
  "DarkCyan",
  "DarkRed",
  "DarkMagenta",
  "DarkYellow",
  "Gray",
  "DarkGray",
  "Blue",
  "Green",
  "Cyan",
  "Red",
  "Magenta",
  "Yellow",
  "White"
)

Write-Host $("{0,13} |" -f "Backgr/Foregr") -NoNewline
foreach ($fgColor in $fgColors) {
  Write-Host "$fgColor " -NoNewline
}
Write-Host "`n---------------------------------------------------------------------------------------------------------------------------------------"
foreach ($bgColor in $bgColors) { 
  Write-Host $("{0,13} |" -f $bgColor) -NoNewline
  foreach ($fgColor in $fgColors) {
    Write-Host "$fgColor " -ForegroundColor $fgColor -BackgroundColor $bgColor -NoNewline
  }
  Write-Host 
}