Import-Module -Name $PSScriptRoot\Show-GoogleTranslate -AsCustomObject

function Add-XMLAttribute([System.Xml.XmlNode] $node, [string] $attr_name, [string] $attr_value)
{
  $attrib = $node.OwnerDocument.CreateAttribute($attr_name)
  $attrib.Value = $attr_value
  $node.Attributes.Append($attrib)
  $node.InnerText = ""
}

function Get-Translation($text)
{
  if (-not $global:translate_cache.ContainsKey($text)) {
    Write-Information -InformationAction Continue "Call google to translate: `"$text`""
    $translated = $(Show-GoogleTranslate -From Slovak -To Hungarian -Console -Text $text)
    $global:translate_cache.Add($text, $translated)
  }
  else {
    Write-Information -InformationAction Continue "Translating skipped!"
  }
  $global:translate_cache[$text]
}

#[xml]$xml = Get-Content "c:\msys64\home\mata\downloads\pelda_jav.xml"
$file = Get-Item "$env:USERPROFILE\Downloads\export_zasob7.xml"

# load it into an XML object:
$xml = New-Object -TypeName XML
$xml.Load($file)

$stk = @{stk = "http://www.stormware.cz/schema/version_2/stock.xsd"}
$xnode = Select-Xml -Xml $xml -Namespace $stk -XPath "//stk:stockHeader/stk:name"
#$xnode.GetType()

$global:translate_cache = @{}

foreach ($item in $xnode.Node)
{
  $arr = $item.InnerText.Split(";")

  $line1 = $arr[0].Trim()
  $line2=""
  Add-XMLAttribute $item "line1" $line1 
  if ($arr.Count -eq 2) {
    $line2 = Get-Translation $arr[1].Trim()
  }
  else {
    Write-Information "Splitted text has $($arr.Count) item. `"$($item.InnerText)`" "
  }
  Add-XMLAttribute $item "line2" $line2
  break
}

#$enc = New-Object System.Text.ASCIIEncoding()

# $savedFilePath=$(Join-Path $file.Directory "$($file.Basename)_saved_iso8859-2.xml")
$savedFilePath=$(Join-Path $file.Directory "$($file.Basename)_saved_utf-8.xml")

try {
  # $enc = [System.Text.Encoding]::GetEncoding('iso-8859-2')
  $enc = New-Object System.Text.UTF8Encoding($false)
  $sw = New-Object System.IO.StreamWriter($savedFilePath, $false, $enc)
  $xml.Save($sw)
}
finally {
  $sw.Close()
}