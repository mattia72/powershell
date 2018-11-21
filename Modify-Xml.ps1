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
  $node.AppendChild($child)
}

function Get-Translation($text) {
  if ($text -match '^[0-9"x: ]+$') {
    return $text
  }
  else {
    if (-not $translate_cache.ContainsKey($text)) {
      Write-Information -InformationAction Continue "Call google to translate: `"$text`""
      $translated = $(Show-GoogleTranslate -From Slovak -To Hungarian -Console -Text $text)
      $translate_cache.Add($text, $translated)
    }
    else {
      Write-Information -InformationAction Continue "Translating skipped!"
    }
    return $translate_cache[$text]
  }
}

function Change-DescriptionNode()
{
  $xnode = Select-Xml -Xml $xml -Namespace $stk -XPath "//stk:stockHeader/stk:description2"
  #$xnode.GetType()

  foreach ($item in $xnode.Node) {

    $descr_arr = @()
    foreach ($line in $($item.InnerText -split "`r`n")) {
      $arr = $line.Split('=')
      $line1 = $arr[0].Trim("$"," ","`t")
      $line2 = $arr[1].Trim("#"," ","`t")
      $descr_arr+=@(,@($line1,$line2))
    }

    $item.InnerText = ""
    $i = 0
    foreach ($descr_item in $descr_arr) {
      $name = Get-Translation $descr_item[0]
      $value = Get-Translation $descr_item[1]

      Add-XMLChildNode $item.ParentNode "descr_name$i" $name 
      Add-XMLChildNode $item.ParentNode "descr_value$i" $value
      $i++
    }

    if ($first_only -eq 1) {
      #only for test :)
      break
    }
  }
}
function Change-NameNode()
{
  $xnode = Select-Xml -Xml $xml -Namespace $stk -XPath "//stk:stockHeader/stk:name"
  #$xnode.GetType()

  foreach ($item in $xnode.Node) {
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

function Save-Xml() {
  #region Save 

  # $savedFilePath=$(Join-Path $file.Directory "$($file.Basename)_saved_iso8859-2.xml")
  $savedFilePath = $(Join-Path $file.Directory "$($file.Basename)_saved_utf-8.xml")

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
    if ($writer -ne $null) {
      $writer.Close()
    }
  }
  #endregion

}

$first_only = 1
#[xml]$xml = Get-Content "c:\msys64\home\mata\downloads\pelda_jav.xml"
$file = Get-Item $XmlFilePath 
$stk = @{stk = "http://www.stormware.cz/schema/version_2/stock.xsd"}

$translate_cache_path = $(Join-Path $file.Directory "translate_cache.txt")
if (Test-Path $translate_cache_path) {
  #$translate_cache = Get-Content $translate_cache_path | Out-String | Invoke-Expression
  $translate_cache = Get-Content -Raw $translate_cache_path | ConvertFrom-StringData
}

if ($translate_cache -eq $null) {
  $translate_cache = @{}
}

# load it into an XML object:
$xml = New-Object -TypeName XML
$xml.Load($file)

Change-NameNode
Change-DescriptionNode
Save-Xml

if ($translate_cache.Count -gt 0) {
  $translate_cache.GetEnumerator() | Sort-Object Name -Unique | 
    Where-Object {$_.Key -ne ''} |
    ForEach-Object { "{0} = {1}" -f $_.Name, $_.Value} | 
    Set-Content $translate_cache_path -Encoding UTF8 
}