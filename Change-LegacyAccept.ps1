Import-Module C:\Users\mattiassich\home\dev\powershell\Add-PascalUnitToUses

function Change-PascalFiles {
  param ( $Path, $Search, $Replace, $Unit )
  begin { 
    $count = 0
  }
  process {
    Get-ChildItem -Path $Path -Include *.pas, *.inc -File -Recurse -ErrorAction SilentlyContinue | 
      Select-String -Pattern $Search | 
      Group-Object Path | 
      Select-Object Name |
      ForEach-Object { 
        $FilePath = $_.Name
        (Get-Content -Path $FilePath -Raw) -replace "$Search", "$Replace"  | Set-Content -Path "$FilePath" -NoNewline
        Add-PascalUnitToUses -FilePath $FilePath -Section implementation -Unit $Unit 
        Write-Host "$FilePath changed successfully." -ForegroundColor Green
        $count++
      } 
  }
  end {
    Write-Host "$count files changed successfully." -ForegroundColor Magenta
  }
}

#
# Replace text should be in single quote!! Or backtick dollar: `$ 
#

Write-Host "`nRevert changed data in $env:AGSRC ..." -ForegroundColor Blue
svn revert -R "$env:AGSRC\WinLohn"

# Step 1
Write-Host "`nStep 1 ..." -ForegroundColor Magenta
$Search = '(?smi)^(\s*)UNTools_S21_DBGridEnter\(\s*([\w.]+?),\s*([\w.]+?),.+?\);'
$Replace = '$1$2.LegacyAccept(TAGridLegacyStorageDBLoad.Create(glrKB.sAktBenutzer), glrKB.sPfadParams + AG_GridPrefix + $3);'
Change-PascalFiles -Path "$env:AGSRC\WinLohn" -Search $Search -Replace $Replace -Unit "AGridStorageDBZmiv"

# Step 2
Write-Host "`nStep 2 ..." -ForegroundColor Magenta
$Search = '(?smi)^(\s*)KorgTools_LoadGridColumns\(\s*([\w.]+?),\s*([\w.]+?),\s+[Tt]rue\s*\);\s*$'
$Replace = "`$1`$2.Accept(TAGridStorageDBDelete.Create(glrKB.sAktBenutzer));`$1`$2.Accept(TAGridStorageDBLoad.Create(glrKB.sAktBenutzer));`r"
Change-PascalFiles -Path "$env:AGSRC\WinLohn" -Search $Search -Replace $Replace -Unit "AGridStorageDBZmiv"

# Step 3
Write-Host "`nStep 3 ..." -ForegroundColor Magenta
$Search = '(?smi)^(\s*)KorgTools_LoadGridColumns\(\s*([\w.]+?),\s*([\w.]+?),\s+[Ff]alse\s*\);\s*$'
$Replace = "`$1`$2.LegacyAccept(TAGridLegacyStorageDBLoad.Create(glrKB.sAktBenutzer), glrKB.sPfadParams + AG_GridPrefix + `$3);`r"
Change-PascalFiles -Path "$env:AGSRC\WinLohn" -Search $Search -Replace $Replace -Unit "AGridStorageDBZmiv"

Write-Host "`nScript ended successfully." -ForegroundColor Green