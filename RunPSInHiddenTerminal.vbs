
'
' powershell -WindowStyle Hidden will also open the cmd window for a moment 
' so you can avoid it
'
' Usage : 
' RunPSInHiddenTerminal.vbs path\PSScript.ps1
if WScript.Arguments.Count = 0 then
    WScript.Echo "Missing parameters"
end if


strPath = Wscript.ScriptFullName
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.GetFile(strPath)
strFolder = objFSO.GetParentFolderName(objFile) 

command = "powershell.exe -ExecutionPolicy ByPass -WindowStyle Hidden -File " & WScript.Arguments(0) 
set shell = CreateObject("WScript.Shell")
shell.CurrentDirectory = strFolder
shell.Run command,0
