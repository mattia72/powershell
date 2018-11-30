param (
# XML file to modify 
[ValidateScript({(Test-Path -Path $_) })]
$XmlFilePath
) # must be the first statement in the script

Import-Module -Name $PSScriptRoot\Show-GoogleTranslate -AsCustomObject


function Add-XMLAttribute([System.Xml.XmlNode] $node, [string] $attr_name, [string] $attr_value)
{
  $attrib = $node.OwnerDocument.CreateAttribute($attr_name)
  $attrib.Value = $attr_value
  $node.Attributes.Append($attrib)
  $node.InnerText = ""
}

function Add-XMLChildNode([System.Xml.XmlNode] $node, [string] $node_name, [string] $node_value)
{
  $child = $node.OwnerDocument.CreateElement($node_name)
  $child.InnerText = $node_value
  $node.AppendChild($child) | Out-Null
}

function Get-Translation([string] $text) {

  if ($text -eq "") { return $text }

  if($text -match ".*\r\n") { $text = $text -replace "\r\n", "_NEWLINE_" }

  if ($translate_cache.ContainsKey($text)) {
    Write-Verbose "Translating from cache!"
    return $translate_cache[$text]
  }

  $translated = $text

  if ($text -match '(^[0-9."x: ]+$)|(^[A-F][+-]?$)|(^RAM)|(^HDD)|(^LAN:)|(^Intel)|(^AMD)|(^NVIDIA)|(^Pentium)|(^Xeon)|(^Celeron)|(^VGA)|(^.*[#&])') {
    Write-Information -InformationAction Continue "Translating skipped for $text"
  } else {
    Write-Information -InformationAction Continue "Call google translate: `"$text`""
    $translated = $(Show-GoogleTranslate -From Slovak -To Hungarian -Console -Text $text)
  }

  if ($translated -eq "") {
    $translated = $text
  } 

  # if (-not $translate_cache.ContainsKey($text)) {
    $translate_cache.Add($text, $translated)
  # }

  return $translated
}

function Split-DescriptionNode([xml] $xml)
{
  $xnode = Select-Xml -Xml $xml -Namespace $stk -XPath "//stk:stockHeader/stk:description2"
  #$xnode.GetType()
  $i = 0

  foreach ($item in $xnode.Node) {

    $descr_arr = @()
    foreach ($line in $($item.InnerText -split "`r`n")) {
      $arr = $line.Split('=')
      $line1 = $arr[0].Trim("$"," ","`t")
      $line2 = ""
      if ($arr.Count -gt 1) {
        $line2 = $arr[1].Trim("#"," ","`t")
      }
      $descr_arr+=@(,@($line1,$line2))
    }

    $j = 0
    $item.InnerText = ""
    foreach ($descr_item in $descr_arr) {
      $prefix = $descr_item[0]
      $postfix = $descr_item[1]
      Write-Progress -Id 5 -ParentId 1 -Activity Translate -Status Descriptions -CurrentOperation "$prefix $postfix" -PercentComplete ([int](100 * $i / $xnode.Count))
      $name = Get-Translation $prefix
      $value = Get-Translation $postfix

      Add-XMLChildNode $item.ParentNode "descr_name$j" $name 
      Add-XMLChildNode $item.ParentNode "descr_value$j" $value
      $j++
    }
    $i++

    if ($first_only -eq 1) {
      #only for test :)
      break
    }
  }
}
function Translate-StorageNode([xml] $xml)
{
  $xnode = Select-Xml -Xml $xml -Namespace $stk -XPath "//stk:stockHeader/stk:storage"
  #$xnode.GetType()

  $i = 0
  foreach ($item in $xnode.Node) {
    Write-Progress -Id 4 -ParentId 1 -Activity Translate -Status Storage -CurrentOperation $item.InnerText -PercentComplete ([int](100 * $i++ / $xnode.Count))
    
    $storages = $item.InnerText.Split("/")
    $translated = ""
    foreach ($storage in $storages) {
      $translated += "$(Get-Translation $storage)/"
    }
    $item.InnerText = $translated

    if ($first_only -eq 1) {
      #only for test :)
      break
    }
  }
}

