Function Connect-UDPClient
{
    <#
        .SYNOPSIS
        Connects to a UDP server using the specified server (hostname or ip) and specified port and then returns a UDP client object.

        .DESCRIPTION
        Internal function.

        This function will create a connect to a UDP server on the specified port. The function will return a UDPClient object.

        .EXAMPLE
        Connect-UDPClient -Server 'bob' -Port 80
        Connect to the UDP Service on server bob, at port 80

        .OUTPUTS
        Returns a System.Net.Sockets.UdpClient
    #>

    [CmdletBinding()]
    [OutputType([System.Net.Sockets.UdpClient])]
    param
    (
        # Hostname or IP address of the server.
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'Hostname or IP address of the server')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server,

        # Port of the server (1-65535)
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'Port of the server (1-65535)')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [UInt16]
        $Port
    )

    # Create a UDP client Object
    Try 
    {
        $UDPCLient = New-Object -TypeName System.Net.Sockets.UdpClient
        $UDPCLient.Connect($Server, $Port)
    }
    Catch 
    {
        Throw $_
    }

    $UDPCLient
}