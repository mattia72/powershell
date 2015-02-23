function Restore-AllFromZip
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFile, 
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [object] $DestinationDirectory
        )
    begin
    {
        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    }
	process
	{

	    switch -wildcard ($ZipFile)
	    {
		    '*.7z'
		    {
			    if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) 
			    {
				    throw "Error: $env:ProgramFiles\7-Zip\7z.exe not exists!"
			    }
			    set-alias sevenZip "$env:ProgramFiles\7-Zip\7z.exe"
			    Write-Output "Extract 7zip archive ${ZipFile}`nto ${DestinationDirectory}..."
			    sevenZip x -o"${DestinationDirectory}" $ZipFile
			    Write-Output "7zip finished extracting`n${ZipFile} to`n${DestinationDirectory}..."
		    }
		    '*.zip'
		    {
			    Write-Output "Extract zip archive ${ZipFile}`nto ${DestinationDirectory}..."
		   	    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $DestinationDirectory)
			    Write-Output "Extracting finished `n${ZipFile} to`n${DestinationDirectory}..."
		    }
		    default {Write-Error "$ZipFile is not a zip file!" }
	    }
    }
}          

function Get-ZipEntries
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFile
        )
    begin
    {
        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    }
	process
	{
   	    $ZipFile = [System.IO.Compression.ZipFile]::Open($ZipFile, "Read")
	    $ZipFile.Entries
    }
}


function Restore-FileFromZip
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFile, 
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[string] $EntryName,
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [object] $DestinationDirectory
        )
    begin
    {
        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    }
	process
	{

	   	$ZipArchive = [System.IO.Compression.ZipFile]::Open($ZipFile, "Read")
		$destinationPath = Join-Path $DestinationDirectory $EntryName
		[System.IO.Compression.ZipFileExtensions]::ExtractToFile($ZipArchive, $destinationPath)
    }
}

function Get-ZipEntry
{
	[CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[object] $ZipFile, 
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
		[string] $EntryName)
	process
	{
		$ZipArchive = [System.IO.Compression.ZipFile]::Open($ZipFile, "Read")
		$entry = $ZipArchive.GetEntry($EntryName)
		if (!$entry) 
		{
			Write-Error "$ZipFile doesn't contain $EntryName"
			return
		}

        $entry
	}
}

Export-ModuleMember -Function Restore-AllFromZip, Get-ZipEntries, Restore-FileFromZip, Get-ZipEntry
