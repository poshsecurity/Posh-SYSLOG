Function Connect-TCPClient
{
    <#
        .SYNOPSIS
        Connects to a TCP server using the specified server (hostname or ip) and specified port and then returns a TCP client object.

        .DESCRIPTION
        Internal function.

        This function will create a connect to a TCP server on the specified port. The function will return a TCPClient object.

        .EXAMPLE
        Connect-TCPClient -Server 'bob' -Port 80
        Connect to the TCP Service on server bob, at port 80

        .OUTPUTS
        Returns a System.Net.Sockets.TCPClient
    #>
    
    [CmdletBinding()]
    [OutputType([System.Net.Sockets.TcpClient])]
    param
    (
        # Hostname or IP address of the server.
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'Hostname or IP address of server')]
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

    # Create a TCP client Object
    Try 
    {
        $TcpClient = New-Object -TypeName System.Net.Sockets.TcpClient
        $TcpClient.Connect($Server, $Port)
    }
    Catch 
    {
        Throw $_
    }

    $TcpClient
}