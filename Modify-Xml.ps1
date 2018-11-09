function Add-XMLAttribute([System.Xml.XmlNode] $node, [string] $attr_name, [string] $attr_value)
{
  $attrib = $node.OwnerDocument.CreateAttribute($attr_name)
  $attrib.Value = $attr_value
  $node.Attributes.Append($attrib)
  $node.InnerText = ""
}

#[xml]$xml = Get-Content "c:\msys64\home\mata\downloads\pelda_jav.xml"
$file = Get-Item "$env:USERPROFILE\Downloads\export_zasob7.xml"

# load it into an XML object:
$xml = New-Object -TypeName XML
$xml.Load($file)

$stk = @{stk = "http://www.stormware.cz/schema/version_2/stock.xsd"}
$xnode = Select-Xml -Xml $xml -Namespace $stk -XPath "//stk:stockHeader/stk:name"
#$xnode.GetType()

foreach ($item in $xnode.Node)
{
  $arr = $item.InnerText.Split(";")
  Add-XMLAttribute $item "line1" $arr[0].Trim()
  Add-XMLAttribute $item "line2" $arr[1].Trim()
  break
}

$xml.Save($(Join-Path $file.Directory "$($file.Basename)_saved.xml"))