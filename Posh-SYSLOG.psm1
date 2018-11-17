# Taken from http://overpoweredshell.com/Working-with-Plaster/

$functionFolders = @('public', 'private', 'classes')
ForEach ($folder in $functionFolders)
{
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    If (Test-Path -Path $folderPath)
    {
        Write-Verbose -Message "Importing from $folder at $folderPath"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1'
        ForEach ($function in $functions)
        {
            Write-Verbose -Message "  Importing $($function.BaseName)"
            . $function.fullname
        }
    }
}

$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\public" -Filter '*.ps1').BaseName
Export-ModuleMember -Function $publicFunctions
