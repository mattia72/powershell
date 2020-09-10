# Runs given command as Admin in a separate Window
# Example: RunAsAdmin Write-Host "haho"
$NewScriptBlock = [scriptblock]::Create(
"$args
Read-Host")
$process = Start-Process powershell -Verb RunAs -PassThru -ArgumentList Invoke-Command, -ScriptBlock, "{$NewScriptBlock}"
# so waits for the end...
$process.WaitForExit()
