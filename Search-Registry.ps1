  [CmdletBinding()] 
  param( 
    [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)] 
    [Alias("PsPath")] 
    # Registry path to search 
    [string[]] $Path, 
    # Specifies whether or not all subkeys should also be searched 
    [switch] $Recurse, 
    [switch] $Relative, 
    # A regular expression that will be checked against key names, value names, and value data (depending on the specified switches) 
    [Parameter(ParameterSetName = "SingleSearchString", Mandatory)] 
    [string] $SearchRegex, 
# When the -SearchRegex parameter is used, this switch means that key names will be tested (if none of the three switches are used, keys will be tested) 
    [Parameter(ParameterSetName = "SingleSearchString")] 
    [switch] $KeyName, 
# When the -SearchRegex parameter is used, this switch means that the value names will be tested (if none of the three switches are used, value names will be tested) 
    [Parameter(ParameterSetName = "SingleSearchString")] 
    [switch] $ValueName, 
# When the -SearchRegex parameter is used, this switch means that the value data will be tested (if none of the three switches are used, value data will be tested) 
    [Parameter(ParameterSetName = "SingleSearchString")] 
    [switch] $ValueData, 
# Specifies a regex that will be checked against key names only 
    [Parameter(ParameterSetName = "MultipleSearchStrings")] 
    [string] $KeyNameRegex, 
    [Parameter(ParameterSetName = "MultipleSearchStrings")] 
    # Specifies a regex that will be checked against value names only 
    [string] $ValueNameRegex, 
    [Parameter(ParameterSetName = "MultipleSearchStrings")] 
    # Specifies a regex that will be checked against value data only 
    [string] $ValueDataRegex 
  ) 

function Create-Record {
  param(
    $Relative,
    $Key,
    $Value,
    $Reason
  )
  if ($Relative) {
    $Key = $Key | Resolve-Path -Relative
  }
  [PSCustomObject] @{ Reason = $Reason; Key = $Key; Value = $Value;  } 
}
function Search-Registry { 
  <# 
.SYNOPSIS 
Searches registry key names, value names, and value data (limited). 

.DESCRIPTION 
This function can search registry key names, value names, and value data (in a limited fashion). It outputs custom objects that contain the key and the first match type (KeyName, ValueName, or ValueData). 

.EXAMPLE 
Search-Registry -Path HKLM:\SYSTEM\CurrentControlSet\Services\* -SearchRegex "svchost" -ValueData 

.EXAMPLE 
Search-Registry -Path HKLM:\SOFTWARE\Microsoft -Recurse -ValueNameRegex "ValueName1|ValueName2" -ValueDataRegex "ValueData" -KeyNameRegex "KeyNameToFind1|KeyNameToFind2" 

#> 
  [CmdletBinding()] 
  param( 
    [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)] 
    [Alias("PsPath")] 
    # Registry path to search 
    [string[]] $Path, 
    # Specifies whether or not all subkeys should also be searched 
    [switch] $Recurse, 
    [switch] $Relative, 
    [Parameter(ParameterSetName = "SingleSearchString", Mandatory)] 
    # A regular expression that will be checked against key names, value names, and value data (depending on the specified switches) 
    [string] $SearchRegex, 
    [Parameter(ParameterSetName = "SingleSearchString")] 
    # When the -SearchRegex parameter is used, this switch means that key names will be tested (if none of the three switches are used, keys will be tested) 
    [switch] $KeyName, 
    [Parameter(ParameterSetName = "SingleSearchString")] 
    # When the -SearchRegex parameter is used, this switch means that the value names will be tested (if none of the three switches are used, value names will be tested) 
    [switch] $ValueName, 
    [Parameter(ParameterSetName = "SingleSearchString")] 
    # When the -SearchRegex parameter is used, this switch means that the value data will be tested (if none of the three switches are used, value data will be tested) 
    [switch] $ValueData, 
    [Parameter(ParameterSetName = "MultipleSearchStrings")] 
    # Specifies a regex that will be checked against key names only 
    [string] $KeyNameRegex, 
    [Parameter(ParameterSetName = "MultipleSearchStrings")] 
    # Specifies a regex that will be checked against value names only 
    [string] $ValueNameRegex, 
    [Parameter(ParameterSetName = "MultipleSearchStrings")] 
    # Specifies a regex that will be checked against value data only 
    [string] $ValueDataRegex 
  ) 

  begin { 
    switch ($PSCmdlet.ParameterSetName) { 
      SingleSearchString { 
        $NoSwitchesSpecified = -not ($PSBoundParameters.ContainsKey("KeyName") -or 
          $PSBoundParameters.ContainsKey("ValueName") -or 
          $PSBoundParameters.ContainsKey("ValueData")) -or 
          (-not $KeyName -and -not $ValueName -and -not $ValueData)
        if ($KeyName -or $NoSwitchesSpecified) { $KeyNameRegex = $SearchRegex } 
        if ($ValueName -or $NoSwitchesSpecified) { $ValueNameRegex = $SearchRegex } 
        if ($ValueData -or $NoSwitchesSpecified) { $ValueDataRegex = $SearchRegex } 
      } 
      MultipleSearchStrings { }
    } 
    $GetChildItemError = ''
    $CurrentLocation = Get-Location
  } 

  process { 
    foreach ($CurrentPath in $Path) { 
      Push-Location $CurrentPath
      Get-ChildItem . -Recurse:$Recurse -ErrorVariable +GetChildItemError |  
        ForEach-Object { 
          $Key = $_ 
          $Reason = ''

          if ($KeyNameRegex) {  
            if ($Key.PSChildName -match $KeyNameRegex) {  
              Write-Verbose "$_  -> Match found!" 
              $Value = $Key.PSChildName
              $Reason = "KeyName" 
              Create-Record -Relative $Relative -Key $Key -Value $Value -Reason $Reason
            }  
          } 
          if (-not $Reason -and $ValueNameRegex) {  
            $Key.GetValueNames() | ForEach-Object { 
              if($_ -match $ValueNameRegex) {
                Write-Verbose "$_  -> Match found!" 
                Create-Record -Relative $Relative -Key $Key -Value $_ -Reason "ValueName"
              }
            }  
          } 
          if (-not $Reason -and $ValueDataRegex) {  
            $Key.GetValueNames() | ForEach-Object { 
                $Value = $Key.GetValue($_) 
                if ($Value -match $ValueNameRegex) {  
                  Write-Verbose "$Value  -> Match!" 
                  $Reason = "ValueData" 
                  Create-Record -Relative $Relative -Key $Key -Value $Value -Reason $Reason
                }
            } 
          } 
        } 
      Pop-Location
    } 
  } 
  end{
    if ($GetChildItemError) {
      Write-Host $GetChildItemError
    }
    Set-Location $CurrentLocation 
  }
} 

switch ($PSCmdlet.ParameterSetName) { 
  SingleSearchString { 
    Search-Registry                     `
      -Path $Path                     `
      -Recurse:$Recurse               `
      -Relative:$Relative               `
      -SearchRegex $SearchRegex       `
      -KeyName:$KeyName               `
      -ValueName:$ValueName           `
      -ValueData:$ValueData           `
  } 
  MultipleSearchStrings { 
    Search-Registry                     `
      -Path $Path                     `
      -Recurse:$Recurse               `
      -Relative:$Relative               `
      -KeyNameRegex $KeyNameRegex     `
      -ValueNameRegex $ValueNameRegex `
      -ValueDataRegex $ValueDataRegex 
  } 
} 
