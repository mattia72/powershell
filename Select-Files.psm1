function Select-Files {
  param (
    $Directory,
    [string[]]$FileTypes = @('*.*'),
    [string[]]$FileHasStrings = @(),
    [string[]]$FileDontHaveStrings = @()
  )
  Get-ChildItem -Path $Directory -Include $FileTypes -File -Recurse -ErrorAction SilentlyContinue | 
    ForEach-Object { 
    $FilePath = $_
    $FileContent = Get-Content -Path $FilePath -Raw
    $Ok = $true
    foreach ($pattern in $FileHasStrings) {
      if ($FileContent -notmatch $pattern) {
        $Ok = $false
        break
      }
    }
    if ($Ok) {
      foreach ($pattern in $FileDontHaveStrings) {
        if ($FileContent -match $pattern) {
          $Ok = $false
          break
        }
      }
    }
    if ($Ok) {
      $FilePath
    }
  }
}

Export-ModuleMember -Function Select-Files