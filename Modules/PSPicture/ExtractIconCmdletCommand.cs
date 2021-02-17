using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Runtime.InteropServices;
using System.Drawing;
using System.IO;


namespace PSPicture
{
  public enum IconSizeType { Large, Small }

  [Cmdlet(VerbsData.Export, "Icon")]
  [OutputType(typeof(Icon))]
  public class ExtractIconCommand : PSCmdlet
  {
    [Parameter(
        Mandatory = true,
        Position = 0,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true)]
    public string Path { get; set; }
    [Parameter(
        Position = 1,
        ValueFromPipelineByPropertyName = true)]
    public int Index { get; set; } = 0;

    [Parameter(
        Position = 2,
        ValueFromPipelineByPropertyName = true)]
    public IconSizeType Size { get; set; } = IconSizeType.Large;

    public static Icon ExtractIconFromFile(string file, int number, IconSizeType ist)
    {
      IntPtr largeIconPtr;
      IntPtr smallIconPtr;
      ExtractIconEx(file, number, out largeIconPtr, out smallIconPtr, 1);
      try
      {
        return Icon.FromHandle(ist == IconSizeType.Large ? largeIconPtr : smallIconPtr);
      }
      catch
      {
        return null;
      }
    }

    [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
    private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
    // This method gets called once for each cmdlet in the pipeline when the pipeline starts executing
    protected override void BeginProcessing()
    {
      if (!File.Exists(Path))
      {
        throw new FileNotFoundException("Path does not exist.", Path);
      }
    }

    // This method will be called for each input received from the pipeline to this cmdlet; if no input is received, this method is not called
    protected override void ProcessRecord()
    {
      WriteObject(
        ExtractIconFromFile(Path, Index, Size)
      );
    }

    // This method will be called once at the end of pipeline execution; 
    // if no input is received, this method is not called
    protected override void EndProcessing()
    {
      WriteVerbose("Icon extracted successfully.");
    }
  }
}
