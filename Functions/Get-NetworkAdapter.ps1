Function Get-NetworkAdapter
{
    <#
        .SYNOPSIS
        
        .DESCRIPTION
        Internal Function.

        

        .EXAMPLE
        

        .OUTPUTS
        
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

        # Get the adapter that the endpoint is assigned to
        #$NetworkAdapter = Get-NetIPAddress -IPAddress $LocalEndPoint
        $NetworkAdapter = $LocalAdapters.ForEach({$_.GetIPProperties().UnicastAddresses}).where({$_.address -eq $IPAddress})

        $NetworkAdapter
}