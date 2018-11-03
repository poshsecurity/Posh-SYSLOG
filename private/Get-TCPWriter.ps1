Function Get-TCPWriter
{
    <#
        .SYNOPSIS
        Returns a TCPWriter object for a given TcpClient.

        .DESCRIPTION
        Creates a TcpWriter, given the TcpClient (and TcpStream), and returns it.

        .EXAMPLE
        Get-TCPWriter -TcpClient $Client
        Returns a TCPWriter connected to the stream associated with the TCPClient.

        .OUTPUTS
        System.IO.StreamWriter
    #>

    [CmdletBinding()]
    [OutputType([System.IO.StreamWriter])]
    param
    (
        # TCP Client that is connected to an endpoint
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'TCP Client that is connected to an endpoint')]
        [ValidateNotNullOrEmpty()]
        [Net.Sockets.TcpClient]
        $TcpClient
    )

    Try 
    {
        $TcpStream = $TcpClient.GetStream()
        $TcpWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $TcpStream

        # We want to set autoflush to true so that we send whatever is in the stream/writer when a newline is entered
        $TcpWriter.AutoFlush = $true
    }
    Catch 
    {
        Throw $_
    }

    $TcpWriter
}
