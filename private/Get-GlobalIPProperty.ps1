Function Get-GlobalIPProperty
{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .EXAMPLE

        .OUTPUTS
    #>

    [CmdletBinding()]
    [OutputType([System.Net.NetworkInformation.IPGlobalProperties])]
    param()

    [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
}