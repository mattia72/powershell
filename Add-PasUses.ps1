# [CmdletBinding()] 
# Param(
#     [Parameter(Mandatory = $true, Position = 0)]
#     [ValidateScript( { (Test-Path -Path $_) })]
#     [String[]]$Path 
# )
function FileNotContainsText {
  param ( $FilePath, $Text)
  $m = Select-String -Path $FilePath -pattern $Text -NotMatch
  if ($m.Matches.Length -gt 0) {
    return $m.Path
  }
  return $null
}
function Add-ToUses {
  param ( 
    $FilePath, 
    $Type, 
    $Uses
  )
  begin {}
  process {
      
    $content = Get-Content $FilePath
    $line = FileNotContainsText $content $Old  
      
    if (0 -ne $line.Length) {
      "Old text: " + $line
      $new_content = ($content | ForEach-Object {$_ -replace $Old, $new} | Set-Content -path $FilePath.FullName -passthru -confirm )
      "New text: " + (FileNotContainsText $new_content $new)
      "Changed: " + $FilePath
    }
    else {
      "Not Changed: " + $FilePath
    }
  }
  end {}
}

$Path = "D:\SCCS\agsrc_trunk\WinLohn\Lohn-Package\unBaulohnMeldeprotokoll.pas"
# $Path = "$env:AGSRC\WinLohn"
$SearchString = "AGridStorageDBZmiv"


Get-ChildItem -Path $Path -Include *.pas, *.inc -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {FileNotContainsText -File $_ -Text "$SearchString"} 
