param (
  # XML file to modify 
  [ValidateScript( {(Test-Path -Path $_) })]
  $XmlFilePath
) 

function Save-Xml([xml]$xml, [string]$filePath) {
  #region Save 


  try {
    #$enc = [System.Text.Encoding]::GetEncoding('iso-8859-2')
    $enc = New-Object System.Text.UTF8Encoding($false)

    # this writer works
    $writer = New-Object System.IO.StreamWriter($filePath, $false, $enc)

    # this writer doesn't work
    # $settings = New-Object System.Xml.XmlWriterSettings
    # $settings.Indent = true;
    # $settings.IndentChars = "\t"
    # $settings.Encoding = $enc
    # $textWriter = New-Object System.Xml.XmlTextWriter($savedFilePath,[System.Text.Encoding]::UTF8)
    # $writer = New-Object System.Xml.XmlWriter($textWriter, $settings)

    Write-Information -InformationAction Continue "Saving: `"$savedFilePath`""
    $xml.Save($writer)

  }
  finally {
    if ($null -ne $writer ) {
      $writer.Close()
    }
  }
  #endregion
}

function Delete-XMLNodes {
  [CmdletBinding()]
  param (
    # XML file to modify 
    [ValidateScript( { (Test-Path -Path $_) })]
    $FilePath,
    $TagList
  ) # must be the first statement in the script

  begin {
    Write-Host 'Working...'
    $file = Get-Item $FilePath 
    # $stk = @{stk = "http://www.stormware.cz/schema/version_2/stock.xsd" }
    # load it into an XML object:
    $xml = New-Object -TypeName XML
    $xml.Load($file)
  }
  
  process {
    try {
      # $xpath = "//zasoby/zas/parametre/par/*"
      # $xpath = "//zasoby/zas/parametre/par/*[matches(.,'^par(id|hodn|nazHU)$')]"
      $xpath = "//zasoby/zas/parametre/par/*[name(.)!='parid' and name(.)!='parhodn' and name(.)!='parnazHU']"
      $nodes = Select-Xml -Xml $xml -XPath $xpath 
      $count = $nodes.Count

      while ($null -ne $nodes){
        Write-Progress -Activity 'Removing parameter' -CurrentOperation "$($count - $nodes.Count) / $count" -PercentComplete $(100 - ($nodes.Count*100/$count))
        $nodes[0].Node.ParentNode.RemoveChild($nodes[0].Node) | Out-Null
        $nodes = Select-Xml -Xml $xml -XPath $xpath 
      }

     }
    catch {
      Write-Error $_.Exception.Message
    }
  }
  
  end {
      $date_time = $(Get-Date -Format "yyyyMMddhhmm")
      $savedFilePath = $(Join-Path $file.Directory "$($file.Basename)_${date_time}_utf-8.xml")
      Save-Xml $xml $savedFilePath
      # Unformatted
      # $xml.OuterXml | Out-File  $out_file -Encoding "UTF8"
      Write-Host "Ready."
  }
}

# $XmlFilePath = 'c:\msys64\home\mata\dev\ricsi\ExportZasobUniversal2019_small.xml'

Delete-XMLNodes -FilePath $XmlFilePath