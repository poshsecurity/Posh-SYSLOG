Function Get-NetworkIPAddress
{
    <#
        .SYNOPSIS
        Gets the correstponding network adapter for the specified local IP address.

        .DESCRIPTION
        Internal Function.

        This replaces the Get-NetAdapter call in previous versions, for all intents and purposes this is a decent subsititue.
        The reason why we want to perform this replacement is so that we don't have the dependency on the Get-NetAdapter and NetTCPIP module,
        as they are not available to PowerShell 6 Core.

        .OUTPUTS
        System.Net.NetworkInformation.SystemUnicastIPAddressInformation that has informaiton on the network card (actually the address assignment).
    #>

    [CmdletBinding()]
    [OutputType([System.Net.NetworkInformation.IPAddressInformation])]
    Param
    (
        # Socket of the Client
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'Add help message for user')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$')]
        [String]
        $IPAddress
    )

    # Get a list of network adapters on the system
    $LocalAdapters = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()
    Write-Debug -Message ('Found {0} network interfaces' -f ($LocalAdapters.Count))

    # Find the Address
    $Addresses = $LocalAdapters.ForEach({$_.GetIPProperties().UnicastAddresses}).where({$_.address -eq $IPAddress})

    if ($Addresses.Count -ne 1)
    {
        Throw 'Unable to find correct network adapter'
    }

    $Addresses
}