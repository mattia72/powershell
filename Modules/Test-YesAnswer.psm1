
function Test-YesAnswer {
  [CmdletBinding()]
  param (
      [string] $Message,
      [string] $DefaultAnswer = "N"
  )

  $answer = ""

  $defaultText = "No"
  if ($DefaultAnswer -match "[nN]") {$defaultText = "No"}
  elseif ($DefaultAnswer -match "[yY]") {$defaultText = "Yes"}

  while ($answer -notmatch "[yYnN]") {
      $answer = Read-Host -Prompt "$Message`n[Y] Yes [N] No (default is $defaultText)"
      if ($null -eq $answer -or $answer -eq "") {
          $answer = $DefaultAnswer
          break;
      }
  }
  return $answer -match "[yY]"
}
Export-ModuleMember -Function Test-YesAnswer