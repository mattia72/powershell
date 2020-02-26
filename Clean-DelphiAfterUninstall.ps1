Remove-Item "${env:ProgramFiles(x86)}\Embarcadero\*" -Verbose -Recurse -Force
Remove-Item "$env:ProgramData\Embarcadero\*" -Verbose -Recurse -Force
Remove-Item "$env:APPDATA\Embarcadero\*" -Verbose -Recurse -Force
Remove-Item "$env:LOCALAPPDATA\Embarcadero\*" -Verbose -Recurse -Force
Remove-Item "$env:PUBLIC\Documents\Embarcadero\*" -Verbose -Recurse -Force
Remove-Item "$env:USERPROFILE\Documents\Embarcadero\*" -Verbose -Recurse -Force

#
#. .\Search-Registry.ps1
#Search-Registry -Path hklm:\software -SearchRegex "Embarcadero" | %{Remove-Item "Registry::$($_.Key)" -Verbose}
#Search-Registry -Path hkcu:\software -SearchRegex "Embarcadero" | %{Remove-Item "Registry::$($_.Key)" -Verbose}
#Search-Registry -Path hklm:\SOFTWARE\Classes\TypeLib -Recurse -ValueDataRegex "Embarcadero" | %{Remove-Item "Registry::$($_.Key -replace '}.*$','}')" -Verbose}