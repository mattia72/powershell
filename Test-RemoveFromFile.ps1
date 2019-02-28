
Import-Module ${env:HOME}\dev\powershell\Modules\Remove-FromFile -Force
Import-Module ${env:HOME}\dev\powershell\Modules\Update-TextInPascalFiles -Force


$FilePath = @(
  'C:\Program Files (x86)\Embarcadero\Studio\19.0\ObjRepos\en\DelphiWin32\SDIApp\ABOUT.PAS',
  'D:\SCCS\agsrc_trunk\WinLohn\Lohn-Package\unKvRueckmImport_DruckAuswahl.pas',
  'D:\SCCS\agsrc_trunk\WinLohn\Lohn-Package\unLorvBEA_DruckAuswahl.pas',
  'D:\SCCS\agsrc_trunk\WinLohn\Lohn-Package\unBaulohnMeldeprotokoll.pas'
)

$Directory = "$env:AGSRC\WinLohn"
Write-Host "Revert changed data in $env:AGSRC ..." -ForegroundColor Blue
svn revert -R $Directory

$FilePath | Remove-HistoryBlock -Verbose

# $t1=@"
# {
#   t1 szöveg
#   valami
# }
# t1 szöveg
# valami
# t1 end
# --------------------
# "@

# $t2=@"
# {
#   t2 
#   valami
# }
# {
#   Historie:                                                                       \n
#   ---------
#   // OY  27.06.18 Task=123390/134388 CD=Oktober-DVD 2018: rvBEA - Registrierungsverfahren - Integration in MPD
#   // OY  24.07.18 Task=134388/134389 CD=Oktober-DVD 2018: rvBEA - Registrierungverfahren - Änderungen in den Betriebsstätten
#   // OY  18.10.18 Task=123390/134388 CD=Januar-DVD 2019: rvBEA - Registrierungsverfahren - Integration in MPD
# }
# implementation
# szöveg
# {valami
# // OY  18.10.18 Task=123390/134388 CD=Januar-DVD 2019: rvBEA - Registrierungsverfahren - Integration in MPD
# szöveg
# }
# valami
# t2 end
# ...........................
# "@

# $B = "{"
# $E = "}[ \t]*\r\n"
# $Contain = "\r\n[\t /]*[A-Z ]{3} \d\d\.\d\d\.\d\d Task="
# $a=@($t1, $t2)
# $a | Remove-BlockFromText -Begin $B -End $E -Contain $Contain -FirstOnly

