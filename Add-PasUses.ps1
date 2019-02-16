# [CmdletBinding()] 
# Param(
#     [Parameter(Mandatory = $true, Position = 0)]
#     [ValidateScript( { (Test-Path -Path $_) })]
#     [String[]]$Path 
# )
function FileContains {
  param ( $FilePath, $Text, [switch] $NotMatch)

  if ($NotMatch) {
    $m = Select-String -Path $FilePath -pattern $Text -NotMatch
  }
  else {
    $m = Select-String -Path $FilePath -pattern $Text 
  }

  if ($m.Matches.Length -gt 0) {
    return $FilePath
  }
  return $null
}

function Add-UnitToUses {
  param (  
    [ValidateScript({ (Test-Path -Path $_) })]
    $FilePath, 
    [ValidateSet("interface", "implementation")]
    $Section, 
    $Unit
  )
  begin {}
  process {
    $fileContent = (Get-Content -Path $FilePath -Raw)

    if ($fileContent -match "\b$Unit\b") {
      Write-Warning("$Unit already in $FilePath")
      return
    }

    $sectionPattern = "(?smi)^\s*$Section" 
    $usesPattern = "$sectionPattern\s*uses\s*"
    # $sectionHasUses = $fileContent -match $usesPattern
    $sectionHasUses = $fileContent -match "$usesPattern(\w+)\s*"

    if(-not $sectionHasUses){
      Write-Warning("No uses in $Section section in $FilePath")
      $fileContent -replace $sectionPattern, "$&`n`nuses`n`t$Unit`n`t;" | Set-Content -Path $FilePath 
    }
    else {
      Write-Host("Add $Unit in $Section section in $FilePath")
      $fileContent -replace "(?smi)^(\s*$Section\s*uses)\s*([\w.]+)\s*", "`$1`n`t$Unit`n`t, `$2`n`t" | Set-Content -Path $FilePath 
    }
  }
  end {}
}

# $Path = "D:\SCCS\agsrc_trunk\WinLohn\Lohn-Package\unBaulohnMeldeprotokoll.pas"
$Path = "C:\Program Files (x86)\Embarcadero\Studio\19.0\ObjRepos\de\DelphiWin32\SDIApp"
# $Path = "$env:AGSRC\WinLohn"
# $SearchString = "AGridStorageDBZmiv"
$SearchString = "About4"

Get-ChildItem -Path $Path -Include *.pas, *.inc -File -Recurse -ErrorAction SilentlyContinue | 
  ForEach-Object { Add-UnitToUses -FilePath $_ -Section interface -Unit "$SearchString" } 
