Function Disconnect-UDPClient
{
    <#
        .SYNOPSIS
        Disconnects/Closes a UdpClient Object

        .DESCRIPTION
        Internal function.
        
        Disconnects/closes an open UdpClient.

        .EXAMPLE
        Disconnect-UdpClient -UdpClient $Client
        Closes the client $client.

        .OUTPUTS
        None
    #>

    [CmdletBinding()]
    param
    (
        # UdpClient that is connected to an endpoint
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'UdpClient that is connected to an endpoint')]
        [ValidateNotNullOrEmpty()]
        [Net.Sockets.UdpClient]
        $UdpClient
    )

    Try 
    {
        $UdpClient.Close()
    }
    Catch 
    {
        Throw $_
    }

}