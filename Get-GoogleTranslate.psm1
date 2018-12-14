<#
.SYNOPSIS
      A simple function to invoke internet explorer and show google translate using powershell
.DESCRIPTION
      A simple function to invoke internet explorer and show google translate using powershell
.EXAMPLE
      PS C:\> Get-GoogleTranslate -From English -To French -Texts "Have a Good day $env:USERNAME" 
      Translate some text from english to french 

      PS C:\> "monday", "tuesday" | Get-GoogleTranslate -From English -To French
      Translate some text from english to french from pipe
.INPUTS
      Texts to translate
.OUTPUTS
      Translated texts 
.NOTES
      Author    : Kiran Reddy, Mattia72
      WebSite   : Kiran-Reddy.in, github/Mattia72
#>

Function Get-SupportedLanguages {
  ('Afrikaans', 'Albanian', 'Arabic', 'Azerbaijani', 'Basque', 'Bengali', 'Belarusian', 'Bulgarian', 'Catalan', 'Chinese Simplified', 'Chinese Traditional', 'Croatian',
    'Czech', 'Danish', 'Dutch', 'English', 'Esperanto', 'Estonian', 'Filipino', 'Finnish', 'French', 'Galician', 'Georgian', 'German', 'Greek', 'Gujarati', 'Haitian Creole',
    'Hebrew', 'Hindi', 'Hungarian', 'Icelandic', 'Indonesian', 'Irish', 'Italian', 'Japanese', 'Kannada', 'Korean', 'Latin', 'Latvian', 'Lithuanian', 'Macedonian', 'Malay',
    'Maltese', 'Norwegian', 'Persian', 'Polish', 'Portuguese', 'Romanian', 'Russian', 'Serbian', 'Slovak', 'Slovenian', 'Spanish', 'Swahili', 'Swedish', 'Tamil', 'Telugu',
    'Thai', 'Turkish', 'Ukrainian', 'Urdu', 'Vietnamese', 'Welsh', 'Yiddish')
}
Function Get-SupportedLangCode ($Language) {
  $LanguageHashTable = @{
    Afrikaans = 'af'; 'Albanian' = 'sq'; Arabic = 'ar'; Azerbaijani = 'az'; Basque = 'eu'; Bengali = 'bn'; Belarusian = 'be'; Bulgarian = 'bg'; Catalan = 'ca'; 'Chinese Simplified' = 'zh-CN'; 'Chinese Traditional' = 'zh-TW'; Croatian = 'hr'; 
    Czech = 'cs'; Danish = 'da'; Dutch = 'nl'; English = 'en'; Esperanto = 'eo'; Estonian = 'et'; Filipino = 'tl'; Finnish = 'fi'; French = 'fr'; Galician = 'gl'; Georgian = 'ka'; German = 'de';
    Greek = 'el'; Gujarati = 'gu'; Haitian = 'ht'; Creole = 'ht'; Hebrew = 'iw'; Hindi = 'hi'; Hungarian = 'hu'; Icelandic = 'is'; Indonesian = 'id'; Irish = 'ga'; Italian = 'it'; Japanese = 'ja'; Kannada = 'kn'; Korean = 'ko'; Latin = 'la'; Latvian = 'lv'; 
    Lithuanian = 'lt'; Macedonian = 'mk'; Malay = 'ms'; Maltese = 'mt'; Norwegian = 'no'; Persian = 'fa'; Polish = 'pl'; Portuguese = 'pt'; Romanian = 'ro'; Russian = 'ru'; Serbian = 'sr'; Slovak = 'sk';
    Slovenian = 'sl'; Spanish = 'es'; Swahili = 'sw'; Swedish = 'sv'; Tamil = 'ta'; Telugu = 'te'; Thai = 'th'; Turkish = 'tr'; Ukrainian = 'uk'; Urdu = 'ur'; Vietnamese = 'vi'; Welsh = 'cy'; Yiddish = 'yi'
  }
  $LanguageHashTable[$Language]
}

Function Get-GoogleTranslate {
  [CmdletBinding()]
  param
  (
    [Parameter(ValueFromPipeline = $False)]
    [ValidateScript( {Get-SupportedLanguages})]
    [String]$From = 'English',

    [Parameter(ValueFromPipeline = $False)]
    [ValidateScript( {Get-SupportedLanguages})]
    [String]$To,

    [Parameter(ValueFromPipeline = $True)]
    [String[]]$Texts,

    [Parameter(ValueFromPipeline = $False)]
    [String]$InputEncoding = 'utf-8',

    [Parameter(ValueFromPipeline = $False)]
    [String]$OutputEncoding = 'utf-8'
  )

  begin {
    try { $IE = New-Object -ComObject Internetexplorer.Application }
    catch { Write-Error $_.Exception.Message }
  }
  process {
    try {
      foreach ($text in $Texts) {

        $EncodedText = [System.Web.HttpUtility]::UrlEncode($text) 
        $URL = 'http://www.google.com/' `
          + 'translate_t?hl=en&ie=' + $InputEncoding `
          + '&oe=' + $OutputEncoding + '&text={0}&langpair={1}|{2}' `
          -f $EncodedText, $(Get-SupportedLangCode $from), $(Get-SupportedLangCode $to)

        $IE.Navigate2(${URL})

        while ($IE.Busy -or ($IE.ReadyState -ne 4)) {
          Start-Sleep -Milliseconds 1
        }

        $innerText = $IE.document.getElementsByClassName('tlid-translation translation')[0].innerText
        $innerText
      }
    }
    catch { Write-Error $_.Exception.Message }
  }
  end {
    if ($null -ne $IE) {
      $IE.Quit()
      [System.Runtime.InteropServices.Marshal]::ReleaseComObject($IE) | Out-Null
      Remove-Variable IE 
    }
  }
}

Export-ModuleMember -Function Get-GoogleTranslate, Get-SupportedLanguages, Get-SupportedLangCode
Add-Type -AssemblyName System.Web
