<#
.SYNOPSIS
  Replace text in a directory of pascal files
.DESCRIPTION
  Replace texts by regular expressions in a directory of pascal files, and adds unit if necessary
.EXAMPLE
  PS C:\> Update-TextInPascalFiles -Directory "$env:AGSRC\WinLohn" -Search $Search -Replace $Replace -Section implementation -Unit "AGridStorageDBZmiv"
  Replace texts by regular expressions in WinLohn directory, and adds unit if necessary
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>

Import-Module C:\Users\mattiassich\home\dev\powershell\Add-PascalUnitToUses

function Update-TextInPascalFile {
  param ( 
    $FilePath, 
    $Replace, 
    [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    [ValidateSet("interface", "implementation")]
    $Section, 
    [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    $Unit 
  )
  process {
    (Get-Content -Path $FilePath -Raw) -replace "$Search", "$Replace"  | Set-Content -Path "$FilePath" -NoNewline
    Add-PascalUnitToUses -FilePath $FilePath -Section $Section -Unit $Unit 
  }
  end {
    Write-Host "$FilePath files changed successfully." -ForegroundColor Magenta
  }
}
function Update-TextInPascalDirectory {
  param ( 
    $Directory, 
    [string[]]$FileTypes = @( "*.pas", "*.inc" ),
    $Search, 
    $Replace, 
    [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    [ValidateSet("interface", "implementation")]
    $Section, 
    [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    $Unit 
  )
  begin { 
    $count = 0
  }
  process {
    Get-ChildItem -Path $Directory -Include $FileTypes -File -Recurse -ErrorAction SilentlyContinue | 
      Select-String -Pattern $Search | 
      Group-Object Path | 
      Select-Object Name |
      ForEach-Object { 
      $FilePath = $_.Name
      Update-TextInPascalFile -FilePath $FilePath -Replace $Replace -Search $Search -Section $Section -Unit $Unit
      $count++
    } 
  }
  end {
    Write-Host "$count files changed successfully." -ForegroundColor Magenta
  }
}

Export-ModuleMember -Function Update-TextInPascalFiles