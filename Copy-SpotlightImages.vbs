command = "powershell.exe -ExecutionPolicy ByPass -WindowStyle Hidden -Command ""& cd 'c:\Users\mattiassich\home\dev\powershell'; .\Copy-SpotlightImages"""
set shell = CreateObject("WScript.Shell")
shell.Run command,0