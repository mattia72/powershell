<#
.Synopsis
   Reads meta-info data from an epub formated ebook
.DESCRIPTION
   The Get-EpubMetaInfo commandlet extracts the OPF metafile and reads some meta-info from it
.EXAMPLE
   Gets meta-infos from the given ebook
   Get-EpubMetaInfo .\ebook.epub
.EXAMPLE
   List the meta-infos of the epub-s in current directory
   Get-ChildItem '*.epub' | Get-EpubMetaInfo
.EXAMPLE
   Get-ChildItem '*.epub' | Get-EpubMetaInfo | %{ Rename-Item $_.File "$($_.Author) - $($_.Title)" }    
#>
function Get-EpubMetaInfo {
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True)]
    [object] $EpubFile
  )
  begin {
    [Reflection.Assembly]::LoadWithPartialName("System.Xml") | Out-Null
    if (!(Get-Module  Handle-ZipFile)) {
      Import-Module -Name (Join-Path $PSScriptRoot Handle-ZipFile)
    }
  }
  process {
    $EpubItem = Get-Item -LiteralPath $EpubFile

    if ( $null -ne $EpubItem ) {

      $ZipEntry = Get-EpubMetaInfoZipEntry $EpubItem.FullName

      if (!$ZipEntry) {
        Write-Error "There is no meta-info $ZipEntry.Name in $EpubFile"
        return
      }

      $Stream = $ZipEntry.Open()

      try {
        $Reader = [System.Xml.XmlReader]::create($Stream)
        [System.Xml.XmlDocument] $opf = New-Object System.Xml.XmlDocument
        $opf.Load($Reader)

        $title = Get-MetaText $opf.package.metadata.title
        $creator = Get-MetaText $opf.package.metadata.creator
        $isbn = $($opf.package.metadata.identifier | Where-Object {$_.scheme -eq "ISBN"}).'#text'
      }
      catch [System.Exception] {
        Write-Error "Couldn't read meta-info $ZipEntry.Name from $EpubFile : $_.Message"
      }
      finally {
        $Stream.Dispose()
        $Reader.Dispose()
        $ZipEntry.Archive.Dispose()
      }
	
      $obj = New-Object -typename PSObject

      $obj | Add-Member -membertype NoteProperty -name File -value ($EpubFile) -passthru |
        Add-Member -membertype NoteProperty -name Author -value ($creator) -passthru |
        Add-Member -membertype NoteProperty -name Title -value ($title) -passthru |
        Add-Member -membertype NoteProperty -name Isbn -value ($isbn) -passthru 
    }
    else {
        Write-Error "Couldn't get item of '$EpubFile'."
    }
  }
  end {
    Remove-Module Handle-ZipFile
  }
}

function Get-MetaText($Tag) {
    if ( $Tag -is [string]) {
        return $Tag
    }
    else {
        return $Tag.'#text'
    }
}

function Get-EpubMetaInfoZipEntry($EpubFile) {
    $EpubFile = Get-Item -LiteralPath $EpubFile
    $OpfFile = 'content.opf'
    $ZipEntry = Get-ZipEntry $EpubFile.FullName $OpfFile -ErrorAction SilentlyContinue
    if (!$ZipEntry) {
        $OpfFile = Get-ZipEntries $EpubFile.FullName | Where-Object { $_ -match '.opf$'}
        $ZipEntry = Get-ZipEntry $EpubFile.FullName $OpfFile
    }
	
    $ZipEntry
}

function Extract-EpubFile( [string] $EpubFileName, [string] $DestinationDirectory ) {
    switch -wildcard ($EpubFileName) {
        '*.epub' {
            Write-Output 'Extract zip archive '.${EpubFileName}.'`nto '.${DestinationDirectory}
            [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory($EpubFileName, $DestinationDirectory)
            Write-Output 'Extracting finished `n'.${EpubFileName}.'to`n'.${DestinationDirectory}.'...'
        }
        default {
            Throw ${EpubFileName}.'is not an epub file!'
        }
    }
}

function Get-EpubMetaFile( [string] $EpubFileName) {
    Import-Module -Name Create-TempFolder -AsCustomObject
    $TempFolder = New-TempFolder

    Extract-EpubFile $EpubFileName $TempFolder

    Remove-TempFolder
    Remove-Module Create-TempFolder
}

Get-ChildItem '*.epub' | Get-EpubMetaInfo

