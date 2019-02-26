<#
.SYNOPSIS
  Adds given unit to uses section in a pascal file if not listed already 
.DESCRIPTION
  Adds given unit to uses section in a pascal file. 
  The given unit will be the first in the uses list, if it doesn't appear in the file already
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
eg:
implementation
uses
	unMessage
	, unKonv
...
will be:
implementation
uses
  <New unit>
	, unMessage
	, unKonv
...
.NOTES
  General notes
#>

function Add-PascalUnitToUses {
  [cmdletbinding()]
  param (  
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    [ValidateScript( { (Test-Path -Path $_) })]
    $FilePath, 
		[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    [ValidateSet("interface", "implementation")]
    $Section, 
		[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    $Unit
  )
  process {
    if ([string]::IsNullOrEmpty($Unit)) {
      Write-Verbose("There is no unit to add to $FilePath")
      return
    }
    $fileContent = (Get-Content -Path $FilePath -Raw)

    if ($fileContent -match "\b$Unit\b") {
      Write-Warning("$FilePath already has $Unit listed.")
      return
    }

    $sectionPattern = "(?smi)^\s*$Section" 
    $usesPattern = "$sectionPattern\s*uses\s*"
    $sectionHasUses = $fileContent -match "$usesPattern(\w+)\s*"

    if (-not $sectionHasUses) {
      Write-Warning("$FilePath has no uses in $Section section.")
      $fileContent -replace $sectionPattern,"$&`r`n`r`nuses`r`n`t$Unit`r`n`t;" | Set-Content -Path $FilePath -NoNewline
    }
    else {
      Write-Verbose("$FilePath $Unit added to $Section section.")
      $fileContent -replace "(?smi)^(\s*$Section\s*uses)\s*([\w.]+)\s*","`$1`r`n`t$Unit`r`n`t, `$2`r`n`t" | Set-Content -Path $FilePath -NoNewline
    }
  }
}


Export-ModuleMember -Function Add-PascalUnitToUses