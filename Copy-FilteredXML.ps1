<#
.SYNOPSIS
  Copy XML content to another file while filtering elements
.DESCRIPTION
  Copy elements from $XmlSrcPath to $XmlDestPath 
  while filtering child elements of $ParentElement not match 
  $ElementFilter 
.EXAMPLE
  PS C:\> Copy-FilteredXML input.xml output.xml 'parent' '^child(2|some_regex)$'
  Copy elements from input.xml to output.xml while filtering 
  child elements not match regex '^child(2|some_regex)$' under 'parent'
  input:                     | output: 
    <parent>                 |   <parent>
      <child1>value<\child1> |     <child1>value<\child1>
      <child2>value<\child2> |   <\parent>
    <\parent>                |
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>

param (
  # XML file to modify 
  [ValidateScript( {(Test-Path -Path $_) })]
  $XmlSrcPath,
  $XmlDestPath,
  $ParentElement,
  $ElementFilter
) 

function Read-FilterAndWriteXml {
  param (
    [ValidateScript( {(Test-Path -Path $_) })]
    $Src,
    $Dest,
    $Parent,
    $Filter
  )
  
  try 
  {
    # Set The Formatting
    $xmlsettings = New-Object System.Xml.XmlWriterSettings
    $xmlsettings.Indent = $true
    $xmlsettings.IndentChars = " "
    $SrcPath = $(Get-Item $Src).FullName
    $DestPath = $(New-Item -path $Dest -ItemType File -Force).FullName

    # Set the File Name Create The Document
    $writer = [System.XML.XmlWriter]::Create($DestPath, $xmlsettings)
    # $writer.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
    $reader = [System.XML.XmlReader]::Create($SrcPath);
    # $reader.WhitespaceHandling = WhitespaceHandling.None;
    $parent_started = $false 
    while ( $reader.Read()) {
      # $dbg_msg = $reader.NodeType.ToString().PadRight(20, '-') 
      # $dbg_msg += $reader.NodeType.ToString().PadRight(20, '-') 
      # $dbg_msg +=  "> ".PadRight($reader.Depth*5) 
      # $dbg_msg += $("Name = {0}, Value = {1}" -f  $reader.Name, $reader.Value)
      # Write-Host $dbg_msg
      switch ($reader.NodeType) {
        'Element' { 
          if ($parent_started) {
            if ( $reader.Name -Match $Filter) {
              $writer.WriteNode($reader, $false)
            }
          }
          else {
            $parent_started = ( $reader.Name -eq $Parent) 
            if($reader.IsEmptyElement) {
              $writer.WriteNode($reader, $false)
            } else {
              $writer.WriteStartElement($reader.Name)
            }
          }
        }
        'Text' {
          if (-not $parent_started) {
            $writer.WriteString($reader.Value)
          }
        }
        'CDATA' {
          if (-not $parent_started) {
            $writer.WriteCData($reader.Value)
          }
        }
        'ProcessingInstruction' {
          $writer.WriteProcessingInstruction($reader.Name, $reader.Value)
        }
        'Comment' {
          $writer.WriteNode($reader, $false)
        }
        'XmlDeclaration' {
          $writer.WriteNode($reader, $false)
        }
        'DocumentType' {
          $writer.WriteNode($reader, $false)
        }
        'EntityReference' {
          $writer.WriteNode($reader, $false)
        }
        'EndElement' {
          if ($parent_started -and $reader.Name -eq $Parent) {
            $parent_started = $false
          }  
          if (-not $parent_started) {
            $writer.WriteEndElement()
          }
        }
      }
    }
  }
  catch {
      Write-Error $_.Exception.Message
  }
  finally {
    $writer.Flush()
    $writer.Close()
    $reader.Close()
  }
}

Read-FilterAndWriteXml -Src $XmlSrcPath -Dest $XmlDestPath -Filter $ElementFilter -Parent $ParentElement