function Split-NameNode([xml] $xml)
{
  $xnode = Select-Xml -Xml $xml -Namespace $stk -XPath "//stk:stockHeader/stk:name"
  #$xnode.GetType()

  $i = 0

  foreach ($item in $xnode.Node) {
    Write-Progress -Id 2 -ParentId 1 -Activity Translate -Status Names -CurrentOperation $item.InnerText -PercentComplete ([int](100 * $i++ / $xnode.Count))

    $hash = $item.InnerText.Split(";")
    $line1 = $hash[0].Trim()
    $line2 = ""
    $item.InnerText = ""

    Add-XMLChildNode $item.ParentNode "name_line1" $line1 
    if ($hash.Count -eq 2) {
      $line2 = Get-Translation $hash[1].Trim()
    }
    else {
      Write-Information "Splitted text has $($hash.Count) item. `"$($item.InnerText)`" "
    }
    Add-XMLChildNode $item.ParentNode "name_line2" $line2


    if ($first_only -eq 1) {
      #only for test :)
      break
    }
  }
}

function Save-Xml([xml]$xml, [System.IO.FileInfo]$file) {
  #region Save 

  $date_time = $(Get-Date -Format "yyyyMMddhhmm")
  # $savedFilePath=$(Join-Path $file.Directory "$($file.Basename)_saved_iso8859-2.xml")
  $savedFilePath = $(Join-Path $file.Directory "$($file.Basename)_${date_time}_utf-8.xml")

  try {
    #$enc = [System.Text.Encoding]::GetEncoding('iso-8859-2')
    $enc = New-Object System.Text.UTF8Encoding($false)

    # this writer works
    $writer = New-Object System.IO.StreamWriter($savedFilePath, $false, $enc)

    # this writer doesn't work
    # $settings = New-Object System.Xml.XmlWriterSettings
    # $settings.Indent = true;
    # $settings.IndentChars = "\t"
    # $settings.Encoding = $enc
    # $textWriter = New-Object System.Xml.XmlTextWriter($savedFilePath,[System.Text.Encoding]::UTF8)
    # $writer = New-Object System.Xml.XmlWriter($textWriter, $settings)

    $xml.Save($writer)

  }
  finally {
    if ($null -ne $writer ) {
      $writer.Close()
    }
  }
  #endregion
}

$first_only = 0
$file = Get-Item $XmlFilePath 
$stk = @{stk = "http://www.stormware.cz/schema/version_2/stock.xsd"}

$translate_cache_path = $(Join-Path $file.Directory "translate_cache.txt")
if (Test-Path $translate_cache_path) {
  #$translate_cache = Get-Content $translate_cache_path | Out-String | Invoke-Expression
  $translate_cache = Get-Content -Raw $translate_cache_path | ConvertFrom-StringData
}

if ($null -eq $translate_cache) {
  $translate_cache = @{}
}

try {
  # load it into an XML object:
  $xml = New-Object -TypeName XML
  $xml.Load($file)

  $Step = 0
  $TotalSteps = 3
  Write-Progress -Id 1             -Activity Translate -Status "Step $Step of $TotalSteps" -PercentComplete ($Step / $TotalSteps * 100) 

  Write-Progress -Id 2 -ParentId 1 -Activity Translate -Status Names -PercentComplete 0
  Write-Progress -Id 4 -ParentId 1 -Activity Translate -Status Storage -PercentComplete 0
  Write-Progress -Id 5 -ParentId 1 -Activity Translate -Status Descriptions -PercentComplete 0
  Translate-StorageNode $xml

  $Step++
  Write-Progress -Id 1 -Activity Translate -Status "Step $Step of $TotalSteps" -PercentComplete ($Step / $TotalSteps * 100) 
  Split-NameNode $xml

  $Step++
  Write-Progress -Id 1 -Activity Translate -Status "Step $Step of $TotalSteps" -PercentComplete ($Step / $TotalSteps * 100) 
  Split-DescriptionNode $xml

  Write-Progress -Id 4 -ParentId 1 -Activity Translate -Status Storage -Completed
  Write-Progress -Id 2 -ParentId 1 -Activity Translate -Status Names -Completed
  Write-Progress -Id 5 -ParentId 1 -Activity Translate -Status Descriptions -Completed

  Save-Xml $xml $file
}
catch {
  Write-Error $_.Exception.Message
}
finally {
  if ($translate_cache.Count -gt 0) {
    $translate_cache.GetEnumerator() | Sort-Object Name -Unique | 
      Where-Object {$_.Key -ne ''} |
      ForEach-Object { "{0} = {1}" -f $_.Name, $_.Value} | 
      Set-Content $translate_cache_path -Encoding UTF8 
  }
}