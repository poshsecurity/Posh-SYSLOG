Function Send-UDPMessage
{
    <#
        .SYNOPSIS
        Sends a datagram using the specified UDP Client

        .DESCRIPTION
        Internal function.

        This function will send a datagram using the specified UDP Client.

        .EXAMPLE
        Send-UdpMessage -UdpWriter $Writer -Datagram $Message
        Sends the datagram, or byte array, $Message using the specified UDP Client $writer.

        .OUTPUTS
        None
    #>

    [CmdletBinding()]
    [OutputType($null)]
    param
    (
        # TCPWriter object, that is already connected to the TCP server.
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'UDPClient object, that is already connected to the TCP server')]
        [ValidateNotNullOrEmpty()]
        [Net.Sockets.UdpClient]
        $UdpClient,

        # Byte array containing the datagram to be sent.
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'Byte array containing the datagram to be sent')]
        [ValidateNotNullOrEmpty()]
        [byte[]]
        $Datagram
    )
    
    Write-Verbose -Message ([Text.Encoding]::ASCII.GetString($Datagram)) -Verbose

    $null = $UdpClient.Send($Datagram, $Datagram.Length)
}