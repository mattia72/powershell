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

Import-Module ${env:HOME}\dev\powershell\Add-PascalUnitToUses -Force
Import-Module ${env:HOME}\dev\powershell\Remove-FromFile -Force

function Update-TextInPascalFile {
  param ( 
    [ValidateScript( {(Test-Path -Path $_)})]
    $FilePath, 
    $Search,
    $Replace, 
    [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    [ValidateSet("interface", "implementation")]
    $Section, 
    [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    $Unit 
  )
  process {
    (Get-Content -Path $FilePath -Raw) -replace $Search, $Replace  | Set-Content -Path $FilePath -NoNewline
    Add-PascalUnitToUses -FilePath $FilePath -Section $Section -Unit $Unit 
  }
  end {
    Write-Verbose "${FilePath} changed."
  }
}
function Update-TextInPascalDirectory {
  param ( 
    [ValidateScript( {(Test-Path -Path $_)})]
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
    Write-Verbose "$count pascal file(s) changed." 
  }
}

function Remove-HistoryBlock {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    [ValidateScript( {(Test-Path -Path $_)})]
    [string] $FilePath 
  )
  begin {
    $count = 0
  }
  process {
    $B = "{"
    $E = "}[ \t]*\r\n"
    $Contain = "\r\n[\t /]*[A-Z ]{3} \d\d\.\d\d\.\d\d Task="
    Select-FileContentContainsBlock -FilePath $FilePath -Begin $B -End $E -Contain $Contain | 
      Where-Object { $_ -ne "" } |
        ForEach-Object { 
          $count++ 
          $_
        } | 
      Remove-BlockFromText  -Begin $B -End $E -Contain $Contain -FirstOnly | 
      ForEach-Object { 
      Write-Verbose "${FilePath} history block removed."
      $_} | 
      Set-Content -Path $FilePath -NoNewline
  }
  end {
    Write-Verbose "History block removed from $count file(s)."
  }
}

Export-ModuleMember -Function Update-TextInPascalFile, Update-TextInPascalDirectory, Remove-HistoryBlock