<#
.SYNOPSIS
  Copy XML content to another file while filtering elements
.DESCRIPTION
  Copy elements from $XmlSrcPath to $XmlDestPath 
  while filtering child elements of $ParentElement not match 
  $ElementFilter 
.EXAMPLE
  PS C:\> Copy-ElementFilteredXML input.xml output.xml 'parent_element_name' '^child_elem_(regex1|regex2)$'
  Copy elements from iput.xml to output.xml while filtering 
  child elements not match '^child_elem_(regex1|regex2)$' under parent_element_name
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
    $par_start_written = $false 
    while ( $reader.Read()) {
      # $dbg_msg = $reader.NodeType.ToString().PadRight(20, '-') 
      # $dbg_msg += $reader.NodeType.ToString().PadRight(20, '-') 
      # $dbg_msg +=  "> ".PadRight($reader.Depth*5) 
      # $dbg_msg += $("Name = {0}, Value = {1}" -f  $reader.Name, $reader.Value)
      # Write-Host $dbg_msg
      switch ($reader.NodeType) {
        'Element' { 
          if ($par_start_written) {
            if ( $reader.Name -Match $Filter) {
              $writer.WriteNode($reader, $false)
            }
          }
          else {
            $par_start_written = ( $reader.Name -eq $Parent) 
            if($reader.IsEmptyElement) {
              $writer.WriteNode($reader, $false)
            } else {
              $writer.WriteStartElement($reader.Name)
            }
          }
        }
        'Text' {
          if (-not $par_start_written) {
            $writer.WriteString($reader.Value)
          }
        }
        'CDATA' {
          if (-not $par_start_written) {
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
          if ($par_start_written -and $reader.Name -eq $Parent) {
            $par_start_written = $false
          }  
          if (-not $par_start_written) {
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
