function Go-Home {cd $env:HOME}

function Get-FavoriteAliases 
{
Get-Alias | 
	Where-Object {
	  $_.Name -in ("gh","ga","fe","fh","fkill")
	  } | 
	Format-Table -Property DisplayName -HideTableHeader
}

function Write-Usage
{
  $shell = $Host.UI.RawUi
  $fg = $shell.BackgroundColor
  $bg = $shell.ForegroundColor

  Write-Host "To get favorite aliases, type: 'gfa'. To edit them, type: 'nvim `$PROFILE'" -ForegroundColor $fg -BackgroundColor $bg 
  Write-Host 
}

#Set PSFzF Module
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -EnableAliasFuzzyEdit -EnableAliasFuzzyHistory -EnableAliasFuzzyFasd -EnableAliasFuzzyKillProcess

$env:Path += ";$env:HOME\dev\powershell"
$env:Path += ";$env:HOME\dev\AutoHotkey\QuickTask\scripts"

$env:EDITOR='nvim-qt'

Set-Alias -Name ga -Value Get-FavoriteAliases
Set-Alias -Name gfa -Value Get-FavoriteAliases
Set-Alias -Name gh -Value Go-Home

cd $env:HOME
Write-Usage


