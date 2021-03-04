using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace PSTrayMenu
{
  [Cmdlet(VerbsCommon.New, "TrayMenu")]
  [OutputType(typeof(TrayMenu))]
  public class NewTrayMenuCmdletCommand : PSCmdlet
  {
    [Parameter(
        Mandatory = true,
        Position = 0,
        ValueFromPipeline = true,
        ValueFromPipelineByPropertyName = true)]
    public int FavoriteNumber { get; set; }

    [Parameter(
        Position = 1,
        ValueFromPipelineByPropertyName = true)]
    [ValidateSet("Cat", "Dog", "Horse")]
    public string FavoritePet { get; set; } = "Dog";

    // This method gets called once for each cmdlet in the pipeline when the pipeline starts executing
    protected override void BeginProcessing()
    {
      WriteVerbose("Begin!");
    }

    // This method will be called for each input received from the pipeline to this cmdlet; if no input is received, this method is not called
    protected override void ProcessRecord()
    {
      WriteObject(new FavoriteStuff
      {
        FavoriteNumber = FavoriteNumber,
        FavoritePet = FavoritePet
      });
    }

    // This method will be called once at the end of pipeline execution; if no input is received, this method is not called
    protected override void EndProcessing()
    {
      WriteVerbose("End!");
    }
  }

  public class MenuItem
  {
    public string ItemIndex { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public string Options { get; set; }
    public string Style { get; set; }
    public string IconPath { get; set; }
    public bool RefreshEnvVars { get; set; }
    public Hotkey HotKey { get; set; }
  }
  public class HotKey
  {
    private bool InStr(string text, string contain)
    {
      return text.Contains(contain);
    }
    public string HotKeyCode { get; set; }
    public string ToString()
    {
      string hkText = "";
      if (HotKeyCode != "")
      {
        if (InStr(HotKeyCode, "@") || InStr(HotKeyCode, "#"))
          hkText += "Win+";
        if (InStr(HotKeyCode, "!"))
          hkText += "Alt+";
        if (InStr(HotKeyCode, "^"))
          hkText += "Ctrl+";
        if (InStr(HotKeyCode, "+"))
          hkText += "Shift+";
Regex rx = new Regex(@".*([\w]+)$", "$1");
        key = Regex.Replace(HotKeyCode, 
        hkText = hkText.StrUpper(key);
      }
      return hkText;
    }
    public class Command
    {
      public CommanType Type { get; set; }
      public string CommandPath { get; set; }

    }
    public enum CommandType
    {
      EXE,
      BAT,
      PowerShell,
      GlobalFunction
    }
  }
}