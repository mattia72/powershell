function Invoke-WindowsApi() {
    param(
        [string] $dllName,
        [Type] $returnType,
        [string] $methodName,
        [Type[]] $parameterTypes,
        [Object[]] $parameters
    )

    ## Begin to build the dynamic assembly
    $domain = [AppDomain]::CurrentDomain
    $name = New-Object Reflection.AssemblyName 'PInvokeAssembly'
    $assembly = $domain.DefineDynamicAssembly($name, 'Run')
    $module = $assembly.DefineDynamicModule('PInvokeModule')
    $type = $module.DefineType('PInvokeType', "Public,BeforeFieldInit")

    ## Go through all of the parameters passed to us.  As we do this,
    ## we clone the user's inputs into another array that we will use for
    ## the P/Invoke call.
    $inputParameters = @()
    $refParameters = @()

    for ($counter = 1; $counter -le $parameterTypes.Length; $counter++) {
        ## If an item is a PSReference, then the user
        ## wants an [out] parameter.
        if ($parameterTypes[$counter - 1] -eq [Ref]) {
            ## Remember which parameters are used for [Out] parameters
            $refParameters += $counter

            ## On the cloned array, we replace the PSReference type with the
            ## .Net reference type that represents the value of the PSReference,
            ## and the value with the value held by the PSReference.
            $parameterTypes[$counter - 1] =
            $parameters[$counter - 1].Value.GetType().MakeByRefType()
            $inputParameters += $parameters[$counter - 1].Value
        }
        else {
            ## Otherwise, just add their actual parameter to the
            ## input array.
            $inputParameters += $parameters[$counter - 1]
        }
    }

    ## Define the actual P/Invoke method, adding the [Out]
    ## attribute for any parameters that were originally [Ref]
    ## parameters.
    $method = $type.DefineMethod($methodName, 'Public,HideBySig,Static,PinvokeImpl',
        $returnType, $parameterTypes)
    foreach ($refParameter in $refParameters) {
        [void] $method.
        DefineParameter($refParameter, "Out", $null)
    }

    ## Apply the P/Invoke constructor
    $ctor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([string])
    $attr = New-Object Reflection.Emit.CustomAttributeBuilder $ctor, $dllName
    $method.SetCustomAttribute($attr)

    ## Create the temporary type, and invoke the method.
    $realType = $type.CreateType()

    $realType.InvokeMember($methodName, 'Public,Static,InvokeMethod', $null, $null,
        $inputParameters)

    ## Finally, go through all of the reference parameters, and update the
    ## values of the PSReference objects that the user passed in.
    foreach ($refParameter in $refParameters) {
        $parameters[$refParameter - 1].Value = $inputParameters[$refParameter - 1]
    }
}

function Read-IniFile() {
    param(
        $file,
        $category,
        $key)

    ## Prepare the parameter types and parameter values for the Invoke-WindowsApi script
    $returnValue = New-Object System.Text.StringBuilder 500
    $parameterTypes = [string], [string], [string], [System.Text.StringBuilder], [int], [string]
    $parameters = [string] $category, [string] $key, [string] "",

    [System.Text.StringBuilder] $returnValue, [int] $returnValue.Capacity, [string] $file
    ## Invoke the API
    [void] (Invoke-WindowsApi "kernel32.dll" ([UInt32]) "GetPrivateProfileString" $parameterTypes $parameters)
    ## And return the results
    $returnValue.ToString()
}

function Write-IniFile() {
    param(
        $file,
        $category,
        $key,
        $value)

    ## Prepare the parameter types and parameter values for the Invoke-WindowsApi script
    $parameterTypes = [string], [string], [string], [string]
    $parameters = [string] $category, [string] $key, [string] $value, [string] $file

    ## Invoke the API
    [void] (Invoke-WindowsApi "kernel32.dll" ([UInt32]) "WritePrivateProfileString" $parameterTypes $parameters)
}

Export-ModuleMember -Function Read-IniFile, Write-IniFile