<#
      .Synopsis
      A simple function to invoke internet explorer and show google translate using powershell
      .DESCRIPTION
      A simple function to invoke internet explorer and show google translate using powershell
      .EXAMPLE
      Show-GoogleTranslate -From English -To 'Chinese Simplified' -Text "Hello good morning $env:USERNAME"

      Description 
      ----------- 
      By Default the cmdlet will use the IE parameterset and display the translation in an IE window
      .EXAMPLE
      Show-GoogleTranslate -From English -To French -Text "Have a Good day $env:USERNAME" 

      Description 
      ----------- 
      Using the 'Console' switch will display the output in the powershell console but be aware the html parsing messes up the output so some characters may show up as weird icons.
      .INPUTS
      String
      .OUTPUTS
      Translated text
      .NOTES
      Author      : Kiran Reddy, Mattia72
      WebSite   : Kiran-Reddy.in, github/Mattia72
#>

Function Show-GoogleTranslate {
  param
  (
    [ValidateSet('Afrikaans', 'Albanian', 'Arabic', 'Azerbaijani', 'Basque', 'Bengali', 'Belarusian', 'Bulgarian', 'Catalan', 'Chinese Simplified', 'Chinese Traditional', 'Croatian',
      'Czech', 'Danish', 'Dutch', 'English', 'Esperanto', 'Estonian', 'Filipino', 'Finnish', 'French', 'Galician', 'Georgian', 'German', 'Greek', 'Gujarati', 'Haitian Creole',
      'Hebrew', 'Hindi', 'Hungarian', 'Icelandic', 'Indonesian', 'Irish', 'Italian', 'Japanese', 'Kannada', 'Korean', 'Latin', 'Latvian', 'Lithuanian', 'Macedonian', 'Malay',
      'Maltese', 'Norwegian', 'Persian', 'Polish', 'Portuguese', 'Romanian', 'Russian', 'Serbian', 'Slovak', 'Slovenian', 'Spanish', 'Swahili', 'Swedish', 'Tamil', 'Telugu',
      'Thai', 'Turkish', 'Ukrainian', 'Urdu', 'Vietnamese', 'Welsh', 'Yiddish')
    ]
    [String]$From = 'English',

    [ValidateSet('Afrikaans', 'Albanian', 'Arabic', 'Azerbaijani', 'Basque', 'Bengali', 'Belarusian', 'Bulgarian', 'Catalan', 'Chinese Simplified', 'Chinese Traditional', 'Croatian',
      'Czech', 'Danish', 'Dutch', 'English', 'Esperanto', 'Estonian', 'Filipino', 'Finnish', 'French', 'Galician', 'Georgian', 'German', 'Greek', 'Gujarati', 'Haitian Creole',
      'Hebrew', 'Hindi', 'Hungarian', 'Icelandic', 'Indonesian', 'Irish', 'Italian', 'Japanese', 'Kannada', 'Korean', 'Latin', 'Latvian', 'Lithuanian', 'Macedonian', 'Malay',
      'Maltese', 'Norwegian', 'Persian', 'Polish', 'Portuguese', 'Romanian', 'Russian', 'Serbian', 'Slovak', 'Slovenian', 'Spanish', 'Swahili', 'Swedish', 'Tamil', 'Telugu',
      'Thai', 'Turkish', 'Ukrainian', 'Urdu', 'Vietnamese', 'Welsh', 'Yiddish')
    ]
    [String]$To,

    [String]$Text,

    [String]$InputEncoding = 'utf-8',

    [String]$OutputEncoding = 'utf-8'
  )


  $LanguageHashTable = 
  @{
    Afrikaans             = 'af'
    Albanian              = 'sq'
    Arabic                = 'ar'
    Azerbaijani           = 'az'
    Basque                = 'eu'
    Bengali               = 'bn'
    Belarusian            = 'be'
    Bulgarian             = 'bg'
    Catalan               = 'ca'
    'Chinese Simplified'  = 'zh-CN'
    'Chinese Traditional' = 'zh-TW'
    Croatian              = 'hr'
    Czech                 = 'cs'
    Danish                = 'da'
    Dutch                 = 'nl'
    English               = 'en'
    Esperanto             = 'eo'
    Estonian              = 'et'
    Filipino              = 'tl'
    Finnish               = 'fi'
    French                = 'fr'
    Galician              = 'gl'
    Georgian              = 'ka'
    German                = 'de'
    Greek                 = 'el'
    Gujarati              = 'gu'
    Haitian               = 'ht'
    Creole                = 'ht'
    Hebrew                = 'iw'
    Hindi                 = 'hi'
    Hungarian             = 'hu'
    Icelandic             = 'is'
    Indonesian            = 'id'
    Irish                 = 'ga'
    Italian               = 'it'
    Japanese              = 'ja'
    Kannada               = 'kn'
    Korean                = 'ko'
    Latin                 = 'la'
    Latvian               = 'lv'
    Lithuanian            = 'lt'
    Macedonian            = 'mk'
    Malay                 = 'ms'
    Maltese               = 'mt'
    Norwegian             = 'no'
    Persian               = 'fa'
    Polish                = 'pl'
    Portuguese            = 'pt'
    Romanian              = 'ro'
    Russian               = 'ru'
    Serbian               = 'sr'
    Slovak                = 'sk'
    Slovenian             = 'sl'
    Spanish               = 'es'
    Swahili               = 'sw'
    Swedish               = 'sv'
    Tamil                 = 'ta'
    Telugu                = 'te'
    Thai                  = 'th'
    Turkish               = 'tr'
    Ukrainian             = 'uk'
    Urdu                  = 'ur'
    Vietnamese            = 'vi'
    Welsh                 = 'cy'
    Yiddish               = 'yi'
  }

  $URL = 'http://www.google.com/translate_t?hl=en&ie=' + $InputEncoding + '&oe=' + $OutputEncoding + '&text={0}&langpair={1}|{2}' -f $Text, $LanguageHashTable[$from], $LanguageHashTable[$to]
  $IE = New-Object -ComObject Internetexplorer.Application
  $IE.Navigate2($url)
  while ($IE.Busy -or ($IE.ReadyState -ne 4)) {
    Start-Sleep -Milliseconds 200
  }
  $IE.document.getElementsByClassName('tlid-translation translation')[0].innerText
}



#Example
#Show-GoogleTranslate -From Slovak -To Hungarian -Text "čierny, A" -Console

#Export-ModuleMember -Function Show-GoogleTranslate