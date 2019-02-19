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
  Output (if any)
.NOTES
  General notes
#>

function Add-PascalUnitToUses {
  param (  
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    [ValidateScript( { (Test-Path -Path $_) })]
    $FilePath, 
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    [ValidateSet("interface", "implementation")]
    $Section, 
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
    $Unit
  )
  begin {}
  process {
    $fileContent = (Get-Content -Path $FilePath -Raw)

    if ($fileContent -match "\b$Unit\b") {
      Write-Warning("$Unit already exists in $FilePath")
      return
    }

    $sectionPattern = "(?smi)^\s*$Section" 
    $usesPattern = "$sectionPattern\s*uses\s*"
    $sectionHasUses = $fileContent -match "$usesPattern(\w+)\s*"

    if (-not $sectionHasUses) {
      Write-Warning("No uses in $Section section in $FilePath")
      $fileContent -replace $sectionPattern,"$&`r`n`r`nuses`r`n`t$Unit`r`n`t;" | Set-Content -Path $FilePath -NoNewline
    }
    else {
      Write-Verbose("Add $Unit to $Section section in $FilePath")
      $fileContent -replace "(?smi)^(\s*$Section\s*uses)\s*([\w.]+)\s*","`$1`r`n`t$Unit`r`n`t, `$2`r`n`t" | Set-Content -Path $FilePath -NoNewline
    }
  }
  end {}
}


Export-ModuleMember -Function Add-PascalUnitToUses
$FilePath = "D:\SCCS\agsrc_trunk\WinLohn\Lohn-Package\unBaulohnMeldeprotokoll.pas" 
Add-PascalUnitToUses -FilePath $FilePath -Section implementation -Unit "UnitBlaBla" 