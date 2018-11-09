#[xml]$xml = Get-Content "c:\msys64\home\mata\downloads\pelda_jav.xml"
[xml]$xml = Get-Content C:\msys64\home\mata\downloads\export_zasob7.xml


foreach ($name in $xml.responsePack.responsePackItem.listStock.stock.stockHeader.name)
{
  $arr = $name.Split(";")
  "<line1> $arr[0] </line1> <line2> $arr[1] </line2> "
}
