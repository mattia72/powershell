
Import-Module ${env:HOME}\dev\powershell\Remove-FromFile -Force
Import-Module ${env:HOME}\dev\powershell\Update-TextInPascalFiles -Force


$FilePath=@(
'D:\SCCS\agsrc_trunk\WinLohn\Lohn-Package\unKvRueckmImport_DruckAuswahl.pas',
'D:\SCCS\agsrc_trunk\WinLohn\Lohn-Package\unLorvBEA_DruckAuswahl.pas',
'D:\SCCS\agsrc_trunk\WinLohn\Lohn-Package\unBaulohnMeldeprotokoll.pas'
)

$Directory = "$env:AGSRC\WinLohn"
Write-Host "Revert changed data in $env:AGSRC ..." -ForegroundColor Blue
svn revert -R $Directory

$FilePath | Remove-HistoryBlock -Verbose