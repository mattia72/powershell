
<#
.SYNOPSIS
  Simple check if file contains given word
.DESCRIPTION
  Simple check if file contains given word
.EXAMPLE
  PS C:\> Test-FileContainsWord -FilePath file.txt -$Text 'text'
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  $true or $false
.NOTES
  General notes
#>
function Test-FileContainsWord {
  param ( $FilePath, $Text )

  if ((Get-Content -Path $FilePath -Raw) -match "\b$Text\b") {
    return $true
  }
  return $false
}

Export-ModuleMember -Function Test-FileContainsWord